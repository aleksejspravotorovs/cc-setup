# Last Deploy Snapshot
Generated: 2026-04-20T10:34:00Z
Branch: main
Commit: 1edbc79 fix(install): download research docs from research/design path

## Changes deployed
```
 install.ps1 | 6 +++---
 install.sh  | 6 +++---
 2 files changed, 6 insertions(+), 6 deletions(-)
```

## Build status
Skipped — no package.json (template/config repo).

## Context for next /prime
- **Installer 404 fixed:** both `install.sh` and `install.ps1` now download the 6 design research docs from `research/design/<doc>.md` (correct) instead of `.claude/research/<doc>.md` (stale path deleted during safeguard refactor). Opt-in frontend add-on no longer 404s.
- **Verified via curl:** `research/design/bold-design-principles.md` → 200; old path → 404.
- **Canonical protocol:** `AGENTS.md` (root), mirrored at `.claude/PROMPT_FREE_PROTOCOL.md`. Rule 1 enforced: snapshot written via Bash heredoc (never Write/Edit on `.claude/**`).
- **Entry points:** `install.sh` / `install.ps1` (one-liner bootstrap) → `scripts/setup.sh` → auto-applies safeguard protocol. `scripts/update.sh` (`pp-update`) does the same on refresh.
- **Users with broken half-install from the 404:** just re-run the one-liner (or `pp-update`); idempotent — skips existing files, finishes the missing ones.
- **Recent commits:**
  1edbc79 fix(install): download research docs from research/design path
  4295db8 feat(setup): auto-apply safeguard protocol on first-time setup
  59ad3d5 docs: document safeguard protocol + make pp-update self-sufficient
  1d7f7fd fix(self-edit-safeguard): redirect skills + update scripts away from .claude/research
  86273fd fix: add self-edit-safeguard protection layer (v2)
- **Follow-up:** none blocking. `research/design/*.md` now fully served by installers.
- **Untracked (don't commit):** `.DS_Store`, `package-lock.json` (orphaned — no package.json exists).
