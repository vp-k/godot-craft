# godot-craft

A Claude Code plugin that autonomously generates playable Godot 4 games from a single text prompt.

> "우주 슈팅 게임 만들어줘" → Playable Godot 4 project with assets, scenes, scripts, and visual QA.

## How It Works

godot-craft runs a fully automated **6-Phase pipeline** — you describe a game in natural language, approve the concept, and the plugin handles the rest:

```
Phase 0: Concept & Planning ─── Expand idea → PLAN.md → User approval (only interaction)
    ↓
Phase 1: Scaffold & Assets ─── Project structure + asset generation (images, sounds, music)
    ↓
Phase 2: Implementation ─── Task-by-task coding with compile checks
    ↓
Phase 3: Visual QA & Fix ─── Screenshot-based inspection + SSIM comparison (up to 3 rounds)
    ↓
Phase 4: Polish & Present ─── Debug cleanup + gameplay video capture
    ↓
Phase 5: Verification ─── Final integrity checks + DoD completion
```

## Commands

| Command | Description |
|---------|-------------|
| `/make-game <description>` | Generate a game from a natural language prompt |
| `/godot-resume` | Resume an interrupted game project from where it left off |

## Skills

| Skill | Phase | Role |
|-------|-------|------|
| concept-planning | 0 | Game concept expansion, visual target, planning docs |
| scaffold-assets | 1 | Project scaffolding, script stubs, scene/asset generation |
| implementation | 2 | DAG-ordered task execution with godot-task sub-skill |
| visual-qa-fix | 3 | Screenshot capture, VQA inspection, SSIM diff, fix loop |
| polish-present | 4 | Debug code removal, code cleanup, video capture |
| verification | 5 | Compile check, asset/scene integrity, DoD checklist |
| godot-task | — | Per-task execution: GDScript writing, scene generation, coordination |

## Asset Generation

Built-in providers for AI-generated game assets:

- **Images** — Flux, Gemini, Worker (sprites, backgrounds, UI)
- **3D Models** — Meshy, Tripo
- **Music** — Suno
- **Sound Effects** — SFX Engine
- **Sprite Processing** — Background removal (rembg), spritesheet packing

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- [Godot 4](https://godotengine.org/) installed and available in PATH
- Python 3.10+ with dependencies:
- `jq` for JSON processing in shell scripts

```bash
pip install -r tools/requirements.txt
```

### Platform Support

| Feature | Linux | macOS | Windows (WSL) |
|---------|-------|-------|---------------|
| Game generation (Phase 0-2, 5) | Full | Full | Full |
| Screenshot capture (Phase 3) | Full | Not yet | Via WSL |
| Video recording (Phase 4) | Full | Not yet | Via WSL |

Phase 3 (Visual QA) and Phase 4 (video capture) use `Xvfb` + `ImageMagick`/`scrot` which are Linux-specific. On macOS and Windows, the game is still fully generated and verified — only automated screenshot/video capture is unavailable.

For full Phase 3/4 support on Linux:
```bash
sudo apt-get install xvfb imagemagick ffmpeg
```

### Optional: API Keys for Asset Generation

Set as environment variables:
- `GEMINI_API_KEY` — Google Gemini for image generation
- `FAL_KEY` — Flux image generation
- `WORKER_IMAGE_URL` — Worker image proxy endpoint URL
- `WORKER_IMAGE_API_KEY` — Worker image proxy API key
- `MESHY_API_KEY` — 3D model generation
- `TRIPO_API_KEY` — 3D model generation
- `SUNO_API_KEY` — Music generation

## Installation

Add godot-craft as a Claude Code plugin:

```bash
claude plugin add vp-k/godot-craft
```

Or clone and link locally:

```bash
git clone https://github.com/vp-k/godot-craft.git
claude plugin add ./godot-craft
```

## Quick Start

```
> /make-game 탑뷰 던전 크롤러 — 검사 캐릭터가 3층 던전을 탐험하며 몬스터와 싸우는 게임
```

The plugin will:
1. Generate a detailed game concept and plan
2. Ask for your approval (the only manual step)
3. Scaffold the Godot project with all assets
4. Implement every feature task-by-task
5. Run visual QA with screenshot inspection
6. Polish and verify the final build

## Project Structure

```
.claude-plugin/     Plugin metadata
commands/           Slash commands (/make-game, /godot-resume)
skills/             Phase-specific skill definitions
tools/              Python utilities (asset gen, visual QA, screenshot diff)
  └── providers/    AI provider integrations
scripts/            Shell scripts (quality gates, scaffolding)
templates/          Godot project templates (2D/3D)
hooks/              Lifecycle hooks
rules/              Shared rules
doc_api/            Godot API reference data
```

## License

MIT
