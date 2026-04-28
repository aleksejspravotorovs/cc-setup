#!/usr/bin/env bash
# propagate-frontend-policy.sh
# Idempotently inject a FRONTEND_SKILL_POLICY reference block into the CLAUDE.md
# of every active project tracked in the Obsidian vault's Projects/<slug>.md notes.
#
# Reads `local_path:` from each project note's frontmatter, then writes a sentinel-
# bracketed block into the CLAUDE.md at that path. Re-running replaces (never
# duplicates) the block. Existing CLAUDE.md content outside the markers is preserved.
#
# Usage:
#   ./scripts/propagate-frontend-policy.sh --dry-run --verbose
#   ./scripts/propagate-frontend-policy.sh --only novashop
#   ./scripts/propagate-frontend-policy.sh                   # writes for real
#
# Skip rules:
#   - Files in Projects/_archived/ or starting with `_`
#   - frontmatter status: archived
#   - missing/empty local_path
#   - local_path directory doesn't exist
#
# Safety guards:
#   - Symlinked CLAUDE.md is REFUSED with an error (would silently break shared-link
#     semantics). Resolve manually if shared-link behavior is intended.
#   - REPLACE path requires both BEGIN and END markers present; truncated/mangled
#     end-marker triggers an error and the file is left untouched.
#   - REPLACE path verifies the rewritten file is non-empty AND ≥50% of original
#     size before atomic mv. Catches awk crashes, partial writes, etc.
#   - When overwriting a customized in-marker block (markers exist but content
#     differs from canonical), a WARN is printed to stderr with the file path.
#
# Compatible with bash 3.2 (macOS system bash).

set -euo pipefail

VAULT="/Users/aleksejpravotorov/Desktop/My AI Knowledge Base"
PROJECTS_DIR="$VAULT/Projects"
POLICY_DOC="$VAULT/FRONTEND_SKILL_POLICY.md"

BEGIN_MARKER='<!-- BEGIN: FRONTEND_SKILL_POLICY (managed by propagate-frontend-policy.sh — do not edit between markers) -->'
END_MARKER='<!-- END: FRONTEND_SKILL_POLICY -->'

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

# Counters
COUNT_UPDATED=0
COUNT_CREATED=0
COUNT_REPLACED=0  # markers already existed, content replaced
COUNT_APPENDED=0  # markers absent, block appended
COUNT_NOOP=0      # block already present and identical
COUNT_SKIP=0
ERRORS=0
MATCHED_ONLY=0    # tracks whether --only filter ever found a non-skipped project

# --only validation: if a slug was passed, the corresponding project note MUST
# exist before we even start iterating. Caught here, not silently after the loop.
if [ -n "$ONLY" ]; then
  if [ ! -f "$PROJECTS_DIR/$ONLY.md" ]; then
    echo "ERROR: --only slug '$ONLY' did not match any project note in $PROJECTS_DIR" >&2
    exit 1
  fi
fi

# The block we'll write between (and including) the sentinel markers.
# Body content is the verbatim Section 8 boilerplate from
# FRONTEND_SKILL_POLICY.md — frontend owns this text; do not paraphrase here.
# Quoted heredoc ('BLOCK') prevents shell from interpreting backticks/dollars.
render_block() {
  cat <<'BLOCK'
<!-- BEGIN: FRONTEND_SKILL_POLICY (managed by propagate-frontend-policy.sh — do not edit between markers) -->
## Frontend Skill Policy (SPSS)

**Active baseline:** shadcn/ui + Tailwind. Use shadcn theme tokens
(`bg-background`, `text-foreground`, `border-border`, `bg-primary`) — never
inline hex into globals.css, tailwind config, or className strings.

**Dormant by default** — activate only via slash command or explicit keyword:
- `/svg-animations`, `/algorithmic-art`, `/scroll-animations`,
  `/framer-motion`, `/gsap`, `/three`
- `/design-bold`, `/scroll-video`, `/section-transitions`,
  `/premium-palette`

**No auto-mix:** invoking one effect skill does NOT activate siblings.

**Z-index contract:** bg ≤ 0 (full-viewport, pointer-events:none required),
chrome 1–9, content 10–19, overlays 20–49, toasts/Radix-portals 50+.
Sticky scroll scenes never exceed 19.

**Conflict resolution:** most-recent invocation wins layout/animation;
earliest invocation (the SPSS baseline) wins color/typography.

**Before claiming a UI task done:** run
`qa/visible-content-checklist.md` — all 5 checks must pass.

Full policy: see `FRONTEND_SKILL_POLICY.md` at the vault root.
<!-- END: FRONTEND_SKILL_POLICY -->
BLOCK
}

# Extract a frontmatter scalar from a markdown file. Frontmatter is the first
# block delimited by `---` lines at the very top of the file.
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

# Result of the last upsert_block call: "replaced" or "appended" (empty on error).
# Avoids using `if upsert_block; then ... fi` which masks set -e and lets awk
# crashes silently truncate target files.
UPSERT_RESULT=""

# Replace marked block in $1 (target) with $2 (block content), OR append if no
# markers. On any internal failure (awk crash, size sanity, missing END marker),
# returns non-zero and leaves the target file UNTOUCHED. Callers MUST inspect
# the return code; do NOT chain via `if`.
upsert_block() {
  local target="$1"
  local block_content="$2"
  UPSERT_RESULT=""
  local tmp blockfile awk_rc orig_size new_size half_orig

  # Symlink guard: replacing via `mv tmp target` would unlink the symlink and
  # write a regular file in its place, breaking shared-link semantics.
  if [ -L "$target" ]; then
    echo "ERROR: $target is a symlink — refusing to rewrite (would break shared-link semantics). Resolve manually." >&2
    return 5
  fi

  if /usr/bin/grep -qF "$BEGIN_MARKER" "$target" 2>/dev/null; then
    # END-marker integrity guard: a BEGIN without an END would cause the awk
    # loop to drop every line after BEGIN. Refuse rather than silently truncate.
    if ! /usr/bin/grep -qF "$END_MARKER" "$target" 2>/dev/null; then
      echo "ERROR: $target has BEGIN marker but missing END marker — refusing to rewrite (manual review required)" >&2
      return 6
    fi

    # HIGH#1 fix: BSD awk on macOS rejects multi-line `-v repl=...`. Pass the
    # block through a tempfile and read it via getline in BEGIN. Single-pass,
    # deterministic, no shell quoting hazards.
    blockfile=$(/usr/bin/mktemp -t propagate-block.XXXXXX)
    printf '%s\n' "$block_content" > "$blockfile"
    tmp=$(/usr/bin/mktemp -t propagate-target.XXXXXX)

    # Run awk with errexit temporarily off so we can capture rc explicitly.
    set +e
    /usr/bin/awk \
      -v BLOCK_FILE="$blockfile" \
      -v begin="$BEGIN_MARKER" \
      -v end="$END_MARKER" \
      '
        BEGIN {
          block = ""
          while ((getline line < BLOCK_FILE) > 0) {
            block = block (block == "" ? "" : "\n") line
          }
          close(BLOCK_FILE)
          skipping = 0; printed = 0
        }
        index($0, begin) > 0 {
          if (!printed) { print block; printed = 1 }
          skipping = 1
          next
        }
        skipping && index($0, end) > 0 {
          skipping = 0
          next
        }
        skipping { next }
        { print }
      ' "$target" > "$tmp"
    awk_rc=$?
    set -e

    /bin/rm -f "$blockfile"

    if [ "$awk_rc" -ne 0 ]; then
      echo "ERROR: awk REPLACE failed (rc=$awk_rc) on $target — leaving file untouched" >&2
      /bin/rm -f "$tmp"
      return 2
    fi

    # Size sanity: catastrophic shrink (>50% of original) almost always means
    # the rewrite step failed silently. Refuse to commit such a write.
    orig_size=$(/usr/bin/wc -c < "$target" | /usr/bin/tr -d ' ')
    new_size=$(/usr/bin/wc -c < "$tmp" | /usr/bin/tr -d ' ')
    if [ "$new_size" -le 0 ]; then
      echo "ERROR: refusing empty replacement of $target (orig=$orig_size, new=$new_size)" >&2
      /bin/rm -f "$tmp"
      return 3
    fi
    half_orig=$((orig_size / 2))
    if [ "$orig_size" -gt 0 ] && [ "$new_size" -lt "$half_orig" ]; then
      echo "ERROR: replacement of $target shrank from $orig_size to $new_size bytes (>50% loss) — refusing" >&2
      /bin/rm -f "$tmp"
      return 4
    fi

    /bin/mv "$tmp" "$target"
    UPSERT_RESULT="replaced"
    return 0
  else
    # APPEND path — no markers. Copy + ensure trailing blank line + write block.
    tmp=$(/usr/bin/mktemp -t propagate-target.XXXXXX)
    /bin/cp "$target" "$tmp"
    if [ -s "$tmp" ]; then
      if [ -n "$(/usr/bin/tail -c 1 "$tmp")" ]; then
        printf '\n' >> "$tmp"
      fi
      printf '\n' >> "$tmp"
    fi
    printf '%s\n' "$block_content" >> "$tmp"

    new_size=$(/usr/bin/wc -c < "$tmp" | /usr/bin/tr -d ' ')
    if [ "$new_size" -le 0 ]; then
      echo "ERROR: refusing empty append result for $target" >&2
      /bin/rm -f "$tmp"
      return 3
    fi

    /bin/mv "$tmp" "$target"
    UPSERT_RESULT="appended"
    return 0
  fi
}

process_project() {
  local note="$1"
  local base="${note##*/}"
  base="${base%.md}"

  # Skip underscore-prefixed, README-style notes, and *-state.md (per-project
  # prime snapshots written by scripts/write-prime-snapshots.sh — these are not
  # project notes and have no own local_path semantics for propagation).
  case "$base" in
    _*|README|readme|Readme) log "skip: $base (system file)"; COUNT_SKIP=$((COUNT_SKIP + 1)); return 0 ;;
    *-state) log "skip: $base (prime snapshot, not a project note)"; COUNT_SKIP=$((COUNT_SKIP + 1)); return 0 ;;
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

  # If we got this far, --only matched a real, processable project.
  if [ -n "$ONLY" ]; then MATCHED_ONLY=1; fi

  local target="$local_path/CLAUDE.md"
  local block_content
  block_content=$(render_block)

  if [ ! -f "$target" ]; then
    if [ -L "$target" ]; then
      echo "ERROR: $target is a broken symlink — refusing to create a regular file in its place" >&2
      ERRORS=$((ERRORS + 1))
      return 0
    fi
    if [ "$DRY_RUN" = "1" ]; then
      log "DRY: would create $target"
      COUNT_CREATED=$((COUNT_CREATED + 1))
      COUNT_UPDATED=$((COUNT_UPDATED + 1))
      return 0
    fi
    if ! /usr/bin/touch "$target" 2>/dev/null; then
      echo "ERROR: cannot create $target (permission denied?)" >&2
      ERRORS=$((ERRORS + 1))
      return 0
    fi
    {
      printf '# %s\n\n' "$base"
      printf '%s\n' "$block_content"
    } > "$target"
    log "CREATE: $target"
    COUNT_CREATED=$((COUNT_CREATED + 1))
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
    return 0
  fi

  # CLAUDE.md exists — check whether the block is already present and identical.
  local has_marker existing_block matches=0
  has_marker=0
  if /usr/bin/grep -qF "$BEGIN_MARKER" "$target" 2>/dev/null; then
    has_marker=1
    existing_block=$(/usr/bin/awk \
      -v begin="$BEGIN_MARKER" \
      -v end="$END_MARKER" \
      '
        index($0, begin) > 0 { capturing = 1 }
        capturing { print }
        capturing && index($0, end) > 0 { exit }
      ' "$target")
    if [ "$existing_block" = "$block_content" ]; then
      matches=1
    fi
  fi

  if [ "$matches" = "1" ]; then
    log "ok:    $target (block already up-to-date)"
    COUNT_NOOP=$((COUNT_NOOP + 1))
    return 0
  fi

  # If markers exist but content differs, the user may have customized it.
  # Warn unconditionally (dry-run + live) so the operator knows before commit.
  if [ "$has_marker" = "1" ]; then
    echo "WARN: replacing customized in-marker block in $target" >&2
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ "$has_marker" = "1" ]; then
      log "DRY: would replace block in $target"
      COUNT_REPLACED=$((COUNT_REPLACED + 1))
    else
      log "DRY: would append block to $target"
      COUNT_APPENDED=$((COUNT_APPENDED + 1))
    fi
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
    return 0
  fi

  if [ ! -w "$target" ]; then
    echo "ERROR: $target is not writable" >&2
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  # Explicit rc capture — never use `if upsert_block; then`, which masks set -e
  # and lets internal awk crashes turn into silent file destruction.
  local upsert_rc=0
  upsert_block "$target" "$block_content" || upsert_rc=$?
  if [ "$upsert_rc" -ne 0 ]; then
    echo "ERROR: upsert failed for $target (rc=$upsert_rc)" >&2
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  case "$UPSERT_RESULT" in
    replaced)
      log "REPLACE: $target"
      COUNT_REPLACED=$((COUNT_REPLACED + 1))
      ;;
    appended)
      log "APPEND:  $target"
      COUNT_APPENDED=$((COUNT_APPENDED + 1))
      ;;
    *)
      echo "ERROR: upsert returned unexpected result '$UPSERT_RESULT' for $target" >&2
      ERRORS=$((ERRORS + 1))
      return 0
      ;;
  esac
  COUNT_UPDATED=$((COUNT_UPDATED + 1))
}

# Sanity check: vault and Projects dir exist
if [ ! -d "$PROJECTS_DIR" ]; then
  echo "ERROR: Projects dir not found: $PROJECTS_DIR" >&2
  exit 2
fi

# Warn (non-fatal) if the canonical policy doc isn't in place yet
if [ ! -f "$POLICY_DOC" ]; then
  echo "WARN: canonical policy doc not found at $POLICY_DOC (block will still reference it)" >&2
fi

# Iterate top-level Projects/*.md only — never recurse into _archived/
shopt -s nullglob
for note in "$PROJECTS_DIR"/*.md; do
  [ -f "$note" ] || continue
  process_project "$note"
done
shopt -u nullglob

# --only sanity: file existed (we checked at startup) but the project was
# skipped (archived / missing local_path / missing dir). Surface that loudly.
if [ -n "$ONLY" ] && [ "$MATCHED_ONLY" -eq 0 ]; then
  echo "ERROR: --only slug '$ONLY' matched a note but the project was filtered out (status=archived, missing local_path, or local dir not present)" >&2
  exit 1
fi

# Final summary
MODE="LIVE"
[ "$DRY_RUN" = "1" ] && MODE="DRY-RUN"
echo ""
echo "[$MODE] Updated: $COUNT_UPDATED (created: $COUNT_CREATED, replaced: $COUNT_REPLACED, appended: $COUNT_APPENDED) | NoOp: $COUNT_NOOP | Skipped: $COUNT_SKIP | Errors: $ERRORS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
exit 0
