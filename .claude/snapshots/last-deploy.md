# Last Deploy Snapshot
Generated: 2026-03-22T12:30:00Z
Branch: main
Commit: 897c68c fix(setup): require tmux, always use tmux teammateMode

## Changes deployed (this session)
- 2ffbb90 fix(mac): allow install without admin rights — nvm fallback, optional tmux
- 2e05ac7 fix(setup): defer git identity config to first commit, not install
- 897c68c fix(setup): require tmux, always use tmux teammateMode

## Build status
Pass (no build step — setup/scaffolding repo)

## Context for next /prime
- Key files changed: scripts/setup.sh, scripts/start.sh
- New components added: `install_node_via_nvm()` function in setup.sh
- New routes added: none
- Breaking changes:
  - Homebrew failure no longer exits setup — continues with nvm for Node.js
  - Git identity (user.name/email) no longer prompted during install — deferred to first commit
  - tmux remains required; teammateMode always "tmux"
- Follow-up needed: user daniilgrigorjev should re-run install to verify non-admin flow reaches pp command
