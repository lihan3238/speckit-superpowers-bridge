#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-actor-resolution.sh
. "$SCRIPT_DIR/common-actor-resolution.sh"
# shellcheck source=bridge-state.sh
. "$SCRIPT_DIR/bridge-state.sh"

ACTION=""
REASON=""
ACTOR=""
TARGET_FEATURE_DIRECTORY=""

usage_error() {
    printf 'Usage error: %s\n' "$1" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --action) ACTION="${2:-}"; shift 2 ;;
        --reason) REASON="${2:-}"; shift 2 ;;
        --actor) ACTOR="${2:-}"; shift 2 ;;
        --target-feature-directory) TARGET_FEATURE_DIRECTORY="${2:-}"; shift 2 ;;
        *) usage_error "unknown argument: $1" ;;
    esac
done

[ -n "${ACTION//[[:space:]]/}" ] || usage_error "--action is required"
command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 2; }

REPO_ROOT="$(get_repo_root)"
ACTOR="$(resolve_bridge_actor "$ACTOR")"
SPECIFY_DIR="$REPO_ROOT/.specify"
HANDOFF_PATH="$SPECIFY_DIR/superpowers-handoff.json"

timestamp_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

handoff_status=""
handoff_feature_dir=""
if [ -f "$HANDOFF_PATH" ]; then
    handoff_status="$(jq -r '.status // empty' "$HANDOFF_PATH" 2>/dev/null || true)"
    handoff_feature_dir="$(jq -r '.feature_directory // empty' "$HANDOFF_PATH" 2>/dev/null || true)"
fi

[ -n "$TARGET_FEATURE_DIRECTORY" ] && handoff_feature_dir="$TARGET_FEATURE_DIRECTORY"

decision=""
deny_reason=""

if [ "$ACTION" = "speckit.implement" ] && [ "$handoff_status" = "executing" ]; then
    decision="deny"
    deny_reason="speckit.implement blocked while superpowers handoff is executing"
elif { [ "$ACTION" = "superpowers:writing-plans" ] || [ "$ACTION" = "superpowers:brainstorming" ]; } && [ -n "$handoff_feature_dir" ]; then
    spec_path="$REPO_ROOT/$handoff_feature_dir/spec.md"
    plan_path="$REPO_ROOT/$handoff_feature_dir/plan.md"
    if [ -f "$spec_path" ] && [ -f "$plan_path" ]; then
        decision="deny"
        deny_reason="native superpowers planning is forbidden while spec kit owns design artifacts"
    fi
elif [ "$ACTION" = "speckit.constitution" ] && [ "$handoff_status" = "executing" ]; then
    decision="deny"
    deny_reason="constitution edits blocked during active handoff; mark blocked first"
elif [[ "$ACTION" == speckit.* ]]; then
    decision="allow"
else
    decision="allow"
fi

[ -n "$decision" ] || decision="allow"

mkdir -p "$SPECIFY_DIR"
jq -nc \
    --arg timestamp "$(timestamp_iso)" \
    --arg decision "$decision" \
    --arg feature_directory "$handoff_feature_dir" \
    --arg reason "$deny_reason" \
    --arg actor "$ACTOR" \
    --arg checked_action "$ACTION" \
    '{timestamp:$timestamp, action:"guard", status:$decision, feature_directory:$feature_directory, decision:$decision, reason:$reason, actor:$actor, checked_action:$checked_action}' \
    >> "$SPECIFY_DIR/bridge-events.jsonl"

# FR-002: emit [bridge state] block on every allow/deny decision (guard never mutates,
# so EmitCompleteWarning is "false"; PriorActor is empty since guard does not change actors).
write_bridge_state_summary "$HANDOFF_PATH" "$REPO_ROOT" "$ACTOR" "" "false"

if [ "$decision" = "deny" ]; then
    printf 'Guard denied %s.\n' "$ACTION"
    [ -n "$deny_reason" ] && printf 'Reason: %s\n' "$deny_reason"
    exit 1
fi

printf 'Guard allowed %s.\n' "$ACTION"
exit 0
