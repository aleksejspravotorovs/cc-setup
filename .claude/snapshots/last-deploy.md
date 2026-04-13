# Last Deploy Snapshot
Generated: 2026-04-13T17:08:00Z
Branch: main
Commit: 3a09e6b feat(setup): add pp-update command for syncing from git

## Changes deployed (this session)
- 3a09e6b feat(setup): add pp-update command for syncing from git
- e57a7f8 feat: add frontend design set (skills + research + libraries)

## Build status
Pass (no build step — setup/scaffolding repo)

## Context for next /prime

### What shipped
- **Frontend design set committed**: `.claude/skills/` (4 skills), `.claude/research/` (6 docs), `libraries/scroll-animations/` (5 files: animations.ts, easings.ts, scroll-animations.ts, tailwind-theme-reference.js, README.md). Previously untracked locally.
- **`pp-update` command**: new `scripts/update.sh` + `scripts/update.ps1`. Auto-detects mode:
  - cc-setup clone → `git pull` + re-runs `install-plugins.sh` (refreshes `~/.claude` hooks/settings/plugins).
  - bootstrapped project → re-downloads `.claude/agents/`, `.claude/commands/`, `scripts/` from GitHub (and frontend set if dir exists).
- **install.sh / install.ps1**: add opt-in prompt "Install frontend design set? (y/n)" — downloads skills + research + libraries when y. Also downloads `update.sh` so bootstrapped projects ship with `pp-update` available.
- **setup.sh / setup.ps1**: registers `pp-update` alias alongside `pp` and `pp-setup`. Skills check is now soft (info, not warn) when `.claude/skills` dir absent — frontend set is opt-in.

### Key files changed
- `install.sh`, `install.ps1` — frontend prompt + downloads `update.sh`
- `scripts/setup.sh`, `scripts/setup.ps1` — `pp-update` alias registration; conditional skills check
- `scripts/update.sh`, `scripts/update.ps1` — new
- `.claude/skills/*.md`, `.claude/research/*.md`, `libraries/scroll-animations/**` — new (committed)

### New routes / components
- None (setup repo)

### Breaking changes
- Existing users must re-run `pp-setup` (or `bash scripts/setup.sh`) to register the new `pp-update` alias.
- `install.sh` and `install.ps1` now ask one extra interactive question (frontend prompt) — defaults to `n` when piped non-interactively (no tty).

### Follow-up needed
- `package-lock.json` and `.DS_Store` remain untracked (intentionally — empty/noise). Consider `.gitignore` entries if desired.
- Optional: mirror `update.sh` mention into `claude-user-config/README.md` and main `README.md`.
- Existing bootstrapped projects (downloaded before this push) won't have `scripts/update.sh` — first run will need either a clone or a re-bootstrap. Document in upgrade notes.
