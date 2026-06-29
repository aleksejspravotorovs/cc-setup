# Agent Team Orchestration (Official Agent Teams)

## MANDATORY — read before spawning teammates
`.claude/PROMPT_FREE_PROTOCOL.md`. Every `Agent(...)` prompt you build MUST include the BLANKET PERMISSION block from the protocol. Hard rules:
- Teammates MUST NOT use `Write`/`Edit` on paths under `.claude/**` or `.git/**` — use `Bash` heredoc
- Teammate artifacts live at repo root (`findings.md`, `research/`, `strategies/`, `qa/`, `web/`) — NOT `.claude/`
- Teammates NEVER ask the user questions — pre-authorized blanket permission


Agent teams coordinate multiple Claude Code instances working together. One session acts as the
team lead, coordinating work, assigning tasks, and synthesizing results. Teammates work
independently, each in its own context window, and communicate directly with each other.

Unlike subagents (which run within a single session and only report back), you can interact
with individual teammates directly without going through the lead.

## Prerequisites

- Claude Code v2.1.32 or later (`claude --version`)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json or environment
- `teammateMode` set in settings.json (see Display modes below)

## Display modes

Agent teams support two display modes controlled by `teammateMode` in settings.json:

| Mode | Setting | How it works |
|------|---------|-------------|
| **In-process** | `"in-process"` | All teammates run inside your main terminal. Shift+Down cycles through teammates. Works in any terminal. |
| **Split panes** | `"tmux"` | Each teammate gets its own pane. Click into a pane to interact directly. Requires tmux or iTerm2. |
| **Auto** (default) | `"auto"` | Uses split panes if running inside tmux, in-process otherwise. |

Split-pane mode requires tmux or iTerm2 with the `it2` CLI.

## Agent roster

Agent definitions live in `.claude/agents/*.md`:
- **lead** — Contract owner + orchestrator (you)
- **frontend** — UI + client logic
- **backend** — API + database + server logic
- **devops** — Infrastructure + deployment
- **skeptic** — Security + UX devil's advocate (review-only, no code). **Must update `findings.md` (repo root)** after every review.
- **qa** — Structured pass/fail verification + regression checks
- **researcher** — Technical research and best practices analysis (read-only)

## Unknown agents

If the task references an agent name NOT in `.claude/agents/`:
1. Infer the agent's role from the task context
2. If unclear, **STOP and ask the user** what the agent does
3. Create `.claude/agents/<name>.md` with the role definition before proceeding

## Workflow

### Phase 0: Contract (Lead only)
1. Analyze the task
2. Produce a SHARED EXECUTION CONTRACT:
   - Scope (what's in, what's out)
   - File ownership per agent (non-overlapping — avoid file conflicts)
   - Acceptance criteria
   - Merge order
3. Create team and spawn teammates

### Phase 1: Spawn team (official mechanism — MANDATORY)

**Use ONLY the official Agent Teams tools:**

1. **`TeamCreate`** — create the team with a descriptive name
2. **`TaskCreate`** — create tasks with descriptions, acceptance criteria, and dependencies (`addBlockedBy`)
   - Aim for 5-6 tasks per teammate
   - Tasks have three states: pending, in progress, completed
   - Tasks with unresolved dependencies cannot be claimed until dependencies complete
3. **`Agent`** tool with `team_name` and `name` params — spawn each teammate with:
   - `team_name`: the team name from step 1
   - `name`: agent name (e.g., "frontend", "backend", "skeptic", "qa")
   - `mode`: "bypassPermissions" (inherits lead's permissions)
   - `run_in_background`: true (teammates work asynchronously)
   - `prompt`: full task context — teammates do NOT inherit lead's conversation history. Include all relevant context in the prompt.
4. Teammates appear as **split panes automatically** in tmux — no manual pane management needed

**Team size**: Start with 3-5 teammates. Three focused teammates often outperform five scattered ones. Scale up only when work genuinely benefits from parallelism.

**Anti-patterns (DO NOT DO):**
- Manually creating tmux panes with `tmux split-window`
- Running `claude --dangerously-skip-permissions` via `tmux send-keys`
- Using `cat prompt.md | claude` pipe patterns
- Any manual tmux pane management for agents

**After spawning:** Stay quiet. Teammates send messages automatically when done. Only speak when there's a blocker or all agents finish.

### Phase 2: Coordination
- Teammates claim tasks via `TaskUpdate` and mark them completed when done
- Task claiming uses file locking to prevent race conditions
- Use `TaskUpdate` with `addBlockedBy` to set dependencies (e.g., QA blocked by implementation tasks)
- When a teammate completes a task, blocked tasks unblock automatically
- Teammates communicate via `SendMessage` — messages are delivered automatically
  - `message`: send to one specific teammate
  - `broadcast`: send to all teammates (use sparingly — costs scale with team size)
- Lead reviews outputs against contract when teammates report back

**If the lead starts implementing tasks itself instead of waiting:**
Tell it: "Wait for your teammates to complete their tasks before proceeding."

### Phase 3: Fix Cycle (MANDATORY when skeptic/QA find issues)

When skeptic or QA report findings (HIGH or MEDIUM severity):

1. **Lead MUST NOT fix bugs directly** — lead is coordination only
2. **Create fix tasks** with clear descriptions referencing the findings
3. **Spawn the relevant agent(s)** (frontend, backend, etc.) to implement fixes
4. **After fixes land**, re-run skeptic + QA:
   - Create new review/verification tasks blocked by the fix tasks
   - Spawn fresh skeptic + QA agents to re-verify
5. **Repeat** until skeptic + QA report clean (no HIGH/MEDIUM findings)

**Anti-patterns (DO NOT DO):**
- Lead editing implementation files to fix bugs found by reviewers
- Skipping re-verification after fixes
- Marking findings resolved without agent-verified fixes

### Phase 4: Cleanup (see AGENTS.md "Shut down completed teammates")
1. The moment a teammate's deliverable is verified, send it a shutdown request
   (SendMessage / "ask <name> to shut down"). Only the lead originates shutdowns.
2. The teammate must APPROVE the request - approval is what ends the process; a
   prose "ok" does NOT terminate it. If it is mid tool-call, shutdown finishes
   that call first - wait.
3. VERIFY each pane/process is actually gone (task list no longer shows it). If a
   pane orphans (Claude Code #29787), force-kill the teammate pane via
   `tmux kill-pane` (never the lead pane), or run `scripts/stop.sh` to tear down
   the whole session.
4. Full teardown at session end = exit the lead session (`/exit`), which
   auto-terminates remaining teammates. `scripts/stop.sh` is the hard fallback.
5. Update `findings.md` (repo root) with resolved items.
## Plan approval mode

For complex or risky tasks, require teammates to plan before implementing:
- Teammate works in read-only plan mode until the lead approves their approach
- Lead reviews and either approves or rejects with feedback
- Give the lead approval criteria: "only approve plans that include test coverage"

## Findings automation
- **Skeptic** must update `findings.md` (repo root) after every review:
  - Add new findings under the appropriate section and severity heading
  - Mark resolved items with ~~strikethrough~~ and commit context
- **Lead** marks findings resolved when fixes are verified and merged

## Rules
- Agents MUST NOT edit files outside their contracted scope
- **Lead MUST NOT implement code, fix bugs, or write patches** — only contract, coordination, task creation, agent spawning, and verification orchestration
- When reviewers find bugs: create tasks -> spawn agents -> re-verify. Never self-fix.
- `npm run build` must pass after all changes
- If an agent starts doing another agent's job, STOP and redirect

## Navigation

| Action | In-process mode | Split-pane mode |
|--------|----------------|-----------------|
| Cycle teammates | Shift+Down | Click pane |
| View teammate session | Enter | Click pane |
| Interrupt teammate | Escape | Click pane, then Escape |
| Toggle task list | Ctrl+T | Ctrl+T |
| Navigate panes | — | Alt + Arrow keys |
| Zoom pane | — | Prefix + z |

## Launch
If not already in tmux, user should start with: `./scripts/start.sh`
