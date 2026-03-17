# Claude Code Setup — macOS

## Quick start (one command)

Open VS Code, open your project folder, open the terminal (`Ctrl+``), and run:

```bash
curl -fsSL https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.sh | bash
```

This downloads the scripts and runs the full setup. Follow the prompts.

## What it installs

The setup script detects what's missing and offers to install each item:

1. **Xcode Command Line Tools** — git, compilers, build tools
2. **Homebrew** — macOS package manager (handles Apple Silicon automatically)
3. **Git** — version control + prompts to configure user.name/email
4. **Node.js + npm** — JavaScript runtime
5. **Claude CLI** — `npm install -g @anthropic-ai/claude-code`
6. **tmux** — terminal multiplexer for agent team split panes
7. **Project dependencies** — `npm install`
8. **VS Code extensions** — ESLint, Tailwind CSS IntelliSense, Prettier

It also downloads:
- `.claude/agents/` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude/commands/` — 4 slash commands (/prime, /build-with-agent-team, /deploy, /research)
- `.claude/settings.json` — agent teams configuration
- `scripts/start.sh` — tmux session launcher
- `.tmux.agent.conf` — tmux configuration for agent panes
- `CLAUDE.md`, `AGENTS.md` — project instructions for Claude

## After setup

### Start a Claude session

```bash
pp
```

This launches a tmux session with Claude (`--dangerously-skip-permissions`) in the left pane and a git watch loop in the right pane.

### Re-run setup

```bash
pp-setup
```

### Set up a new project

```bash
mkdir my-new-project && cd my-new-project
curl -fsSL https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.sh | bash
```

### Inside Claude

| Command | What it does |
|---|---|
| `/prime` | Load codebase context |
| `/build-with-agent-team` | Spawn agent team (auto split panes) |
| `/research <topic>` | Spawn research agent |
| `/deploy` | Commit, push, snapshot |

## Troubleshooting

**"pp: command not found"** (or whatever alias you chose)
Run `source ~/.zshrc` or open a new terminal. The setup adds your quick commands to your shell profile.

**"tmux not found"**
Run `brew install tmux`, or re-run setup.

**Homebrew on Apple Silicon**
The setup handles `/opt/homebrew` automatically and adds it to your `.zshrc`.
