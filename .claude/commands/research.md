---
description: Spawn a researcher agent to analyze best practices, patterns, or trade-offs
allowed-tools: Bash, Read, Write, Glob, Grep
---

# /research — Research Agent

Spawn a researcher agent that produces an actionable report. The agent writes
findings to `.claude/research/`.

## Arguments

`/research <topic or question>`

If no arguments provided, infer the research topic from the current conversation context.

## Procedure

### 1) Gather prior research context

Scan `.claude/research/` for existing reports. For each, read the first 10 lines
(title + summary) to check relevance. Include relevant prior research as context
so the agent builds on previous findings instead of starting from scratch.

### 2) Spawn the researcher

Use the **Agent** tool (subagent) — NOT manual tmux panes:

- `name`: "researcher"
- `run_in_background`: true
- `prompt`: Include project context (from CLAUDE.md in system context),
  prior research summaries, and the research task.
  The agent must write its report to `.claude/research/<topic-slug>.md`.

### 3) Report

Tell the user:
- Topic being researched
- Output file path
- The agent is running in background and will notify when done

## Notes

- The researcher is READ-ONLY for project source files
- Writes ONLY to `.claude/research/`
- Previous research is reused as context, not duplicated
- Agent definition: `.claude/agents/researcher.md`
