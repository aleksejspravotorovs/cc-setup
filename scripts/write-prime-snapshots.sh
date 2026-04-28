#!/usr/bin/env bash
# write-prime-snapshots.sh
# Writes Projects/<slug>-state.md for every active project — the file the
# `/prime` command in this vault looks for (matched via frontmatter
# `local_path: <cwd>` to identify the previous-session context).
#
# Reuses the same project-iteration logic and skip rules as
# scripts/propagate-frontend-policy.sh:
#   - Top-level Projects/*.md only
#   - Skip _*, README*, archived (status: archived)
#   - Skip empty/missing local_path
#   - Skip if local_path directory doesn't exist
#
# Idempotency: if Projects/<slug>-state.md already exists with
# `session: frontend-skill-policy` AND `last_updated:` matches today, skip.
# Otherwise, write/replace.
#
# Usage:
#   ./scripts/write-prime-snapshots.sh --dry-run --verbose
#   ./scripts/write-prime-snapshots.sh --only novashop
#   ./scripts/write-prime-snapshots.sh                       # writes for real
#
# Compatible with bash 3.2 (macOS system bash).

set -euo pipefail

VAULT="/Users/aleksejpravotorov/Desktop/My AI Knowledge Base"
PROJECTS_DIR="$VAULT/Projects"
SESSION_TAG="frontend-skill-policy"
TODAY="$(date '+%Y-%m-%d')"

DRY_RUN=0
VERBOSE=0
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --only)
      shift
      ONLY="${1:-}"
      if [ -z "$ONLY" ]; then
        echo "ERROR: --only requires a slug argument" >&2
        exit 2
      fi
      ;;
    -h|--help)
      /usr/bin/sed -n '2,/^$/p' "$0" | /usr/bin/sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ERROR: unknown flag: $1" >&2
      exit 2
      ;;
  esac
  shift
done

log() {
  if [ "$VERBOSE" = "1" ]; then echo "$*" >&2; fi
}

COUNT_WRITTEN=0
COUNT_NOOP=0
COUNT_SKIP=0
ERRORS=0
MATCHED_ONLY=0

if [ -n "$ONLY" ]; then
  if [ ! -f "$PROJECTS_DIR/$ONLY.md" ]; then
    echo "ERROR: --only slug '$ONLY' did not match any project note in $PROJECTS_DIR" >&2
    exit 1
  fi
fi

# Same frontmatter extractor as propagate-frontend-policy.sh.
get_frontmatter_value() {
  local file="$1" key="$2"
  /usr/bin/awk -v k="$key" '
    BEGIN { in_fm = 0 }
    NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/ { exit }
    in_fm {
      if (match($0, "^[[:space:]]*" k "[[:space:]]*:[[:space:]]*")) {
        v = substr($0, RLENGTH + 1)
        sub(/[[:space:]]+$/, "", v)
        if (v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2) }
        else if (v ~ /^\x27.*\x27$/) { v = substr(v, 2, length(v) - 2) }
        print v
        exit
      }
    }
  ' "$file"
}

render_state_file() {
  local slug="$1" local_path="$2"
  cat <<HEAD
---
type: project-state
slug: $slug
local_path: $local_path
last_updated: $TODAY
session: $SESSION_TAG
---

HEAD
  cat <<'BODY'
# Last session — Frontend Skill Policy rollout (2026-04-28)

## What changed
- SPSS (Single Primary Style Skill) policy is now active for this project. Canonical: `/Users/aleksejpravotorov/Desktop/My AI Knowledge Base/FRONTEND_SKILL_POLICY.md`.
- Project's `CLAUDE.md` has a managed block between `<!-- BEGIN: FRONTEND_SKILL_POLICY -->` markers — reference, do not edit between markers.

## Active baseline
- shadcn/ui + Tailwind. All effect/animation skills DORMANT until explicitly invoked.

## Dormant lane (require explicit trigger)
- `/svg-animations`, `/algorithmic-art`, `/scroll-animations`, `/framer-motion`, `/gsap`, `/three.js`
- Or natural-language: "add scroll animation", "use GSAP", "premium design system palette", etc. (see policy §4a strong signals)

## Z-index contract (cheat sheet)
- Decorative bg: `z ≤ 0` + `pointer-events:none` (full-viewport decorative MUST have both)
- Chrome: `1-9` OR `z-50` for sticky app frame (canonical `<header className="sticky top-0 z-50">` allowed)
- Content: `10-19`
- Functional overlays (Radix Dialog/Sheet/AlertDialog, vaul Drawer, cmdk): platform default `z-50` with `pointer-events:auto` — exempt from decorative rule

## Skills outside policy scope
- `json-render`, `knowledge-update`, session reminders, functional auto-fire co-load (nextjs + next-cache-components + react-best-practices + agent-browser-verify) — cannot be suppressed; mitigate by keeping styling minimal.

## Verification
Before marking visual work complete, walk the project through `qa/visible-content-checklist.md` (5 yes/no checks) at vault root.

## Next session
Pick up project work normally. The policy auto-loads via this state file + the managed CLAUDE.md block.
BODY
}

process_project() {
  local note="$1"
  local base="${note##*/}"
  base="${base%.md}"

  case "$base" in
    _*|README|readme|Readme) log "skip: $base (system file)"; COUNT_SKIP=$((COUNT_SKIP + 1)); return 0 ;;
  esac

  # Don't write a state file for an existing state file (avoid recursion if
  # someone runs this twice without cleanup).
  case "$base" in
    *-state) log "skip: $base (already a state file)"; COUNT_SKIP=$((COUNT_SKIP + 1)); return 0 ;;
  esac

  if [ -n "$ONLY" ] && [ "$base" != "$ONLY" ]; then
    return 0
  fi

  local status local_path
  status=$(get_frontmatter_value "$note" "status")
  local_path=$(get_frontmatter_value "$note" "local_path")

  if [ "$status" = "archived" ]; then
    log "skip: $base (status=archived)"
    COUNT_SKIP=$((COUNT_SKIP + 1))
    return 0
  fi
  if [ -z "$local_path" ]; then
    log "skip: $base (no local_path in frontmatter)"
    COUNT_SKIP=$((COUNT_SKIP + 1))
    return 0
  fi
  if [ ! -d "$local_path" ]; then
    log "skip: $base (local_path does not exist: $local_path)"
    COUNT_SKIP=$((COUNT_SKIP + 1))
    return 0
  fi

  if [ -n "$ONLY" ]; then MATCHED_ONLY=1; fi

  local state_file="$PROJECTS_DIR/$base-state.md"

  # Idempotency: skip if existing file already has today's session tag + date.
  if [ -f "$state_file" ]; then
    local existing_session existing_updated
    existing_session=$(get_frontmatter_value "$state_file" "session")
    existing_updated=$(get_frontmatter_value "$state_file" "last_updated")
    if [ "$existing_session" = "$SESSION_TAG" ] && [ "$existing_updated" = "$TODAY" ]; then
      log "noop: $state_file (already current)"
      COUNT_NOOP=$((COUNT_NOOP + 1))
      return 0
    fi
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ -f "$state_file" ]; then
      log "DRY: would replace $state_file"
    else
      log "DRY: would create $state_file"
    fi
    COUNT_WRITTEN=$((COUNT_WRITTEN + 1))
    return 0
  fi

  local tmp
  tmp=$(/usr/bin/mktemp -t prime-state.XXXXXX)
  render_state_file "$base" "$local_path" > "$tmp"

  local new_size
  new_size=$(/usr/bin/wc -c < "$tmp" | /usr/bin/tr -d ' ')
  if [ "$new_size" -le 0 ]; then
    echo "ERROR: refusing to write empty state file for $base" >&2
    /bin/rm -f "$tmp"
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  /bin/mv "$tmp" "$state_file"
  log "WRITE: $state_file"
  COUNT_WRITTEN=$((COUNT_WRITTEN + 1))
}

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "ERROR: Projects dir not found: $PROJECTS_DIR" >&2
  exit 2
fi

shopt -s nullglob
for note in "$PROJECTS_DIR"/*.md; do
  [ -f "$note" ] || continue
  process_project "$note"
done
shopt -u nullglob

if [ -n "$ONLY" ] && [ "$MATCHED_ONLY" -eq 0 ]; then
  echo "ERROR: --only slug '$ONLY' matched a note but the project was filtered out" >&2
  exit 1
fi

MODE="LIVE"
[ "$DRY_RUN" = "1" ] && MODE="DRY-RUN"
echo ""
echo "[$MODE] States written: $COUNT_WRITTEN | NoOp: $COUNT_NOOP | Skipped: $COUNT_SKIP | Errors: $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
exit 0
