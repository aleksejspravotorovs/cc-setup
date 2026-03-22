# Last Deploy Snapshot
Generated: 2026-03-22T12:15:00Z
Branch: main
Commit: 2e05ac7 fix(setup): defer git identity config to first commit, not install

## Changes deployed (this session)
- 2ffbb90 fix(mac): allow install without admin rights — nvm fallback, optional tmux
- 2e05ac7 fix(setup): defer git identity config to first commit, not install

## Build status
Pass (no build step — setup/scaffolding repo)

## Context for next /prime
- Key files changed: scripts/setup.sh
- New components added: `install_node_via_nvm()` function in setup.sh
- New routes added: none
- Breaking changes:
  - Homebrew failure no longer exits setup — continues with alternatives
  - tmux failure no longer exits setup — falls back to in-process teammate mode
  - Git identity (user.name/email) no longer prompted during install — deferred to first commit
- Follow-up needed: user daniilgrigorjev should re-run install to verify non-admin flow works end-to-end
