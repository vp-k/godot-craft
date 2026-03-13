#!/usr/bin/env python3
"""
plan_parser.py — PLAN.md 파서 → JSON
PLAN.md의 태스크를 구조화된 JSON으로 변환합니다.
"""

import argparse
import json
import re
import sys


def parse_plan(plan_path: str) -> list:
    """PLAN.md를 파싱하여 태스크 리스트 반환"""
    with open(plan_path, "r", encoding="utf-8") as f:
        content = f.read()

    tasks = []

    # ### T1: 제목 또는 ### Task 1: 제목 패턴 매칭
    task_pattern = re.compile(
        r'###\s+(?:T|Task\s*)(\d+)\s*[:\-]\s*(.+?)(?:\n|$)',
        re.IGNORECASE
    )

    matches = list(task_pattern.finditer(content))

    for i, match in enumerate(matches):
        task_id = f"T{match.group(1)}"
        title = match.group(2).strip()

        # 다음 태스크까지의 텍스트 추출
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        body = content[start:end]

        # 설명 추출
        desc_match = re.search(r'\*\*설명\*\*\s*[:\-]\s*(.+?)(?:\n|$)', body)
        description = desc_match.group(1).strip() if desc_match else ""

        # 의존성 추출
        deps_match = re.search(r'\*\*의존\*\*\s*[:\-]\s*(.+?)(?:\n|$)', body)
        deps = []
        if deps_match:
            deps_text = deps_match.group(1).strip()
            if deps_text.lower() not in ("없음", "none", "-", ""):
                deps = re.findall(r'T\d+', deps_text)

        # 산출물 추출
        outputs_match = re.search(r'\*\*산출물\*\*\s*[:\-]\s*(.+?)(?:\n\s*\-|\n\s*\*\*|\n\n|$)',
                                  body, re.DOTALL)
        outputs = []
        if outputs_match:
            out_text = outputs_match.group(1).strip()
            # 파일 경로 패턴 추출
            outputs = re.findall(r'[\w/]+\.\w+', out_text)

        # 완료 기준 추출
        criteria_match = re.search(r'\*\*완료\s*기준\*\*\s*[:\-]\s*(.+?)(?:\n\s*###|\n\n\n|$)',
                                   body, re.DOTALL)
        criteria = criteria_match.group(1).strip() if criteria_match else ""

        tasks.append({
            "id": task_id,
            "title": title,
            "description": description,
            "deps": deps,
            "status": "ready" if not deps else "pending",
            "outputs": outputs,
            "completionCriteria": criteria,
        })

    return tasks


def main():
    parser = argparse.ArgumentParser(description="Parse PLAN.md to JSON")
    parser.add_argument("--input", required=True, help="PLAN.md path")
    parser.add_argument("--output", default=None,
                        help="Output JSON path (default: stdout)")

    args = parser.parse_args()
    tasks = parse_plan(args.input)

    result = json.dumps(tasks, indent=2, ensure_ascii=False)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(result)
        print(f"OK: Parsed {len(tasks)} tasks → {args.output}")
    else:
        print(result)


if __name__ == "__main__":
    main()
