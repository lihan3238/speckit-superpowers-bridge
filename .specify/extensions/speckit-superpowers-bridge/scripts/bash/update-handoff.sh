#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-actor-resolution.sh
. "$SCRIPT_DIR/common-actor-resolution.sh"
# shellcheck source=bridge-state.sh
. "$SCRIPT_DIR/bridge-state.sh"

STATUS="ready"
FEATURE_DIRECTORY=""
REASON=""
ARTIFACT_OWNER=""
REVIEW_ONLY_AGENTS=""
ACTOR=""
CLEAR_FEATURE_DIRECTORY=false

usage_error() {
    printf 'Usage error: %s\n' "$1" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --status) STATUS="${2:-}"; shift 2 ;;
        --feature-directory) FEATURE_DIRECTORY="${2:-}"; shift 2 ;;
        --reason) REASON="${2:-}"; shift 2 ;;
        --artifact-owner) ARTIFACT_OWNER="${2:-}"; shift 2 ;;
        --review-only-agents) REVIEW_ONLY_AGENTS="${2:-}"; shift 2 ;;
        --actor) ACTOR="${2:-}"; shift 2 ;;
        --clear-feature-directory) CLEAR_FEATURE_DIRECTORY=true; shift ;;
        --append-archive-entry) shift 2 ;; # Accepted for PS CLI parity; v1 does not persist archive history.
        *) usage_error "unknown argument: $1" ;;
    esac
done

case "$STATUS" in ready|executing|blocked|complete) ;; *) usage_error "invalid --status: $STATUS" ;; esac
case "$ARTIFACT_OWNER" in ""|codex|claude|unknown) ;; *) usage_error "invalid --artifact-owner: $ARTIFACT_OWNER" ;; esac

command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 1; }

REPO_ROOT="$(get_repo_root)"
ACTOR="$(resolve_bridge_actor "$ACTOR")"
SPECIFY_DIR="$REPO_ROOT/.specify"
HANDOFF_PATH="$SPECIFY_DIR/superpowers-handoff.json"

[ -d "$SPECIFY_DIR" ] || { printf 'Missing .specify directory. Run this from a Spec Kit project.\n' >&2; exit 1; }

timestamp_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

snapshot_timestamp() {
    local base nanos
    base="$(date -u +"%Y%m%dT%H%M%S")"
    nanos="$(date -u +"%N" 2>/dev/null || printf '000000000')"
    case "$nanos" in *N*) nanos="000000000" ;; esac
    printf '%s%sZ\n' "$base" "${nanos:0:3}"
}

project_path() {
    local path="$1"
    [ -n "$path" ] || return 0
    local full root
    full="$(realpath -m "$path")"
    root="$(realpath -m "$REPO_ROOT")"
    case "$full" in
        "$root"/*) printf '%s\n' "${full#"$root"/}" ;;
        "$root") printf '.\n' ;;
        *) printf '%s\n' "$full" ;;
    esac
}

json_field() {
    local path="$1" expr="$2"
    if [ -f "$path" ]; then jq -r "$expr // empty" "$path" 2>/dev/null || true; fi
}

prior_feature_directory="$(json_field "$HANDOFF_PATH" '.feature_directory')"
prior_artifact_owner="$(json_field "$HANDOFF_PATH" '.artifact_owner')"
# v0.7.0+: capture prior artifacts_sha256 snapshot for drift comparison on complete writes.
prior_artifacts_sha256_json="null"
if [ -f "$HANDOFF_PATH" ]; then
    if jq -e 'has("artifacts_sha256") and (.artifacts_sha256 != null)' "$HANDOFF_PATH" >/dev/null 2>&1; then
        prior_artifacts_sha256_json="$(jq -c '.artifacts_sha256' "$HANDOFF_PATH" 2>/dev/null || printf 'null')"
    fi
fi
# FR-004: prior_actor sourced from the most recent handoff event (NOT from the handoff JSON,
# which does not persist actor distinctly).
prior_actor=""
if [ -f "$SPECIFY_DIR/bridge-events.jsonl" ]; then
    prior_actor="$(grep '"action":"handoff"' "$SPECIFY_DIR/bridge-events.jsonl" 2>/dev/null | tail -n 1 | jq -r '.actor // empty' 2>/dev/null || printf '')"
fi
snapshot_source_directory=""

if [ "$CLEAR_FEATURE_DIRECTORY" = true ]; then
    snapshot_source_directory="$prior_feature_directory"
    FEATURE_DIRECTORY=""
elif [ -z "${FEATURE_DIRECTORY//[[:space:]]/}" ]; then
    if [ -n "$prior_feature_directory" ]; then
        FEATURE_DIRECTORY="$prior_feature_directory"
    elif [ -f "$SPECIFY_DIR/feature.json" ]; then
        FEATURE_DIRECTORY="$(jq -r '.feature_directory // empty' "$SPECIFY_DIR/feature.json")"
    fi
fi

feature_full=""
feature_project=""
if [ -n "${FEATURE_DIRECTORY//[[:space:]]/}" ]; then
    if [[ "$FEATURE_DIRECTORY" = /* ]]; then
        feature_full="$(realpath -m "$FEATURE_DIRECTORY")"
    else
        feature_full="$(realpath -m "$REPO_ROOT/$FEATURE_DIRECTORY")"
    fi
    feature_project="$(project_path "$feature_full")"
fi

source_spec=""
source_plan=""
source_tasks=""
missing=()
if [ -n "$feature_full" ]; then
    source_spec="$(project_path "$feature_full/spec.md")"
    source_plan="$(project_path "$feature_full/plan.md")"
    source_tasks="$(project_path "$feature_full/tasks.md")"
    [ -f "$feature_full/spec.md" ] || missing+=("$source_spec")
    [ -f "$feature_full/plan.md" ] || missing+=("$source_plan")
    [ -f "$feature_full/tasks.md" ] || missing+=("$source_tasks")
fi

resolved_status="$STATUS"
blocked_reason=""
if [ "${#missing[@]}" -gt 0 ] && [ "$STATUS" != "complete" ] && [ "$STATUS" != "ready" ]; then
    resolved_status="blocked"
    if [ -n "$REASON" ]; then
        blocked_reason="$REASON"
    else
        blocked_reason="Missing required Spec Kit artifacts: $(IFS=', '; printf '%s' "${missing[*]}")"
    fi
elif [ "$STATUS" = "blocked" ]; then
    blocked_reason="${REASON:-"(no reason provided)"}"
fi

owner="$ARTIFACT_OWNER"
if [ -z "$owner" ]; then
    if [ -n "$prior_artifact_owner" ]; then owner="$prior_artifact_owner"
    elif [ "$ACTOR" = "codex" ] || [ "$ACTOR" = "claude" ]; then owner="$ACTOR"
    else owner="unknown"
    fi
fi

snapshot_id=""
snapshot_path=""
if [ -n "$snapshot_source_directory" ]; then
    if [[ "$snapshot_source_directory" = /* ]]; then snapshot_path="$(realpath -m "$snapshot_source_directory")"
    else snapshot_path="$(realpath -m "$REPO_ROOT/$snapshot_source_directory")"
    fi
elif [ -n "$feature_full" ]; then
    snapshot_path="$feature_full"
fi

if [ -n "$snapshot_path" ] && [ -d "$snapshot_path" ]; then
    snapshot_id="$(snapshot_timestamp)-$resolved_status"
    snapshot_root="$SPECIFY_DIR/bridge-snapshots/$snapshot_id"
    mkdir -p "$snapshot_root"
    for artifact in spec.md plan.md tasks.md; do
        [ -f "$snapshot_path/$artifact" ] && cp "$snapshot_path/$artifact" "$snapshot_root/$artifact"
    done
    [ -f "$SPECIFY_DIR/memory/constitution.md" ] && cp "$SPECIFY_DIR/memory/constitution.md" "$snapshot_root/constitution.md"
fi

review_json="[]"
if [ -n "${REVIEW_ONLY_AGENTS//[[:space:]]/}" ]; then
    review_json="$(printf '%s\n' "$REVIEW_ONLY_AGENTS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != "")) | unique')"
fi

executor="superpowers"
[ "$resolved_status" = "ready" ] && executor="speckit"

# v0.7.0+: compute fresh artifacts_sha256 snapshot for executing/complete writes
# (spec FR-005, contract handoff-v1.1.delta.md). Omitted on ready/blocked writes.
fresh_artifacts_sha256_json="null"
if [ "$resolved_status" = "executing" ] || [ "$resolved_status" = "complete" ]; then
    if [ -n "$feature_full" ]; then
        fresh_artifacts_sha256_json="$(build_artifacts_sha256_json "$feature_full")"
    else
        fresh_artifacts_sha256_json='{"spec.md":null,"plan.md":null,"tasks.md":null}'
    fi
fi

# v0.7.0+: drift comparison on complete writes (spec FR-006, FR-008).
# Computed BEFORE we overwrite the handoff so prior snapshot is intact.
drifted_filenames=""
drift_details_json="[]"
if [ "$resolved_status" = "complete" ] && [ "$prior_artifacts_sha256_json" != "null" ]; then
    drift_details_json="$(jq -nc \
        --argjson p "$prior_artifacts_sha256_json" \
        --argjson n "$fresh_artifacts_sha256_json" \
        '["spec.md","plan.md","tasks.md"]
         | map(. as $k | {path:$k, old_sha256:($p[$k]//null), new_sha256:($n[$k]//null)})
         | map(select(.old_sha256 != .new_sha256))' 2>/dev/null || printf '[]')"
    if [ "$(printf '%s' "$drift_details_json" | jq 'length' 2>/dev/null || printf 0)" -gt 0 ]; then
        drifted_filenames="$(printf '%s' "$drift_details_json" | jq -r 'map(.path) | join(", ")')"
    fi
fi

jq -n \
    --arg updated_at "$(timestamp_iso)" \
    --arg feature_directory "$feature_project" \
    --arg spec "$source_spec" \
    --arg plan "$source_plan" \
    --arg tasks "$source_tasks" \
    --arg executor "$executor" \
    --arg status "$resolved_status" \
    --arg blocked_reason "$blocked_reason" \
    --arg artifact_owner "$owner" \
    --arg snapshot_id "$snapshot_id" \
    --arg instructions 'Use /speckit-superpowers-bridge (Claude Code) or $speckit-superpowers-bridge (Codex). The bridge orchestrates native Superpowers skills against tasks.md; do not run speckit.implement and do not invoke superpowers:writing-plans / :brainstorming for an active Spec Kit feature.' \
    --argjson review_only "$review_json" \
    --argjson artifacts_sha256 "$fresh_artifacts_sha256_json" \
    '{
        schema_version: 1,
        updated_at: $updated_at,
        feature_directory: (if $feature_directory == "" then null else $feature_directory end),
        source_of_truth: {
            constitution: ".specify/memory/constitution.md",
            spec: (if $spec == "" then null else $spec end),
            plan: (if $plan == "" then null else $plan end),
            tasks: (if $tasks == "" then null else $tasks end)
        },
        supersedes: ["speckit.implement"],
        executor: $executor,
        capabilities: ["executing-plans", "test-driven-development", "verification-before-completion", "requesting-code-review", "finishing-a-development-branch"],
        status: $status,
        blocked_reason: (if $blocked_reason == "" then null else $blocked_reason end),
        artifact_owner: $artifact_owner,
        review_only_agents: $review_only,
        notes: null,
        last_snapshot_id: (if $snapshot_id == "" then null else $snapshot_id end),
        instructions: $instructions
    } + (if $artifacts_sha256 == null then {} else {artifacts_sha256: $artifacts_sha256} end)' > "$HANDOFF_PATH"

event_reason="$REASON"
[ -z "$event_reason" ] && event_reason="$blocked_reason"

# FR-004: augment event-log reason with actor-change note when applicable.
if [ -n "$prior_actor" ] && [ "$prior_actor" != "$ACTOR" ]; then
    change_note="actor change $prior_actor → $ACTOR"
    if [ -z "$event_reason" ]; then
        event_reason="$change_note"
    else
        event_reason="$change_note; $event_reason"
    fi
fi

# prior_actor JSON value: null if empty string, quoted string otherwise.
if [ -n "$prior_actor" ]; then prior_actor_json="\"$prior_actor\""; else prior_actor_json="null"; fi

mkdir -p "$SPECIFY_DIR"
jq -nc \
    --arg timestamp "$(timestamp_iso)" \
    --arg status "$resolved_status" \
    --arg feature_directory "$feature_project" \
    --arg reason "$event_reason" \
    --arg actor "$ACTOR" \
    --argjson prior_actor "$prior_actor_json" \
    --arg snapshot_id "$snapshot_id" \
    '{timestamp:$timestamp, action:"handoff", status:$status, feature_directory:$feature_directory, decision:"updated", reason:$reason, actor:$actor, prior_actor:$prior_actor, snapshot_id:$snapshot_id}' \
    >> "$SPECIFY_DIR/bridge-events.jsonl"

printf "Wrote .specify/superpowers-handoff.json with status '%s'.\n" "$resolved_status"
[ -n "$blocked_reason" ] && printf 'Reason: %s\n' "$blocked_reason"

# v0.7.0+: emit drift warning + artifact_drift_detected event on complete writes (FR-006, FR-008).
if [ -n "$drifted_filenames" ]; then
    printf '[bridge] WARNING: artifact drift since executing snapshot: %s (sha256 mismatch)\n' "$drifted_filenames" >&2
    jq -nc \
        --arg timestamp "$(timestamp_iso)" \
        --arg actor "$ACTOR" \
        --arg feature_directory "$feature_project" \
        --argjson drifted "$drift_details_json" \
        '{event:"artifact_drift_detected", timestamp:$timestamp, actor:$actor, feature_directory:$feature_directory, drifted_artifacts:$drifted}' \
        >> "$SPECIFY_DIR/bridge-events.jsonl"
fi

# FR-001..FR-003: emit [bridge state] block. EmitCompleteWarning="true" makes the helper
# fire the FR-003 WARNING when status='complete' and tasks.md has unchecked task-IDs.
write_bridge_state_summary "$HANDOFF_PATH" "$REPO_ROOT" "$ACTOR" "$prior_actor" "true"

exit 0
