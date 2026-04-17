---
description: Spawn a researcher agent to analyze best practices, patterns, or trade-offs
allowed-tools: Bash, Read, Write, Glob, Grep
---

# /research — Research Agent

Spawn a researcher agent that produces an actionable report. The agent writes findings to `research/` at the repo root. **Never** writes to `.claude/` (protected path — triggers hardcoded safeguard and crashes teammate panes).

## Arguments
`/research <topic or question>`

If no arguments provided, infer the research topic from the current conversation context.

## Procedure

### 1) Gather prior research context
Scan `research/` (repo root) for existing reports. For each, read the first 10 lines. Include relevant prior research as context.

### 2) Spawn the researcher
Use the **Agent** tool — NOT manual tmux panes:
- `name`: "researcher"
- `run_in_background`: true
- `prompt`: Include project context (CLAUDE.md/AGENTS.md), prior research summaries, the task.
  Agent MUST write to `research/<topic-slug>.md` (repo root, NOT `.claude/research/`).
  Include the BLANKET PERMISSION block from AGENTS.md / `.claude/PROMPT_FREE_PROTOCOL.md`.

### 3) Report
- Topic, output file path, background status

## Notes
- Researcher is READ-ONLY for project source files
- Writes ONLY to `research/` at repo root
- Agent def: `.claude/agents/researcher.md`
- Protocol: `AGENTS.md` (canonical) + `.claude/PROMPT_FREE_PROTOCOL.md` (mirror)
