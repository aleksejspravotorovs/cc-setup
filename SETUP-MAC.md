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

It also creates:
- `.claude/agents/` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude/commands/` — 5 slash commands (/prime, /build-with-agent-team, /deploy, /cleo-install, /research)
- `.claude/settings.json` — agent teams configuration
- `scripts/start.sh` — tmux session launcher
- `.tmux.agent.conf` — tmux configuration for agent panes

## After setup

### Start a Claude session

```bash
cc
```

### Set up a new project

```bash
mkdir my-new-project && cd my-new-project
cc-setup
```

Or if you haven't run setup before in any project:

```bash
mkdir -p scripts
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

**"cc: command not found"**
Run `source ~/.zshrc` or open a new terminal. The setup adds `cc` and `cc-setup` to your shell profile.

**"tmux not found"**
Run `brew install tmux`, or re-run `cc-setup`.

**Homebrew on Apple Silicon**
The setup handles `/opt/homebrew` automatically and adds it to your `.zshrc`.
