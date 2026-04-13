# cc-setup

One-command setup for Claude Code + Agent Teams. Installs all dependencies, configures VS Code, and gets you coding in minutes.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.sh | bash
```

### Windows

```powershell
irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
```

Open your project folder in VS Code, open the terminal, paste the command, and follow the prompts.

## What you get

**Tools installed** (skips what's already present):

| Tool | macOS | Linux | Windows |
|------|-------|-------|---------|
| Xcode CLT + Homebrew | Yes | — | — |
| Git | Via Homebrew | Expected pre-installed | Via winget/Chocolatey |
| Node.js + npm | Via Homebrew | Via apt/dnf/pacman | Via winget/Chocolatey |
| Claude CLI | npm global | npm global | npm global |
| tmux | Via Homebrew | Via apt/dnf/yum/pacman/apk | Via WSL (auto-installed) |
| WSL + Ubuntu | — | — | Auto-installed if missing |
| Claude CLI in WSL | — | — | Auto-installed for split panes |
| VS Code extensions | ESLint, Tailwind CSS, Prettier | ESLint, Tailwind CSS, Prettier | ESLint, Tailwind CSS, Prettier |

**Project configured**:
- `.claude/agents/` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude/commands/` — 4 slash commands (/prime, /build-with-agent-team, /deploy, /research)
- `.claude/settings.json` — agent teams configuration
- `.tmux.agent.conf` — tmux config for agent panes (macOS/Linux)
- `scripts/start.sh` — tmux session launcher (macOS/Linux)
- `scripts/start.ps1` — WSL tmux session launcher (Windows)
- `CLAUDE.md`, `AGENTS.md` — project instructions for Claude

**User-scope Claude Code setup** (optional, macOS/Linux):
- `claude-user-config/` — 6 plugins + 5 GSD hook scripts + sanitized global settings.json
- `scripts/install-plugins.sh` — one-shot installer for plugins/hooks/settings (`bash scripts/install-plugins.sh`)
- See [claude-user-config/README.md](claude-user-config/README.md) for the plugin list and what gets wired up.

**Quick commands added** (persisted in shell profile):
- `pp` — launch Claude session (tmux + split pane git watch, `--dangerously-skip-permissions`)
- `pp-setup` — re-run setup for this project

## Usage

```bash
# Start working
pp

# Re-run setup
pp-setup

# Inside Claude
/prime                    # Load codebase context
/build-with-agent-team    # Spawn agent team
/deploy                   # Commit, push, snapshot
```

## Detailed instructions

- [macOS setup guide](SETUP-MAC.md)
- [Linux setup guide](SETUP-LINUX.md)
- [Windows setup guide](SETUP-WINDOWS.md)
