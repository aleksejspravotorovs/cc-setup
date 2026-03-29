# Last Deploy Snapshot
Generated: 2026-03-29T14:30:00Z
Branch: main
Commit: 69a0c52 fix(setup): pp command now launches Claude in current folder, not cc-setup

## Changes deployed (this session)
- 69a0c52 fix(setup): pp command now launches Claude in current folder, not cc-setup

## Build status
Pass (no build step — setup/scaffolding repo)

## Context for next /prime
- Key files changed: scripts/start.sh, scripts/start.ps1, scripts/setup.sh, scripts/setup.ps1, .claude/settings.json
- New components added: none
- New routes added: none
- Breaking changes:
  - `pp` no longer cd's to cc-setup — it launches Claude in the current directory ($PWD)
  - Users with existing `pp` alias must re-run setup (or `pp-setup`) to get the updated alias
  - start.sh/start.ps1 now accept an optional directory argument (defaults to $PWD)
- Follow-up needed: users who already installed should re-run setup to update their shell alias
