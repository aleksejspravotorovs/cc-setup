#Requires -Version 5.1
# +==================================================================+
# |  Claude Code + Agent Teams Setup (Windows)                       |
# |  Equivalent of scripts/setup.sh for Windows / PowerShell         |
# |  First run:  full setup (tools, agents, commands, settings).     |
# |  Repeat run: verify everything is in place, then launch.         |
# +==================================================================+

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

# --- Logging helpers ----------------------------------------------

function Log($msg)  { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Info($msg) { Write-Host "  [ii] $msg" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "  [XX] $msg" -ForegroundColor Red }

$ExpectedAgents   = @("lead", "frontend", "backend", "devops", "skeptic", "qa", "researcher")
$ExpectedCommands = @("prime", "build-with-agent-team", "deploy", "research")
$VscodeExtensions = @("dbaeumer.vscode-eslint", "bradlc.vscode-tailwindcss", "esbenp.prettier-vscode")
$CreatedAnything  = $false

# ===================================================================
# INSTALL HELPERS
# ===================================================================

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-GitBash {
    # Claude Code on Windows requires Git Bash
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitDir = Split-Path -Parent (Split-Path -Parent (Get-Command git).Source)
        $bashPath = Join-Path $gitDir "bin\bash.exe"
        if (Test-Path $bashPath) {
            Log "Git Bash found: $bashPath"
            return $true
        }
    }

    # Check common install locations
    $commonPaths = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            Log "Git Bash found: $p"
            Info "If Claude cannot find it, set: `$env:CLAUDE_CODE_GIT_BASH_PATH = '$p'"
            return $true
        }
    }

    Warn "Git for Windows is not installed (required by Claude Code)"
    Write-Host ""
    $install = Read-Host "    Install Git for Windows now? (y/n)"
    if ($install -ne "y") {
        Fail "Git for Windows is required. Install: https://git-scm.com/downloads/win"
        return $false
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Info "Installing Git for Windows via winget..."
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Log "Git for Windows installed"
            return $true
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Info "Installing Git for Windows via Chocolatey..."
        choco install git -y
        Refresh-Path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Log "Git for Windows installed"
            return $true
        }
    }

    Fail "Automatic installation failed. Install manually:"
    Write-Host "    https://git-scm.com/downloads/win" -ForegroundColor White
    Write-Host "    or: winget install Git.Git" -ForegroundColor White
    return $false
}

function Install-NodeJS {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Log "Node.js found: $(node --version)"
        return $true
    }

    Warn "Node.js is not installed (required for Claude CLI and npm packages)"
    Write-Host ""
    $install = Read-Host "    Install Node.js LTS now? (y/n)"
    if ($install -ne "y") {
        Fail "Node.js is required. Install manually: https://nodejs.org"
        return $false
    }

    # Try winget first (Windows 10 1709+)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Info "Installing Node.js LTS via winget..."
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Log "Node.js installed: $(node --version)"
            return $true
        }
    }

    # Try Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Info "Installing Node.js LTS via Chocolatey..."
        choco install nodejs-lts -y
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Log "Node.js installed: $(node --version)"
            return $true
        }
    }

    Fail "Automatic installation failed. Install manually:"
    Write-Host "    https://nodejs.org/en/download" -ForegroundColor White
    Write-Host "    or: winget install OpenJS.NodeJS.LTS" -ForegroundColor White
    return $false
}

function Install-ClaudeCLI {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $v = (claude --version 2>$null | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
        Log "Claude CLI found: $v"

        # Check minimum version for agent teams (>= 2.1.32)
        if ($v -match '^(\d+)\.(\d+)\.(\d+)$') {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]; $patch = [int]$Matches[3]
            if ($major -lt 2 -or ($major -eq 2 -and $minor -lt 1) -or
                ($major -eq 2 -and $minor -eq 1 -and $patch -lt 32)) {
                Warn "Claude $v -- agent teams require >= 2.1.32"
                Info "Update: npm install -g @anthropic-ai/claude-code@latest"
            }
        }
        return $true
    }

    Warn "Claude CLI is not installed"
    Write-Host ""
    $install = Read-Host "    Install Claude CLI now? (y/n)"
    if ($install -ne "y") {
        Fail "Claude CLI is required. Install: npm install -g @anthropic-ai/claude-code"
        return $false
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Fail "npm not available -- install Node.js first"
        return $false
    }

    Info "Installing Claude CLI via npm..."
    npm install -g @anthropic-ai/claude-code
    Refresh-Path

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $v = (claude --version 2>$null | Select-Object -First 1) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
        Log "Claude CLI installed: $v"
        return $true
    }

    Fail "Installation failed. Try manually: npm install -g @anthropic-ai/claude-code"
    return $false
}

# ===================================================================
# DETECT REPEAT vs FIRST RUN
# ===================================================================

function Test-SetupComplete {
    if (-not (Test-Path ".claude/settings.json"))  { return $false }
    if (-not (Test-Path "scripts/start.ps1"))       { return $false }
    if (-not (Test-Path ".claude/agents"))           { return $false }
    if (-not (Test-Path ".claude/commands"))          { return $false }
    if (-not (Test-Path ".claude/snapshots"))         { return $false }
    foreach ($agent in $ExpectedAgents) {
        if (-not (Test-Path ".claude/agents/$agent.md")) { return $false }
    }
    foreach ($cmd in $ExpectedCommands) {
        if (-not (Test-Path ".claude/commands/$cmd.md")) { return $false }
    }
    return $true
}

# ===================================================================
# REPEAT RUN -- verify + launch
# ===================================================================

if (Test-SetupComplete) {
    Write-Host ""
    Write-Host "+======================================+" -ForegroundColor Cyan
    Write-Host "|  Claude Code -- Already Set Up       |" -ForegroundColor Cyan
    Write-Host "+======================================+" -ForegroundColor Cyan
    Write-Host ""

    $issues = 0

    # Tools
    if (-not (Install-GitBash))   { $issues++ }
    if (-not (Install-NodeJS))    { $issues++ }
    if (-not (Install-ClaudeCLI)) { $issues++ }

    # Windows Terminal (recommended, not required)
    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        Log "Windows Terminal found"
    } else {
        Info "Windows Terminal not found (recommended for split-pane view)"
        Write-Host "      winget install Microsoft.WindowsTerminal" -ForegroundColor White
    }

    # Project dependencies
    if (Test-Path "node_modules") {
        Log "Project dependencies installed (node_modules)"
    } else {
        Warn "node_modules missing -- run 'npm install'"
        $issues++
    }

    # VS Code extensions
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Log "VS Code CLI found"
        $installedExt = code --list-extensions 2>$null
        $missingExt = 0
        foreach ($ext in $VscodeExtensions) {
            if ($installedExt -notcontains $ext) { $missingExt++ }
        }
        if ($missingExt -gt 0) {
            Warn "$missingExt recommended VS Code extension(s) missing"
            Info "Re-run setup to install, or: code --install-extension <id>"
            $issues++
        } else {
            Log "VS Code extensions: all recommended installed"
        }
    } else {
        Info "VS Code 'code' command not in PATH (optional)"
    }

    # Quick commands
    $psProf = $PROFILE
    if ((Test-Path $psProf) -and ((Get-Content $psProf -Raw -ErrorAction SilentlyContinue) -match 'function pp ')) {
        Log "Quick commands registered (pp, pp-setup)"
    } else {
        Warn "Quick commands (pp, pp-setup) not in PowerShell profile"
        $issues++
    }

    # User-level settings
    $userSettings = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $userSettings) {
        $content = Get-Content $userSettings -Raw
        if ($content -match "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") {
            Log "Agent teams enabled (user settings)"
        } else {
            Warn "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS missing in user settings"
            $issues++
        }
        if ($content -match "teammateMode") {
            Log "teammateMode set (user settings)"
        } else {
            Warn "teammateMode missing in user settings"
            $issues++
        }
    } else {
        Warn "No user settings at $userSettings"
        $issues++
    }

    # Project artifacts
    Log "Project settings:  .claude\settings.json"
    Log "Agents ($($ExpectedAgents.Count)):        $($ExpectedAgents -join ', ')"
    Log "Commands ($($ExpectedCommands.Count)):      $($ExpectedCommands -join ', ')"
    Log "Launcher:          scripts\start.ps1"

    if ($issues -gt 0) {
        Write-Host ""
        Warn "$issues issue(s) found above -- review before continuing"
        Write-Host ""
        $launch = Read-Host "    Launch anyway? (y/n)"
        if ($launch -ne "y") { exit 0 }
    }

    Write-Host ""
    Log "Launching Claude session..."
    Write-Host ""
    & "$ProjectDir\scripts\start.ps1"
    exit 0
}

# ===================================================================
# FIRST RUN -- full setup
# ===================================================================

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Claude Code + Agent Teams Setup     |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# --- Pre-flight ---------------------------------------------------

$gitOk   = Install-GitBash
$nodeOk  = Install-NodeJS
$claudeOk = Install-ClaudeCLI

if (-not $gitOk) {
    Fail "Git for Windows is required by Claude Code. Cannot continue."
    Write-Host "    Install: winget install Git.Git" -ForegroundColor White
    Write-Host "    Then close and reopen this terminal." -ForegroundColor White
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not $claudeOk) {
    Fail "Claude CLI is required. Cannot continue."
    exit 1
}

if (-not $nodeOk) {
    Warn "Node.js missing -- some features will not be available."
}

Log "Pre-flight passed"
Write-Host ""

# --- User-level settings -----------------------------------------

$userSettingsDir  = "$env:USERPROFILE\.claude"
$userSettingsFile = "$userSettingsDir\settings.json"

if (-not (Test-Path $userSettingsDir)) { New-Item -ItemType Directory -Path $userSettingsDir -Force | Out-Null }

if (Test-Path $userSettingsFile) {
    $content = Get-Content $userSettingsFile -Raw
    $needsUpdate = $false
    if ($content -notmatch "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") { $needsUpdate = $true }
    if ($content -notmatch "teammateMode")                         { $needsUpdate = $true }

    if ($needsUpdate) {
        Info "Updating user settings for agent teams..."
        try {
            $settings = $content | ConvertFrom-Json
            if (-not $settings.env) { $settings | Add-Member -NotePropertyName "env" -NotePropertyValue ([PSCustomObject]@{}) }
            $settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force
            $settings | Add-Member -NotePropertyName "teammateMode" -NotePropertyValue "tmux" -Force
            $settings | ConvertTo-Json -Depth 10 | Set-Content $userSettingsFile -Encoding UTF8
            Log "Updated $userSettingsFile"
        } catch {
            Warn "Could not auto-update user settings. Add manually:"
            Write-Host '    env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' -ForegroundColor White
            Write-Host '    teammateMode = "tmux"' -ForegroundColor White
        }
    } else {
        Log "User settings: agent teams already configured"
    }
} else {
    $settingsJson = @'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
'@
    $settingsJson | Set-Content $userSettingsFile -Encoding UTF8
    Log "Created $userSettingsFile"
}

# --- Project-level settings ---------------------------------------

if (-not (Test-Path ".claude")) { New-Item -ItemType Directory -Path ".claude" -Force | Out-Null }

if (Test-Path ".claude/settings.json") {
    $content = Get-Content ".claude/settings.json" -Raw
    $needsUpdate = $false
    if ($content -notmatch "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") { $needsUpdate = $true }
    if ($content -notmatch "teammateMode")                         { $needsUpdate = $true }

    if ($needsUpdate) {
        try {
            $settings = $content | ConvertFrom-Json
            if (-not $settings.env) { $settings | Add-Member -NotePropertyName "env" -NotePropertyValue ([PSCustomObject]@{}) }
            $settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force
            $settings | Add-Member -NotePropertyName "teammateMode" -NotePropertyValue "tmux" -Force
            $settings | ConvertTo-Json -Depth 10 | Set-Content ".claude/settings.json" -Encoding UTF8
            Log "Updated .claude\settings.json"
        } catch {
            Warn "Could not auto-update project settings"
        }
    } else {
        Log "Project settings already configured"
    }
} else {
    $projSettings = @'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
'@
    $projSettings | Set-Content ".claude/settings.json" -Encoding UTF8
    Log "Created .claude\settings.json"
    $CreatedAnything = $true
}

# --- Agents (only create missing ones) ----------------------------

if (-not (Test-Path ".claude/agents")) { New-Item -ItemType Directory -Path ".claude/agents" -Force | Out-Null }

$AgentContent = @{}

$AgentContent["lead"] = @'
---
description: Lead/PM -- owns scope, task breakdown, merges, prevents redesign.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Lead / PM

## Responsibilities
1. Analyze the task and produce a SHARED EXECUTION CONTRACT:
   - Scope (what's in, what's out)
   - File ownership per agent (non-overlapping)
   - Acceptance criteria
   - Merge order
2. Split tasks for Frontend/Backend/DevOps with non-overlapping outputs.
3. Enforce "LOCK & PATCH": change only what is requested.
4. Ensure the project builds after each merge.
5. Do NOT implement UI/business logic -- only contract, coordination, and merge.

## CRITICAL: Lead MUST NOT implement fixes
When skeptic or QA report bugs/findings:
1. **Create fix tasks** with clear descriptions of what to fix
2. **Spawn the relevant agent(s)** (frontend, backend, etc.) to implement fixes
3. **Re-run skeptic + QA** after fixes land to verify
4. **Repeat** until all checks pass

Lead's role is CONTRACT + COORDINATION + VERIFICATION ORCHESTRATION only.
Never write implementation code, UI logic, or bug fixes directly.

## Output format
- Task list per agent (bullets)
- Merge order
- Definition of Done
'@

$AgentContent["frontend"] = @'
---
description: Frontend -- implements UI pages, components, and client-side logic.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Frontend

## Lock
- Use existing UI-kit components and design tokens.
- No redesign, no new components unless Lead requests.
- Follow the project's folder patterns for pages and components.

## Responsibilities
- Implement pages/routes as specified in the contract.
- Match designs exactly: spacing, typography, layout.
- Wire forms to API endpoints per the contract.
- Handle all UI states: loading, empty, error, success.

## Deliverables
- Routes/pages + minimal layout scaffolding
- No backend logic; consume agreed contract only
- Build passes
'@

$AgentContent["backend"] = @'
---
description: Backend -- API endpoints, database, auth, server logic.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Backend

## Lock
- Do NOT touch UI layout/styles.
- Keep scope to what the contract specifies.

## Responsibilities
- Implement API endpoints or server actions per the contract.
- Database schema and migrations as needed.
- Standard error format: { error: { code, message, details? } }
- Document required env vars.

## Deliverables
- API endpoints / server actions
- DB setup + migrations (if applicable)
- `.env.example` updates
- Build passes
'@

$AgentContent["devops"] = @'
---
description: DevOps -- local/dev/prod setup, env vars, deployment, CI.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: DevOps

## Lock
- Do not change UI or business logic code.

## Responsibilities
- Maintain `.env.example` based on backend requirements.
- Recommend and configure hosting/deployment.
- Add minimal CI checks (lint + typecheck + build).
- Document local setup steps.

## Deliverables
- Deployment configuration
- Env var checklist
- CI config (if applicable)
'@

$AgentContent["skeptic"] = @'
---
description: Skeptic -- security, UX, and accessibility devil's advocate.
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# ROLE: Skeptic

## Purpose
Challenge every implementation decision for security holes, UX pitfalls, accessibility gaps, edge cases, and scope creep.

## Lock
- Do NOT implement code. Your output is analysis + recommendations.
- Do NOT block progress with hypothetical risks. Every risk must be concrete and actionable.
- Do NOT redesign. Flag issues with the current approach, suggest minimal fixes.

## Review scope
1. **Security**: injection, XSS, CSRF, auth bypass, exposed secrets, missing RLS, insecure token handling.
2. **UX**: confusing flows, missing feedback (loading/error/empty states), broken mobile layouts.
3. **Accessibility**: missing labels, keyboard navigation, color contrast, screen reader support.
4. **Edge cases**: empty data, long strings, concurrent requests, network failures.
5. **Scope creep**: features or abstractions that weren't requested.

## Output format
For each finding:
```
[SEVERITY: critical | high | medium | low]
WHAT: one-line description
WHERE: file path + line or component name
WHY: concrete risk (what breaks, for whom)
FIX: minimal change to resolve it
```

## Findings automation (MANDATORY)
After every review, you MUST update `.claude/findings.md`:
- Add new findings under the appropriate section and severity heading
- Use the checkbox format: `- [ ] **Title** -- description`
- Include source attribution: `Source: Skeptic review, YYYY-MM-DD`
- If a section for the reviewed component doesn't exist, create one
- Do NOT mark items as resolved -- only Lead does that after fixes are verified

## Deliverables
- Structured findings list, severity-ordered (criticals first)
- `.claude/findings.md` updated with all new findings
- No fix suggestions requiring new dependencies or architectural changes unless asked
'@

$AgentContent["qa"] = @'
---
description: QA -- structured pass/fail verification, regression checks, and contract compliance.
allowed-tools: Read, Glob, Grep, Bash
---

# ROLE: QA

## Purpose
Verify implementations meet acceptance criteria, catch regressions, and flag contract violations. Final gate before work is considered done.

## Lock
- Do NOT implement features or fix bugs. Report findings to Lead.
- Do NOT invent requirements. Test against what was specified.
- Every claim must be backed by evidence (command output, file content, build result).

## Verification process
1. **Build check**: build must pass with zero new errors.
2. **Lint check**: lint must not introduce new errors.
3. **Route verification**: new/changed routes render without runtime errors.
4. **Contract compliance**: implementation matches the execution contract.
5. **Regression check**: existing functionality still works after changes.

## Output format
```
## QA Report -- [feature/task name]

### Build
- [ ] Build passes (0 new errors)
- [ ] Lint passes (0 new errors)

### Acceptance criteria
- [ ] Criterion -- PASS/FAIL (evidence)

### Regression
- [ ] Existing routes still render
- [ ] No removed exports or broken imports

### Contract violations
- (list or "None")

### Verdict: PASS / FAIL
Blockers: (list if FAIL)
```

## Deliverables
- Structured pass/fail checklist per task
- Evidence-backed verdicts
'@

$AgentContent["researcher"] = @'
---
description: Researcher -- technical research, best practices analysis, and trade-off evaluation. Read-only.
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch, Write
---

# ROLE: Researcher

## Purpose
Research best practices, patterns, and industry standards. Produce concise, actionable reports with clear recommendations.

## Lock
- Read-only: does NOT edit project source files
- Outputs research ONLY to `.claude/research/` directory
- No implementation -- analysis and recommendations only

## Responsibilities
- Research best practices, patterns, and industry standards
- Analyze trade-offs between competing approaches (3-5 options)
- Check existing research in `.claude/research/` to build on prior findings
- Consider security, performance, complexity, and compatibility
- Cite real-world examples and framework documentation

## Output format
Write reports to `.claude/research/<topic-slug>.md` with:
1. Executive summary (recommended approach in 2-3 sentences)
2. Detailed analysis of each approach (pros/cons)
3. Final recommendation with implementation steps
4. Sources

## Deliverables
- Research report in `.claude/research/`
- Clear recommendation with rationale
- No code changes to project source files
'@

foreach ($agent in $AgentContent.Keys) {
    $path = ".claude/agents/$agent.md"
    if (-not (Test-Path $path)) {
        $AgentContent[$agent] | Set-Content $path -Encoding UTF8
        Log "Created $path"
        $CreatedAnything = $true
    }
}

$agentCount = ($ExpectedAgents | Where-Object { Test-Path ".claude/agents/$_.md" }).Count
Log "Agents ready: $agentCount/$($ExpectedAgents.Count) ($($ExpectedAgents -join ', '))"

# --- Commands (only create missing ones) --------------------------

foreach ($dir in @(".claude/commands", ".claude/snapshots")) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

if (-not (Test-Path ".claude/commands/prime.md")) {
$primeCmd = @'
---
description: Lean codebase prime -- context load (Claude Code)
allowed-tools: Read, Glob
---

# /prime -- Lean Prime

Role: GSD Execution Partner (senior engineer + pragmatic PM). Ship smallest correct change. Be direct. Prevent scope creep.

## 1) Codebase prime (Glob-first, minimal reads)

CLAUDE.md is ALREADY in system context. Do NOT re-read it. Do NOT read style/token CSS files (conventions are documented in CLAUDE.md).

**Glob only** (structure scan, no file reads):
- `src/app/**/page.tsx` -- route inventory
- `src/app/**/route.ts` -- API endpoints
- `src/components/ui/*/index.ts` -- UI-kit inventory
- `src/lib/**/*.ts` -- utilities
- `src/components/**/index.ts` -- feature components
- `.claude/agents/*.md` -- agent roster
- `scripts/*.sh` -- available scripts

**Read only these** (2-4 files max):
- `package.json` -- scripts, deps, versions
- `.claude/snapshots/last-deploy.md` -- previous session context (if exists)
- `.claude/findings.md` -- open bugs and UX issues (if exists)

**Report** (compact, no duplication of CLAUDE.md):
```
Routes: [list from glob]
API: [list from glob]
UI-kit: [component names from glob]
Lib: [utility files from glob]
Feature components: [from glob]
Agents: [names from .claude/agents/ glob]
Scripts: [from scripts/ glob + package.json]
Deps: [key deps from package.json]
Findings: [count by severity from .claude/findings.md, or "none"]
Missing/unexpected: [anything notable]
```

## 2) MCP check (non-blocking)

Glob for `.mcp.json`. If found, note "MCP configured."

## 3) Session template

Output once after prime, then proceed to work:
```
Goal: (1 sentence)
Plan: (3-7 steps)
Lock: (files not to touch)
Change: (files to edit)
Next: (first action)
```

## Rules (always active)
- Ask only truly blocking questions; otherwise state assumptions
- LOCK & PATCH: change only what's required
- Include: exact file paths, patches, commands
- Handle states: loading / empty / error / success
- HARD NO: no new deps, no global tooling changes, no rewrites unless asked

## Team orchestration
- Launch with `./scripts/start.sh` (macOS/Linux) or `.\scripts\start.ps1` (Windows)
- Agents are defined in `.claude/agents/*.md`: lead, frontend, backend, devops, skeptic, qa

## Iteration close
What changed - How to verify - Next action

## Session close
Done - Remaining - Next step - Risks
'@
    $primeCmd | Set-Content ".claude/commands/prime.md" -Encoding UTF8
    Log "Created .claude\commands\prime.md"
    $CreatedAnything = $true
}

if (-not (Test-Path ".claude/commands/build-with-agent-team.md")) {
$teamCmd = @'
# Agent Team Orchestration (Official Agent Teams)

Use the **official Agent Teams mechanism** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

## Agent roster

Agent definitions live in `.claude/agents/*.md`:
- **lead** -- Contract owner + orchestrator (you)
- **frontend** -- UI + client logic
- **backend** -- API + database + server logic
- **devops** -- Infrastructure + deployment
- **skeptic** -- Security + UX devil's advocate (review-only, no code)
- **qa** -- Structured pass/fail verification + regression checks

## Workflow

### Phase 0: Contract (Lead only)
1. Analyze the task
2. Produce a SHARED EXECUTION CONTRACT (scope, file ownership, acceptance criteria, merge order)
3. Create team and spawn teammates

### Phase 1: Spawn team (official mechanism -- MANDATORY)
1. **`TeamCreate`** -- create the team
2. **`TaskCreate`** -- create tasks with descriptions and dependencies
3. **`Agent`** tool with `team_name` and `name` params -- spawn each teammate
4. Teammates appear as split panes automatically

### Phase 2: Coordination
- Teammates claim tasks via `TaskUpdate` and mark completed when done
- Lead reviews outputs against contract

### Phase 3: Fix Cycle (MANDATORY when skeptic/QA find issues)
1. Lead MUST NOT fix bugs directly
2. Create fix tasks -> spawn agents -> re-verify
3. Repeat until clean

### Phase 4: Cleanup
1. Send shutdown_request to each teammate
2. Run TeamDelete
3. Update .claude/findings.md

## Rules
- Agents MUST NOT edit files outside their contracted scope
- Lead MUST NOT implement code -- only contract, coordination, and verification
- `npm run build` must pass after all changes
'@
    $teamCmd | Set-Content ".claude/commands/build-with-agent-team.md" -Encoding UTF8
    Log "Created .claude\commands\build-with-agent-team.md"
    $CreatedAnything = $true
}

if (-not (Test-Path ".claude/commands/deploy.md")) {
$deployCmd = @'
---
description: Commit, deploy, verify, and snapshot session state for next prime
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /deploy -- Commit & Deploy

## 1) Pre-flight
- `git status` -- uncommitted changes?
- `git remote -v` -- remote configured?
- `git branch --show-current` -- current branch?

## 2) Build gate
`npm run build` -- STOP if build fails.

## 3) Commit
Stage changed files (specific files, NOT `git add -A`).
Conventional commit: `type(scope): description`

## 4) Push
`git push origin <current-branch>`

## 5) Session snapshot
Create `.claude/snapshots/last-deploy.md` with changes, build status, and context for next /prime.
'@
    $deployCmd | Set-Content ".claude/commands/deploy.md" -Encoding UTF8
    Log "Created .claude\commands\deploy.md"
    $CreatedAnything = $true
}

if (-not (Test-Path ".claude/commands/research.md")) {
$researchCmd = @'
---
description: Spawn a researcher agent to analyze best practices, patterns, or trade-offs
allowed-tools: Bash, Read, Write, Glob, Grep
---

# /research -- Research Agent

Spawn a researcher agent that produces an actionable report to `.claude/research/`.

## Usage
`/research <topic or question>`

## Procedure
1. Scan `.claude/research/` for existing reports
2. Spawn researcher agent (background) with project context + prior research
3. Agent writes report to `.claude/research/<topic-slug>.md`
'@
    $researchCmd | Set-Content ".claude/commands/research.md" -Encoding UTF8
    Log "Created .claude\commands\research.md"
    $CreatedAnything = $true
}

$cmdCount = ($ExpectedCommands | Where-Object { Test-Path ".claude/commands/$_.md" }).Count
Log "Commands ready: $cmdCount/$($ExpectedCommands.Count) ($($ExpectedCommands -join ', '))"

# --- .gitignore additions -----------------------------------------

if (Test-Path ".gitignore") {
    $ignoreContent = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    $entries = @(".env", ".env.*")
    foreach ($entry in $entries) {
        if ($ignoreContent -notmatch [regex]::Escape($entry)) {
            Add-Content ".gitignore" $entry
        }
    }
    Log "Updated .gitignore"
}

# --- Quick commands (pp, pp-setup) --------------------------------

$psProfile = $PROFILE
if (-not (Test-Path $psProfile)) {
    $profileDir = Split-Path -Parent $psProfile
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
}

$hasQuickCmds = $false
if (Test-Path $psProfile) {
    $profileContent = Get-Content $psProfile -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match 'function pp ') { $hasQuickCmds = $true }
}

if ($hasQuickCmds) {
    Log "Quick commands already registered (pp, pp-setup)"
} else {
    Write-Host ""
    Info "Quick commands:"
    Write-Host "    pp         -- launch Claude session"
    Write-Host "    pp-setup   -- re-run setup for this project"
    Write-Host ""
    $addCmds = Read-Host "    Add 'pp' and 'pp-setup' to PowerShell profile? (y/n)"
    if ($addCmds -eq "y") {
        $cmdBlock = @"

# Claude Code -- quick commands (added by setup.ps1)
function pp { Set-Location "$ProjectDir"; & ".\scripts\start.ps1" @args }
function pp-setup { Set-Location "$ProjectDir"; powershell -ExecutionPolicy Bypass -File ".\scripts\setup.ps1" @args }
"@
        Add-Content $psProfile $cmdBlock
        Log "Added 'pp' and 'pp-setup' to $psProfile"
        Info "Restart PowerShell or run '. `$PROFILE' to use them"
    } else {
        Info "Skipping quick commands. Add manually later."
    }
}

# --- Project dependencies -----------------------------------------

if (Test-Path "node_modules") {
    Log "Project dependencies installed (node_modules)"
} else {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Info "Installing project dependencies (npm install)..."
        npm install
        if (Test-Path "node_modules") {
            Log "Project dependencies installed"
        } else {
            Warn "npm install failed"
        }
    } else {
        Warn "npm not available -- cannot install project dependencies"
    }
}

# --- VS Code extensions -------------------------------------------

if (Get-Command code -ErrorAction SilentlyContinue) {
    Log "VS Code CLI found: $(code --version 2>$null | Select-Object -First 1)"
    Write-Host ""
    Info "Recommended extensions for this project:"
    Write-Host "    ESLint              (dbaeumer.vscode-eslint)"
    Write-Host "    Tailwind CSS        (bradlc.vscode-tailwindcss)"
    Write-Host "    Prettier            (esbenp.prettier-vscode)"
    Write-Host ""
    $installExt = Read-Host "    Install recommended VS Code extensions? (y/n)"
    if ($installExt -eq "y") {
        $installedExt = code --list-extensions 2>$null
        foreach ($ext in $VscodeExtensions) {
            if ($installedExt -contains $ext) {
                Log "Already installed: $ext"
            } else {
                Info "Installing: $ext"
                code --install-extension $ext --force 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Log "Installed: $ext"
                } else {
                    Warn "Failed to install $ext"
                }
            }
        }
        Log "VS Code extensions installed"
    } else {
        Info "Skipping. Install later:"
        foreach ($ext in $VscodeExtensions) {
            Write-Host "    code --install-extension $ext" -ForegroundColor White
        }
    }
} else {
    Info "VS Code 'code' command not in PATH -- skipping extension setup"
    Info "Open VS Code -> Ctrl+Shift+P -> 'Shell Command: Install code command in PATH'"
}

# --- Summary ------------------------------------------------------

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|  Setup Complete                      |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Agent Teams (Official Mechanism):"
Write-Host "    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  Enabled in settings"
Write-Host "    teammateMode: tmux                      Teammates auto-create split panes"
Write-Host "    .claude\settings.json                   Project-level settings"
Write-Host "    ~\.claude\settings.json                 User-level settings"
Write-Host "    .claude\agents\              $($ExpectedAgents.Count) agents: $($ExpectedAgents -join ', ')"
Write-Host ""
Write-Host "  Commands:"
Write-Host "    .claude\commands\            $($ExpectedCommands.Count) commands: $($ExpectedCommands -join ', ')"
Write-Host ""
Write-Host "  Dev Environment:"
Write-Host "    Git + Node.js + npm          Foundation tools"
Write-Host "    node_modules\                Project dependencies"
if (Get-Command code -ErrorAction SilentlyContinue) {
Write-Host "    VS Code extensions:          ESLint, Tailwind CSS, Prettier"
}
Write-Host ""
Write-Host "  Quick commands (added to PowerShell profile):"
Write-Host "    pp                           Launch Claude session"
Write-Host "    pp-setup                     Re-run setup for this project"
Write-Host ""
Write-Host "  Inside Claude:"
Write-Host "    /prime                       Prime the session with codebase context"
Write-Host "    /build-with-agent-team       Spawn agent team"
Write-Host "    /research <topic>            Spawn research agent"
Write-Host "    /deploy                      Commit, push, snapshot"
Write-Host ""

Log "Launching Claude session..."
Write-Host ""
& "$ProjectDir\scripts\start.ps1"
