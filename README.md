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
- Xcode CLT + Homebrew (macOS) or Git for Windows + winget (Windows)
- Node.js, npm, Claude CLI, tmux (macOS)
- VS Code extensions: ESLint, Tailwind CSS IntelliSense, Prettier

**Project configured**:
- `.claude/agents/` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude/commands/` — 5 slash commands (/prime, /build-with-agent-team, /deploy, /research, /cleo-install)
- Agent teams settings, tmux config, session launcher

**Global commands added**:
- `cc` — start a Claude session (works in any project)
- `cc-setup` — run setup in any project

## Usage

```bash
# Start working
cc

# Inside Claude
/prime                    # Load codebase context
/build-with-agent-team    # Spawn agent team
/deploy                   # Commit, push, snapshot
```

## Detailed instructions

- [macOS setup guide](SETUP-MAC.md)
- [Windows setup guide](SETUP-WINDOWS.md)
