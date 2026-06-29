---
description: Lean codebase prime — context load (Claude Code) + Obsidian vault context
allowed-tools: Read, Glob, Bash
---

# /prime — Lean Prime

Role: GSD Execution Partner (senior engineer + pragmatic PM). Ship smallest correct change. Be direct. Prevent scope creep.

## 1) Codebase prime (Glob-first, minimal reads)

CLAUDE.md is ALREADY in system context. Do NOT re-read it. Do NOT read style/token CSS files (conventions are documented in CLAUDE.md).

**Glob only** (structure scan, no file reads):
- `src/app/**/page.tsx`, `src/pages/*.tsx` — route inventory
- `src/app/**/route.ts`, `api/*.ts` — API endpoints
- `src/components/ui/*/index.ts`, `src/components/*.tsx` — UI inventory
- `src/lib/**/*.ts` — utilities
- `.claude/agents/*.md` — agent roster
- `scripts/*.sh` — available scripts

**Read only these** (compact sources only — keep prime under ~2k tokens):
- `package.json` — use `Read` with `limit: 50` (scripts + key deps only; skip lockfile-level detail).
- Previous-session context — see §2 fallback chain. **Do NOT read full `.claude/snapshots/last-deploy.md`** (grows unbounded; often >50KB on mature projects).

**Report** (compact, no duplication of CLAUDE.md):
```
Routes: [list from glob]
API: [list from glob]
UI-kit / components: [names from glob]
Lib: [utility files]
Agents: [names from .claude/agents/]
Scripts: [scripts/ + package.json scripts block]
Deps: [key deps from package.json]
Missing/unexpected: [anything notable]
```

## 2) Previous-session context (token-lean, ordered fallback)

**Source priority — use the FIRST source that exists, stop there:**

**A. Obsidian project-state file (preferred, authored by /deploy, ≤40 lines):**

```bash
VAULT="$HOME/Desktop/My AI Knowledge Base"
CWD="$(pwd)"
NOTE=$(grep -rl "local_path: $CWD$" "$VAULT/Projects" 2>/dev/null | head -1)
if [ -n "$NOTE" ]; then
  SLUG=$(basename "$NOTE" .md)
  STATE="$VAULT/Projects/${SLUG}-state.md"
  [ -f "$STATE" ] && echo "STATE_FILE=$STATE"
fi
```

If `STATE_FILE=...` printed → Read that file (compact by design). Done. Skip B.

**B. Fallback — LAST section of `.claude/snapshots/last-deploy.md`** (everything after the final `---` separator):

```bash
SNAP=".claude/snapshots/last-deploy.md"
[ -f "$SNAP" ] && awk 'BEGIN{buf=""} /^---$/{buf=""; next} {buf=buf $0 "\n"} END{printf "%s", buf}' "$SNAP"
```

Print the output inline — no Read call, no full-file load. Only the most-recent deploy entry is consumed.

**C. Neither present** → print `Previous session: no snapshot — fresh start.` and move on.

## 3) MCP check (non-blocking)

Glob for `.mcp.json`. If found, note "MCP configured." Do NOT verify MCP servers at prime time.

## 4) Obsidian project-note metadata (non-blocking)

`$NOTE` was resolved in §2A. If non-empty → Read that project note for frontmatter + "Related projects" + "Skills" sections only (skip "Vault knowledge" and "Notes").

**Append to prime report** one "Obsidian" block:
```
Obsidian: [slug] · status=[active|archived|paused] · last_synced=[date]
Related: [[note1]], [[note2]]
Skills: React, Supabase, Vite, ...
```

If `$NOTE` empty → print `Obsidian: no matching note for $(pwd) — skip.`

**Do NOT**: write to the vault, trigger MCP calls, tail the global activity-log, or block the prime report on vault I/O. If grep/read errors, continue silently.

## 5) Session template

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
