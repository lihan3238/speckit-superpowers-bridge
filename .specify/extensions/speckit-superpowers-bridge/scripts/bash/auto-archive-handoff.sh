#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-actor-resolution.sh
. "$SCRIPT_DIR/common-actor-resolution.sh"

ACTOR=""
REASON="Auto-archive complete handoff before new feature."

usage_error() {
    printf 'Usage error: %s\n' "$1" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --actor) ACTOR="${2:-}"; shift 2 ;;
        --reason) REASON="${2:-}"; shift 2 ;;
        *) usage_error "unknown argument: $1" ;;
    esac
done

command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 1; }

REPO_ROOT="$(get_repo_root)"
ACTOR="$(resolve_bridge_actor "$ACTOR")"
HANDOFF_PATH="$REPO_ROOT/.specify/superpowers-handoff.json"

if [ ! -f "$HANDOFF_PATH" ]; then
    printf 'No handoff file at %s; nothing to archive.\n' "$HANDOFF_PATH"
    exit 0
fi

current_status="$(jq -r '.status // empty' "$HANDOFF_PATH")"
if [ "$current_status" != "complete" ]; then
    printf "No complete handoff to archive (current status: '%s').\n" "$current_status"
    exit 0
fi

prior_feature_directory="$(jq -r '.feature_directory // empty' "$HANDOFF_PATH")"

"$SCRIPT_DIR/update-handoff.sh" --status ready --clear-feature-directory --artifact-owner unknown --reason "$REASON" --actor "$ACTOR" >/dev/null

snapshot_id="$(jq -r '.last_snapshot_id // empty' "$HANDOFF_PATH")"
jq -nc \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg feature_directory "$prior_feature_directory" \
    --arg reason "$REASON" \
    --arg actor "$ACTOR" \
    --arg snapshot_id "$snapshot_id" \
    '{timestamp:$timestamp, action:"archive", status:"archived", feature_directory:$feature_directory, decision:"archive", reason:$reason, actor:$actor, snapshot_id:$snapshot_id}' \
    >> "$REPO_ROOT/.specify/bridge-events.jsonl"

printf "Auto-archived handoff for '%s' (snapshot: %s).\n" "$prior_feature_directory" "$snapshot_id"
exit 0
