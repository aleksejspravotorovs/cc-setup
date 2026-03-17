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

It also downloads:
- `.claude\agents\` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude\commands\` — 4 slash commands (/prime, /build-with-agent-team, /deploy, /research)
- `.claude\settings.json` — agent teams configuration
- `scripts\start.ps1` — Windows Terminal session launcher

## After setup

### Start a Claude session

```powershell
pp
```

### Re-run setup

```powershell
pp-setup
```

### Set up a new project

```powershell
mkdir my-new-project; cd my-new-project
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

**"pp: The term 'pp' is not recognized"** (or whatever alias you chose)
Restart PowerShell or run `. $PROFILE`. The setup adds your quick commands to your PowerShell profile.

**"execution of scripts is disabled"**
Use `.\scripts\setup.bat` instead — it bypasses execution policy automatically.

**Windows Terminal not installed**
Install it for split-pane support: `winget install Microsoft.WindowsTerminal`
