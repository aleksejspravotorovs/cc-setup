# Claude Code Setup — Windows

## Quick start (one command)

Open VS Code, open your project folder, open the terminal (`Ctrl+``), and run:

```powershell
irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
```

This downloads the scripts and runs the full setup. Follow the prompts.

## What it installs

The setup script detects what's missing and offers to install each item:

1. **Git for Windows** — via winget or Chocolatey (required by Claude CLI)
2. **Node.js LTS** — JavaScript runtime, via winget or Chocolatey
3. **Claude CLI** — `npm install -g @anthropic-ai/claude-code`
4. **Project dependencies** — `npm install`
5. **VS Code extensions** — ESLint, Tailwind CSS IntelliSense, Prettier
6. **Windows Terminal** — recommended for split-pane view (checked, not auto-installed)

It also creates:
- `.claude\agents\` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude\commands\` — 5 slash commands (/prime, /build-with-agent-team, /deploy, /cleo-install, /research)
- `.claude\settings.json` — agent teams configuration
- `scripts\start.ps1` — Windows Terminal session launcher

## After setup

### Start a Claude session

```powershell
cc
```

### Set up a new project

```powershell
mkdir my-new-project; cd my-new-project
cc-setup
```

Or if you haven't run setup before in any project:

```powershell
New-Item -ItemType Directory -Path scripts -Force
irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
```

### Inside Claude

| Command | What it does |
|---|---|
| `/prime` | Load codebase context |
| `/build-with-agent-team` | Spawn agent team |
| `/research <topic>` | Spawn research agent |
| `/deploy` | Commit, push, snapshot |

## Troubleshooting

**"cc: The term 'cc' is not recognized"**
Restart PowerShell or run `. $PROFILE`. The setup adds `cc` and `cc-setup` to your PowerShell profile.

**"execution of scripts is disabled"**
Use `.\scripts\setup.bat` instead — it bypasses execution policy automatically.

**Windows Terminal not installed**
Install it for split-pane support: `winget install Microsoft.WindowsTerminal`
