# Claude Code Setup — Windows

## Quick start (one command)

Open VS Code, open your project folder, open the terminal (`` Ctrl+` ``), and run:

```powershell
irm https://raw.githubusercontent.com/AleksejsPravotorovs/cc-setup/main/install.ps1 | iex
```

This downloads the scripts and runs the full setup. Follow the prompts.

If PowerShell blocks script execution, use the batch launcher instead:

```cmd
scripts\setup.bat
```

## What it installs

The setup script detects what's missing and offers to install each item:

1. **Execution policy** — sets `RemoteSigned` for current user (so PowerShell scripts can run)
2. **Git for Windows** — via winget or Chocolatey (includes Git Bash, required by Claude CLI)
3. **Node.js LTS** — JavaScript runtime, via winget or Chocolatey
4. **npm** — verified and PATH-resolved after Node.js install
5. **Claude CLI** — `npm install -g @anthropic-ai/claude-code`
6. **WSL (Windows Subsystem for Linux)** — required for tmux split-pane agent teams
7. **Ubuntu distro in WSL** — auto-installed if WSL has no distro
8. **tmux in WSL** — terminal multiplexer for agent team split panes
9. **UTF-8 locale in WSL** — generates `en_US.UTF-8` and `ru_RU.UTF-8` locales for Cyrillic and Unicode support
10. **Claude CLI in WSL** — required for split-pane mode (includes Node.js in WSL if needed)
11. **Project dependencies** — `npm install` (only if `package.json` exists)
12. **VS Code extensions** — ESLint, Tailwind CSS IntelliSense, Prettier

It also configures:
- `~\.claude\settings.json` — user-level agent teams settings
- `.claude\settings.json` — project-level agent teams settings
- `.gitignore` — adds `.env` and `.env.*` entries

## What it downloads

The installer (`install.ps1`) downloads these files before running setup:

- `scripts\setup.ps1` — full setup script
- `scripts\start.ps1` — WSL tmux session launcher
- `scripts\fix-profile.ps1` — PowerShell profile repair tool (UTF-8 BOM fix for Cyrillic paths)
- `scripts\setup.bat` — batch wrapper (bypasses execution policy)
- `scripts\start.bat` — batch wrapper for session launcher
- `.claude\agents\` — 7 agent definitions (lead, frontend, backend, devops, skeptic, qa, researcher)
- `.claude\commands\` — 4 slash commands (/prime, /build-with-agent-team, /deploy, /research)
- `.claude\settings.json` — agent teams configuration (only if not present)
- `CLAUDE.md`, `AGENTS.md` — project instructions for Claude (only if not present)

## How split-pane mode works on Windows

Windows uses WSL + tmux to run Claude with split-pane agent teams:

1. `start.ps1` checks that WSL, tmux, UTF-8 locale, and Claude CLI are available in WSL
2. Auto-installs any missing components (Ubuntu distro, tmux, locale, Node.js, Claude CLI)
3. Converts your Windows project path to a WSL path (`/mnt/c/...`) — done in PowerShell to avoid encoding issues
4. If the path contains Cyrillic or other non-ASCII characters, creates an NTFS junction with an ASCII-only path
5. Launches a tmux session inside WSL with Claude running in split-pane mode
6. Agent teammates auto-appear as tmux panes

Your project files are accessed via WSL's `/mnt/` mount — no file copying needed. Cyrillic paths are handled automatically via NTFS junctions.

## After setup

### Start a Claude session

```powershell
pp
```

Or run directly:

```powershell
.\scripts\start.ps1
```

Or via batch file (no execution policy needed):

```cmd
scripts\start.bat
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

**"pp: The term 'pp' is not recognized"**
Restart PowerShell or run `. $PROFILE`. The setup adds quick commands to your PowerShell profile.

**"execution of scripts is disabled"**
Use `scripts\setup.bat` instead — it bypasses execution policy automatically. Or fix it manually:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**WSL install requires a restart**
After WSL is installed for the first time, you must restart your computer. Then re-run `pp-setup` or `.\scripts\setup.ps1`.

**"WSL has no Linux distribution installed"**
Run `wsl --install -d Ubuntu` and follow the prompts to create a Unix username/password. Then re-run setup.

**Claude CLI not working in WSL**
Try reinstalling manually:
```powershell
wsl bash -c "sudo npm install -g @anthropic-ai/claude-code"
```

**"WSL cannot access project path"**
Your project must be on a Windows drive (C:, D:, etc.). WSL accesses it via `/mnt/c/...`. Network drives and UNC paths are not supported.

**Project path contains Cyrillic characters (e.g. `Рабочий стол`)**
The setup handles this automatically by creating an NTFS junction with an ASCII path. If you see path-related errors, the simplest long-term fix is to move your project to an ASCII path like `C:\projects\myapp`. Otherwise, re-run `pp-setup` to recreate the junction.

**PowerShell profile corrupted — `pp` shows `?????` instead of path**
PowerShell 5.1 can corrupt Cyrillic characters in profile scripts. Run the repair tool:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fix-profile.ps1
```
This rewrites your profile with UTF-8 BOM encoding so Cyrillic paths display correctly.

**Cyrillic characters display as underscores or garbage in tmux**
The WSL locale needs to be set to UTF-8. Re-run setup (`pp-setup`) or fix manually:
```powershell
wsl bash -c "sudo apt-get install -y locales && sudo locale-gen en_US.UTF-8 ru_RU.UTF-8 && sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
wsl --shutdown
```
Then restart your terminal. For best results, use Windows Terminal (pre-installed on Windows 11, or `winget install Microsoft.WindowsTerminal` on Windows 10) — it has full Unicode rendering with the Cascadia Code font.

**tmux not found in WSL**
Install manually:
```powershell
wsl bash -c "sudo apt-get update && sudo apt-get install -y tmux"
```
