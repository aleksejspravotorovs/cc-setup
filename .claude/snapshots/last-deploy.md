# Last Deploy Snapshot
Generated: 2026-03-18T12:15:00Z
Branch: main
Commit: fd85189 fix(windows): keep Claude session inside VS Code terminal

## Changes deployed
 install.ps1       | 37 +++++++++++++++++++++++++++++++------
 scripts/setup.ps1 |  6 ++----
 scripts/start.ps1 | 15 +++++++++++++--
 3 files changed, 46 insertions(+), 12 deletions(-)

## Build status
Pass (no build step — setup/scaffolding repo)

## Context for next /prime
- Key files changed: install.ps1, scripts/setup.ps1, scripts/start.ps1
- New components added: none
- New routes added: none
- Breaking changes: Windows setup.ps1 no longer auto-launches (prints instructions instead)
- Follow-up needed: none
- Prior commit (same session): 03ef4a0 — macOS fixes (piped install, pp-setup alias, .cleo cleanup)
