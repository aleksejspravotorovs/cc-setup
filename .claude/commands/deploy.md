---
description: Commit, deploy, verify, and snapshot session state for next prime
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /deploy — Commit & Deploy

## 1) Pre-flight (parallel)

Run all at once:
- `git status` — uncommitted changes?
- `git remote -v` — remote configured?
- `git branch --show-current` — current branch?
- Glob `.vercel/project.json` OR `netlify.toml` — hosting connected?
**If no remote**: STOP — "No git remote."
**If no changes**: Ask — "Working tree clean. Force deploy? (y/n)"

## 2) Build gate

```bash
npm run build
```

**If build fails**: STOP. Show error. Do NOT commit broken code.

## 3) Lint gate (if script exists)

```bash
npm run lint 2>&1 || true
```

Report warnings but don't block. Only block on errors.

## 4) Commit

Analyze changes with `git diff --stat` and `git status`.

Stage changed files (specific files, NOT `git add -A`):
- Stage source code changes
- Stage `.claude/commands/` if modified
- Stage `CLAUDE.md` if modified
- Do NOT stage `.env*`, credentials

Conventional commit message:
- Format: `type(scope): description`
- Types: feat, fix, chore, refactor, style, docs
- Keep subject under 72 chars

## 5) Push

```bash
git push origin <current-branch>
```

## 6) Session snapshot (for next /prime)

Create/overwrite `.claude/snapshots/last-deploy.md` **via Bash heredoc** (the path is protected — see `.claude/PROMPT_FREE_PROTOCOL.md`, Rule 1):

```markdown
# Last Deploy Snapshot
Generated: [ISO timestamp]
Branch: [branch]
Commit: [short hash] [commit message]

## Changes deployed
[git diff --stat output]

## Build status
[pass/fail + any warnings]

## Context for next /prime
- Key files changed: [list]
- New components added: [list, if any]
- New routes added: [list, if any]
- Breaking changes: [none / description]
- Follow-up needed: [none / description]
```

## 7) Output report

```
Deploy Complete
═══════════════
Commit:   [hash] [message]
Branch:   [branch] → origin/[branch]
Build:    [pass/fail]
Snapshot: .claude/snapshots/last-deploy.md

Next prime will auto-load this snapshot for context.
```
