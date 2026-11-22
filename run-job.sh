#!/usr/bin/env bash
# Nightjar lite job runner. Runs one job prompt headless with Claude Code and logs it.
#   bash run-job.sh <job>                run a job now
#   JOB_DRYRUN=1 bash run-job.sh <job>   same, but every write goes to Digests/_dryrun/
#
# A job is two files in jobs/: <job>.md (the prompt) and <job>.conf (its tools, model, timeout).
# Every job also gets jobs/_rules.md in front of its prompt.
# Lite has no phone alerts and no scheduler: run it by hand, or point your own scheduler at it.

set -u
JOB="${1:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE" || exit 1
[ -n "$JOB" ] || { echo "usage: bash run-job.sh <job>"; exit 2; }
[ -f "config.sh" ] || { echo "config.sh missing: copy config.example.sh to config.sh and edit it"; exit 2; }
# Read config and job files with any Windows line endings stripped (a CRLF would break every value)
src() { source <(tr -d '\r' < "$1"); }
src ./config.sh
[ -f "jobs/$JOB.md" ] && [ -f "jobs/$JOB.conf" ] || { echo "no such job: $JOB (need jobs/$JOB.md and jobs/$JOB.conf)"; exit 2; }

DRY="${JOB_DRYRUN:-0}"
mkdir -p logs "$VAULT/Daily" "$VAULT/Digests"
LOG="logs/$([ "$DRY" = 1 ] && echo dryrun-)$JOB-$(date +%Y%m%d-%H%M).log"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude)}"
[ -n "$CLAUDE_BIN" ] || { echo "claude not found on PATH; set CLAUDE_BIN in config.sh" | tee -a "$LOG"; exit 2; }

# Permission rules want //c/Users/... style absolute paths
V="/$(cygpath -u "$VAULT" 2>/dev/null || echo "$VAULT")"
V="${V%/}"

# Defaults; jobs/<job>.conf overrides them. It can use $V (the vault) in its rules.
ALLOW=("Read($V/**)" "Edit($V/Daily/**)" "Edit($V/Digests/**)" Glob Grep)
MODEL="${DEFAULT_MODEL:-sonnet}"
TIMEOUT=20m
TURNS=40
src "jobs/$JOB.conf"

# Always denied: shell, web, subagents, and edits to the runner folder or Memory.md
DENY=(Bash PowerShell WebFetch WebSearch Agent "Edit($V/Memory.md)" "Edit(/$(cygpath -u "$HERE" 2>/dev/null || echo "$HERE")/**)")

if [ "$DRY" = 1 ]; then
  mkdir -p "$VAULT/Digests/_dryrun"
  KEEP=(); for a in "${ALLOW[@]}"; do case "$a" in Edit\(*|Write\(*|mcp__*) ;; *) KEEP+=("$a") ;; esac; done
  ALLOW=("${KEEP[@]}" "Edit($V/Digests/_dryrun/**)")
fi

PROMPT="Current local time: $(date '+%A %Y-%m-%d %H:%M'). Use exactly this date and time in file names, headings and log lines.
Your notes folder (the vault) is: $VAULT

$(cat jobs/_rules.md "jobs/$JOB.md")"
[ "$DRY" = 1 ] && PROMPT="$PROMPT

DRY RUN: write every file you would write to $VAULT/Digests/_dryrun/$JOB.md instead (one section per real target path). Don't edit anything else."

(
  echo "=== $JOB started $(date '+%Y-%m-%d %H:%M:%S')$([ "$DRY" = 1 ] && echo ' DRY RUN')"
  timeout "$TIMEOUT" "$CLAUDE_BIN" -p "$PROMPT" \
    --model "$MODEL" \
    --tools "Read,Edit,Write,Glob,Grep" \
    --allowedTools "${ALLOW[@]}" \
    --disallowedTools "${DENY[@]}" \
    --permission-mode dontAsk \
    --max-turns "$TURNS" < /dev/null
  RC=$?
  echo
  echo "=== $JOB exit $RC at $(date '+%Y-%m-%d %H:%M:%S')"
  exit $RC
) >> "$LOG" 2>&1
RC=$?

REASON=""
[ "$RC" -ne 0 ] && REASON="exit $RC"
[ "$RC" -eq 124 ] && REASON="timed out after $TIMEOUT"
# Only the last non-empty line Claude printed counts
LAST="$(grep -v '^[[:space:]]*$' "$LOG" | grep -v '^=== ' | tail -1)"
case "$LAST" in JOB_FAILED:*) REASON="${LAST#JOB_FAILED: }" ;; esac
if [ -n "$REASON" ]; then
  echo "Job $JOB failed: $REASON. Log: $HERE/$LOG"
  exit 1
fi
case "$LAST" in NOTIFY:*) echo "Note from $JOB: ${LAST#NOTIFY: }" ;; esac
echo "Job $JOB done. Log: $HERE/$LOG"
exit 0
