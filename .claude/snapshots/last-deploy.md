# Last Deploy Snapshot
Generated: 2026-03-20T10:33:00Z
Branch: main
Commit: 42bb261 fix(windows): handle Cyrillic paths in profile, WSL, and tmux launch

## Changes deployed (this session)
- 306b724 chore: remove all CLEO references and .cleo/ directory
- c5bb66a docs: rewrite installation guides for all platforms
- daa05bb fix(windows): configure UTF-8 locale in WSL for Cyrillic support
- 49b80d5 fix(windows): harden Cyrillic locale checks
- 42bb261 fix(windows): handle Cyrillic paths in profile, WSL, and tmux launch

## Build status
Pass (no build step -- setup/scaffolding repo)

## Context for next /prime
- Key files changed: scripts/setup.ps1, scripts/start.ps1, install.ps1, SETUP-WINDOWS.md, SETUP-LINUX.md (new), SETUP-MAC.md, README.md
- New components added: scripts/fix-profile.ps1 (UTF-8 BOM profile repair tool), SETUP-LINUX.md, bugfix/bugfix-report-2026-03-20.md
- New routes added: none
- Breaking changes:
  - start.ps1: --dangerously-skip-permissions removed (Claude now prompts for permissions)
  - start.ps1: wslpath replaced with PowerShell-side path conversion
  - setup.ps1: profile written with UTF-8 BOM instead of default encoding
- Follow-up needed: test full install flow on Windows with Cyrillic project path
