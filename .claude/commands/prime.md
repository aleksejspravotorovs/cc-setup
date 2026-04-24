---
description: Lean codebase prime — context load (Claude Code) + Obsidian vault context
allowed-tools: Read, Glob, Bash
---

# /prime — Lean Prime

Role: GSD Execution Partner (senior engineer + pragmatic PM). Ship smallest correct change. Be direct. Prevent scope creep.

## 1) Codebase prime (Glob-first, minimal reads)

CLAUDE.md is ALREADY in system context. Do NOT re-read it. Do NOT read style/token CSS files (conventions are documented in CLAUDE.md).

**Glob only** (structure scan, no file reads):
- `src/app/**/page.tsx` — route inventory
- `src/app/**/route.ts` — API endpoints
- `src/components/ui/*/index.ts` — UI-kit inventory
- `src/lib/**/*.ts` — utilities
- `src/components/**/index.ts` — feature components
- `.claude/agents/*.md` — agent roster
- `scripts/*.sh` — available scripts

**Read only these** (2-3 files max):
- `package.json` — scripts, deps, versions
- `.claude/snapshots/last-deploy.md` — previous session context (if exists)

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
Missing/unexpected: [anything notable]
```

## 2) MCP check (non-blocking)

Glob for `.mcp.json`. If found, note "MCP configured." If Figma work comes up later, user can verify Figma Desktop is running then. Do NOT block session on MCP verification.

## 3) Obsidian vault context pull (non-blocking)

Vault root default: `$HOME/Desktop/My AI Knowledge Base`. Override via `OBSIDIAN_VAULT` env var if installed elsewhere.

**Run exactly this Bash one-liner** (silent if vault missing / no match — never blocks):

```bash
VAULT="${OBSIDIAN_VAULT:-$HOME/Desktop/My AI Knowledge Base}"
CWD="$(pwd)"
[ -d "$VAULT/Projects" ] && grep -rl "local_path: $CWD$" "$VAULT/Projects" 2>/dev/null | head -1
```

If the command returns a path → Read that single note (it has frontmatter with status / last_synced / tags, plus sections: Links, Related projects, Skills, and optionally Status / Backlog / Recent activity).

Also run (once, non-blocking):

```bash
# Recent cross-project activity — last 3 entries from vault's global log, if exists
[ -f "$VAULT/wiki/meta/activity-log.md" ] && tail -30 "$VAULT/wiki/meta/activity-log.md" 2>/dev/null
```

**Append to prime report** one "Obsidian" block:
```
Obsidian: [project slug] · status=[active|archived|paused] · last_synced=[date]
Related: [[note1]], [[note2]]
Skills: React, Supabase, Vite, ...
```

If no match found → print `Obsidian: no matching note for $(pwd) — skip.` and move on.

**Do NOT**: write to the vault, trigger MCP calls, or block the prime report on vault I/O. If grep/read errors, continue silently.

## 4) Session template

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
- Agent teams use the **official Agent Teams** mechanism (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Display mode controlled by `teammateMode` in settings.json: `"tmux"` for split panes, `"in-process"` for single terminal, `"auto"` (default) auto-detects
- Launch with `./scripts/start.sh` (tmux: Claude left pane + git watch right pane)
- Agents are defined in `.claude/agents/*.md`: lead, frontend, backend, devops, skeptic, qa, researcher
- When `/build-with-agent-team` is invoked, Lead uses `TeamCreate` + `TaskCreate` + `Agent` tool to create the team and delegate
- Teammates spawn as split panes automatically in tmux — no manual pane management
- Navigation: Shift+Down cycles teammates (in-process), click pane (split-pane), Alt+Arrow to navigate panes
- Unknown agent names: infer role from task context → create `.claude/agents/<name>.md`, or ask user if unclear

## Iteration close
What changed · How to verify · Next action

## Session close
Done · Remaining · Next step · Risks
