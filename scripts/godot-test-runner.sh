#!/usr/bin/env bash
# godot-test-runner.sh — Godot 게임 인터랙티브 테스트 실행기
# game-develop의 playwright-test.js에 대응하는 Godot 구현.
#
# 사용법:
#   godot-test-runner.sh --scenario idle [OPTIONS]
#   godot-test-runner.sh --scenarios idle,start-game,basic-movement [OPTIONS]
#   godot-test-runner.sh --check-api [OPTIONS]
#
# 옵션:
#   --project <path>        Godot 프로젝트 경로 (기본: 자동 탐지)
#   --scenario <name>       단일 시나리오 실행
#   --scenarios <a,b,c>     여러 시나리오 배치 실행
#   --scenarios-file <path> 시나리오 정의 JSON 파일 (기본: templates/test-scenarios.json)
#   --output-dir <dir>      결과 출력 디렉토리 (기본: test_output/)
#   --timeout <sec>         시나리오당 타임아웃 (기본: 30)
#   --check-api             StateReporter/TestChoreography Autoload 존재 확인
#   --inject-autoloads      Autoload 스크립트를 프로젝트에 자동 주입
#   --display <:N>          Xvfb 디스플레이 번호 (기본: :99)
#   --no-xvfb               Xvfb 사용 안 함 (직접 디스플레이 사용)
#   --verbose               상세 로그 출력

set -euo pipefail

# ─── 기본값 ───

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_FILE=".claude-godot-progress.json"

PROJECT_DIR=""
SCENARIO=""
SCENARIOS=""
SCENARIOS_FILE=""
OUTPUT_DIR="test_output"
TIMEOUT=30
CHECK_API=false
INJECT_AUTOLOADS=false
DISPLAY_NUM=":99"
USE_XVFB=true
VERBOSE=false

# ─── 인수 파싱 ───

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)       PROJECT_DIR="$2"; shift 2 ;;
    --scenario)      SCENARIO="$2"; shift 2 ;;
    --scenarios)     SCENARIOS="$2"; shift 2 ;;
    --scenarios-file) SCENARIOS_FILE="$2"; shift 2 ;;
    --output-dir)    OUTPUT_DIR="$2"; shift 2 ;;
    --timeout)       TIMEOUT="$2"; shift 2 ;;
    --check-api)     CHECK_API=true; shift ;;
    --inject-autoloads) INJECT_AUTOLOADS=true; shift ;;
    --display)       DISPLAY_NUM="$2"; shift 2 ;;
    --no-xvfb)       USE_XVFB=false; shift ;;
    --verbose)       VERBOSE=true; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *) echo "ERROR: Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ─── 유틸리티 ───

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "[godot-test] $*"; }
vlog() { [[ "$VERBOSE" == true ]] && echo "[godot-test][debug] $*" || true; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed"
}

# ─── 프로젝트 탐지 ───

detect_project_dir() {
  if [[ -n "$PROJECT_DIR" ]]; then
    [[ -f "$PROJECT_DIR/project.godot" ]] || die "No project.godot in $PROJECT_DIR"
    echo "$PROJECT_DIR"
    return
  fi
  if [[ -f "project.godot" ]]; then
    echo "."
    return
  fi
  if [[ -f "$PROGRESS_FILE" ]]; then
    local game_name
    game_name=$(jq -r '.gameName // empty' "$PROGRESS_FILE" 2>/dev/null)
    if [[ -n "$game_name" ]] && [[ -f "$game_name/project.godot" ]]; then
      echo "$game_name"
      return
    fi
  fi
  die "Cannot detect project directory. Use --project <path>"
}

# ─── Xvfb 관리 ───

start_xvfb() {
  if [[ "$USE_XVFB" != true ]]; then
    return
  fi
  if ! command -v Xvfb >/dev/null 2>&1; then
    log "WARNING: Xvfb not found. Running without virtual display."
    USE_XVFB=false
    return
  fi
  local existing_pid
  existing_pid=$(pgrep -f "Xvfb $DISPLAY_NUM" 2>/dev/null | head -1 || true)
  if [[ -n "$existing_pid" ]]; then
    vlog "Xvfb already running on $DISPLAY_NUM (pid: $existing_pid), reusing"
    XVFB_PID=""  # don't kill someone else's Xvfb
  else
    log "Starting Xvfb on $DISPLAY_NUM..."
    Xvfb "$DISPLAY_NUM" -screen 0 1280x720x24 +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 1
  fi
  export DISPLAY="$DISPLAY_NUM"
}

cleanup_xvfb() {
  if [[ -n "${XVFB_PID:-}" ]]; then
    kill "$XVFB_PID" 2>/dev/null || true
  fi
}

trap cleanup_xvfb EXIT

# ─── 크로스 플랫폼 sed -i (macOS 호환) ───

portable_sed_i() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ─── Autoload 주입 ───

inject_autoloads() {
  local proj_dir="$1"
  local project_file="$proj_dir/project.godot"

  # autoloads 디렉토리 생성
  mkdir -p "$proj_dir/autoloads"

  # StateReporter 복사
  if [[ ! -f "$proj_dir/autoloads/game_state_reporter.gd" ]]; then
    cp "$PLUGIN_ROOT/templates/game_state_reporter.gd" "$proj_dir/autoloads/game_state_reporter.gd"
    log "Injected game_state_reporter.gd"
  fi

  # TestChoreography 복사
  if [[ ! -f "$proj_dir/autoloads/test_choreography.gd" ]]; then
    cp "$PLUGIN_ROOT/templates/test_choreography.gd" "$proj_dir/autoloads/test_choreography.gd"
    log "Injected test_choreography.gd"
  fi

  # project.godot에 Autoload 등록 (없으면 추가)
  if ! grep -q "StateReporter" "$project_file" 2>/dev/null; then
    if grep -q '^\[autoload\]' "$project_file"; then
      portable_sed_i '/^\[autoload\]/a StateReporter="*res://autoloads/game_state_reporter.gd"' "$project_file"
      log "Registered StateReporter autoload"
    else
      echo "" >> "$project_file"
      echo "[autoload]" >> "$project_file"
      echo 'StateReporter="*res://autoloads/game_state_reporter.gd"' >> "$project_file"
      log "Created [autoload] section + registered StateReporter"
    fi
  fi

  if ! grep -q "TestChoreography" "$project_file" 2>/dev/null; then
    if grep -q '^\[autoload\]' "$project_file"; then
      portable_sed_i '/^\[autoload\]/a TestChoreography="*res://autoloads/test_choreography.gd"' "$project_file"
      log "Registered TestChoreography autoload"
    else
      echo "" >> "$project_file"
      echo "[autoload]" >> "$project_file"
      echo 'TestChoreography="*res://autoloads/test_choreography.gd"' >> "$project_file"
      log "Created [autoload] section + registered TestChoreography"
    fi
  fi
}

remove_autoloads() {
  local proj_dir="$1"
  local project_file="$proj_dir/project.godot"

  # project.godot에서 테스트 autoload 제거
  if [[ -f "$project_file" ]]; then
    portable_sed_i '/StateReporter.*game_state_reporter/d' "$project_file"
    portable_sed_i '/TestChoreography.*test_choreography/d' "$project_file"
    vlog "Removed test autoloads from project.godot"
  fi

  # 파일 제거
  rm -f "$proj_dir/autoloads/game_state_reporter.gd"
  rm -f "$proj_dir/autoloads/test_choreography.gd"
}

# ─── API 확인 ───

check_api() {
  local proj_dir="$1"
  log "Checking test API availability..."

  local has_reporter=false
  local has_choreography=false

  if grep -q "StateReporter" "$proj_dir/project.godot" 2>/dev/null; then
    has_reporter=true
  fi
  if grep -q "TestChoreography" "$proj_dir/project.godot" 2>/dev/null; then
    has_choreography=true
  fi

  echo "{"
  echo "  \"state_reporter\": $has_reporter,"
  echo "  \"test_choreography\": $has_choreography,"
  echo "  \"ready\": $([ "$has_reporter" = true ] && [ "$has_choreography" = true ] && echo true || echo false)"
  echo "}"

  if [[ "$has_reporter" != true ]] || [[ "$has_choreography" != true ]]; then
    log "WARNING: Test autoloads not found. Use --inject-autoloads to add them."
    return 1
  fi
  return 0
}

# ─── 시나리오 추출 ───

extract_scenario() {
  local scenarios_file="$1"
  local scenario_name="$2"
  local output_file="$3"

  # jq로 시나리오 추출
  jq --arg name "$scenario_name" '.scenarios[$name]' "$scenarios_file" > "$output_file"

  if [[ "$(cat "$output_file")" == "null" ]]; then
    die "Scenario '$scenario_name' not found in $scenarios_file"
  fi
}

# ─── 단일 시나리오 실행 ───

run_scenario() {
  local proj_dir="$1"
  local scenario_name="$2"
  local scenarios_file="$3"

  log "Running scenario: $scenario_name"

  # 시나리오 JSON 추출
  local scenario_file="$OUTPUT_DIR/scenario-${scenario_name}.json"
  extract_scenario "$scenarios_file" "$scenario_name" "$scenario_file"

  # Godot user:// 경로에 해당하는 실제 경로
  # SEC-MEDIUM-003: project.godot에서 실제 프로젝트명을 파싱 (basename 대신)
  local project_name
  project_name=$(grep 'config/name=' "$proj_dir/project.godot" 2>/dev/null \
    | head -1 | sed 's/config\/name="//' | sed 's/"$//' || true)
  # SEC-MEDIUM-001: 경로 안전 문자만 허용 (/, .., \, 따옴표 제거)
  project_name=$(echo "$project_name" | tr -d '/\\\"'\''' | sed 's/\.\.\.*//g')
  if [[ -z "$project_name" ]]; then
    project_name="$(basename "$proj_dir")"
    vlog "Could not parse project name from project.godot, using directory name: $project_name"
  fi

  local godot_user_dir
  if [[ "$(uname)" == "Linux" ]]; then
    godot_user_dir="$HOME/.local/share/godot/app_userdata/$project_name"
  elif [[ "$(uname)" == "Darwin" ]]; then
    godot_user_dir="$HOME/Library/Application Support/Godot/app_userdata/$project_name"
  else
    # Windows (Git Bash / MSYS2)
    godot_user_dir="$APPDATA/Godot/app_userdata/$project_name"
  fi

  # 테스트 출력 디렉토리 생성
  mkdir -p "$godot_user_dir/test_output" 2>/dev/null || true

  # Godot 실행
  local godot_args=(
    "--path" "$proj_dir"
    "--" "--test-scenario" "$scenario_file"
    "--test-name" "$scenario_name"
  )

  local exit_code=0
  if [[ "$USE_XVFB" == true ]]; then
    DISPLAY="$DISPLAY_NUM" timeout "$TIMEOUT" godot "${godot_args[@]}" 2>"$OUTPUT_DIR/stderr-${scenario_name}.log" || exit_code=$?
  else
    timeout "$TIMEOUT" godot "${godot_args[@]}" 2>"$OUTPUT_DIR/stderr-${scenario_name}.log" || exit_code=$?
  fi

  # 타임아웃 체크
  if [[ $exit_code -eq 124 ]]; then
    log "WARNING: Scenario '$scenario_name' timed out after ${TIMEOUT}s"
  fi

  # 결과 수집 (user:// → output_dir)
  local test_output="$godot_user_dir/test_output"
  if [[ -d "$test_output" ]]; then
    # 스크린샷
    [[ -f "$test_output/shot-${scenario_name}.png" ]] && \
      cp "$test_output/shot-${scenario_name}.png" "$OUTPUT_DIR/" 2>/dev/null || true
    # 상태 JSON
    [[ -f "$test_output/state.json" ]] && \
      cp "$test_output/state.json" "$OUTPUT_DIR/state-${scenario_name}.json" 2>/dev/null || true
    # 시나리오별 상태
    for f in "$test_output"/state-${scenario_name}-*.json; do
      [[ -f "$f" ]] && cp "$f" "$OUTPUT_DIR/" 2>/dev/null || true
    done
    # 결과 JSON
    [[ -f "$test_output/result-${scenario_name}.json" ]] && \
      cp "$test_output/result-${scenario_name}.json" "$OUTPUT_DIR/" 2>/dev/null || true
  fi

  # stderr에서 에러 추출 (SEC-HIGH-001: Godot 에러 접두사만 매칭)
  if [[ -f "$OUTPUT_DIR/stderr-${scenario_name}.log" ]]; then
    local error_count
    error_count=$(grep -c "ERROR:\|SCRIPT ERROR:\|USER ERROR:\|FATAL:" "$OUTPUT_DIR/stderr-${scenario_name}.log" 2>/dev/null || echo 0)
    if [[ "$error_count" -gt 0 ]]; then
      log "WARNING: $error_count error(s) in $scenario_name"
      # 에러를 JSON으로 저장
      grep "ERROR:\|SCRIPT ERROR:\|USER ERROR:\|FATAL:" "$OUTPUT_DIR/stderr-${scenario_name}.log" | \
        jq -R -s 'split("\n") | map(select(length > 0)) | map({"message": .})' \
        > "$OUTPUT_DIR/errors-${scenario_name}.json" 2>/dev/null || true
    fi
  fi

  # 결과 판정
  local result="UNKNOWN"
  if [[ -f "$OUTPUT_DIR/result-${scenario_name}.json" ]]; then
    local passed
    passed=$(jq -r '.passed' "$OUTPUT_DIR/result-${scenario_name}.json" 2>/dev/null || echo "false")
    if [[ "$passed" == "true" ]]; then
      result="PASS"
    else
      result="FAIL"
    fi
  elif [[ $exit_code -eq 0 ]]; then
    result="PASS"
  elif [[ $exit_code -eq 124 ]]; then
    result="TIMEOUT"
  else
    result="FAIL"
  fi

  log "  → $scenario_name: $result"
  echo "$result"
}

# ─── 배치 실행 ───

run_batch() {
  local proj_dir="$1"
  local scenario_list="$2"
  local scenarios_file="$3"

  IFS=',' read -ra scenario_array <<< "$scenario_list"
  local total=${#scenario_array[@]}
  local passed=0
  local failed=0
  local results=()

  log "Batch test: ${total} scenarios"

  for scenario_name in "${scenario_array[@]}"; do
    scenario_name=$(echo "$scenario_name" | xargs)  # trim
    local result
    result=$(run_scenario "$proj_dir" "$scenario_name" "$scenarios_file")
    # SEC-HIGH-002: jq로 안전한 JSON 생성 (인젝션 방지)
    results+=("$(jq -n --arg s "$scenario_name" --arg r "$result" '{"scenario":$s,"result":$r}')")

    if [[ "$result" == "PASS" ]]; then
      ((passed++)) || true
    else
      ((failed++)) || true
    fi
  done

  # 배치 요약 저장
  local summary_json="["
  local first=true
  for r in "${results[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      summary_json+=","
    fi
    summary_json+="$r"
  done
  summary_json+="]"

  echo "{
  \"total\": $total,
  \"passed\": $passed,
  \"failed\": $failed,
  \"results\": $summary_json
}" > "$OUTPUT_DIR/batch-summary.json"

  log "Batch complete: $passed/$total passed"

  if [[ $failed -gt 0 ]]; then
    return 1
  fi
  return 0
}

# ─── 메인 ───

main() {
  require_cmd godot
  require_cmd jq

  local proj_dir
  proj_dir=$(detect_project_dir)
  log "Project: $proj_dir"

  # 시나리오 파일 결정
  if [[ -z "$SCENARIOS_FILE" ]]; then
    SCENARIOS_FILE="$PLUGIN_ROOT/templates/test-scenarios.json"
  fi
  [[ -f "$SCENARIOS_FILE" ]] || die "Scenarios file not found: $SCENARIOS_FILE"

  # 출력 디렉토리 생성
  mkdir -p "$OUTPUT_DIR"

  # API 확인 모드
  if [[ "$CHECK_API" == true ]]; then
    check_api "$proj_dir"
    exit $?
  fi

  # Autoload 주입
  if [[ "$INJECT_AUTOLOADS" == true ]]; then
    inject_autoloads "$proj_dir"
  fi

  # Xvfb 시작
  start_xvfb

  local exit_code=0

  # 단일 시나리오
  if [[ -n "$SCENARIO" ]]; then
    local result
    result=$(run_scenario "$proj_dir" "$SCENARIO" "$SCENARIOS_FILE")
    [[ "$result" == "PASS" ]] || exit_code=1

  # 배치 시나리오
  elif [[ -n "$SCENARIOS" ]]; then
    run_batch "$proj_dir" "$SCENARIOS" "$SCENARIOS_FILE" || exit_code=1

  # 기본: 전체 시나리오 실행
  else
    local all_scenarios
    all_scenarios=$(jq -r '.scenarios | keys | join(",")' "$SCENARIOS_FILE")
    if [[ -n "$all_scenarios" ]]; then
      run_batch "$proj_dir" "$all_scenarios" "$SCENARIOS_FILE" || exit_code=1
    else
      die "No scenarios found in $SCENARIOS_FILE"
    fi
  fi

  # 테스트 autoload 제거 (주입했던 경우)
  if [[ "$INJECT_AUTOLOADS" == true ]]; then
    remove_autoloads "$proj_dir"
  fi

  exit $exit_code
}

main "$@"
