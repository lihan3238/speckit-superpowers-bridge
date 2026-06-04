#!/usr/bin/env bash
# bridge-state.sh — shared helper for state-summary + pending-task counting.
# Sourced by update-handoff.sh and guard-command.sh.
# Contract: specs/008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md
# Decision basis: specs/008-bridge-hardening-0-5-0/research.md (R1-R4) + spec FR-001..FR-005.

# Canonical regexes per FR-001 + FR-005 + Clarifications Q4/Q6.
# Task-ID lines: `^- \[ \] T\d+`  (POSIX ERE form below uses [0-9])
# Deferred-exemption header text (case-insensitive): one of deferred|optional|out of scope|won't do|future|wontfix|backlog
# Implementation uses awk with tolower() for portability across gawk and POSIX awk.

get_pending_task_count() {
    # Args: tasks_path
    # Stdout: integer >= 0 if file exists; "-1" sentinel if file missing
    local tasks_path="$1"
    if [ ! -f "$tasks_path" ]; then
        printf -- '-1\n'
        return 0
    fi
    awk '
        BEGIN { in_exempt = 0; pending = 0 }
        # Detect any markdown header
        /^#+[[:space:]]+/ {
            lower = tolower($0)
            if (lower ~ /\<deferred\>/ || lower ~ /\<optional\>/ || lower ~ /\<out of scope\>/ \
                || lower ~ /won.?t do/ || lower ~ /\<future\>/ || lower ~ /\<wontfix\>/ || lower ~ /\<backlog\>/) {
                in_exempt = 1
            } else {
                in_exempt = 0
            }
            next
        }
        # Count task-ID checkbox lines outside exemption
        !in_exempt && /^- \[ \] T[0-9]+/ { pending++ }
        END { print pending+0 }
    ' "$tasks_path"
}

write_bridge_state_summary() {
    # Args: handoff_path repo_root actor prior_actor emit_complete_warning(true|false)
    local handoff_path="$1"
    local repo_root="$2"
    local actor="$3"
    local prior_actor="${4:-}"
    local emit_warning="${5:-false}"

    if [ ! -f "$handoff_path" ]; then
        return 0
    fi

    local feature_dir status owner
    feature_dir="$(jq -r '.feature_directory // ""' "$handoff_path" 2>/dev/null || printf '')"
    status="$(jq -r '.status // ""' "$handoff_path" 2>/dev/null || printf '')"
    owner="$(jq -r '.artifact_owner // ""' "$handoff_path" 2>/dev/null || printf '')"

    local dir_label status_label owner_label actor_label
    if [ -z "$feature_dir" ] || [ "$feature_dir" = "null" ]; then dir_label="(none)"; else dir_label="$feature_dir"; fi
    if [ -z "$status" ]; then status_label="(unknown)"; else status_label="$status"; fi
    if [ -z "$owner" ]; then owner_label="unknown"; else owner_label="$owner"; fi
    if [ -z "$actor" ]; then actor_label="unknown"; else actor_label="$actor"; fi

    printf '[bridge state]\n'
    printf '  Feature directory: %s\n' "$dir_label"
    printf '  Status: %s\n' "$status_label"
    printf '  Artifact owner: %s\n' "$owner_label"
    if [ -n "$prior_actor" ] && [ "$prior_actor" != "$actor_label" ]; then
        printf '  Actor: %s → %s\n' "$prior_actor" "$actor_label"
    else
        printf '  Actor: %s\n' "$actor_label"
    fi

    local pending tasks_path
    if [ -z "$feature_dir" ] || [ "$feature_dir" = "null" ]; then
        printf '  Pending tasks: (no feature_directory)\n'
        return 0
    fi

    if [[ "$feature_dir" = /* ]]; then
        tasks_path="$feature_dir/tasks.md"
    else
        tasks_path="$repo_root/$feature_dir/tasks.md"
    fi

    pending="$(get_pending_task_count "$tasks_path")"
    if [ "$pending" = "-1" ]; then
        printf '  Pending tasks: (no tasks.md)\n'
        return 0
    fi
    printf '  Pending tasks: %s\n' "$pending"

    if [ "$emit_warning" = "true" ] && [ "$status" = "complete" ] && [ "$pending" -gt 0 ]; then
        printf "[bridge] WARNING: handoff is 'complete' but tasks.md has %s unchecked tasks; review or move under a deferred section.\n" "$pending" >&2
    fi
}

# ---------------------------------------------------------------------------
# v0.7.0+ additions: artifact-hash + next-command helpers for bridge-status.sh.
# Spec: specs/012-bridge-status-and-hash/spec.md
# Contracts:
#   specs/012-bridge-status-and-hash/contracts/bridge-status-output.md
#   specs/012-bridge-status-and-hash/contracts/handoff-v1.1.delta.md
#   specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md
# These helpers are stateless and side-effect-free; the existing
# write_bridge_state_summary above stays byte-identical (SC-008).
# ---------------------------------------------------------------------------

# Canonical artifact set (spec.md, plan.md, tasks.md) per spec Clarifications Q1.
BRIDGE_ARTIFACTS=(spec.md plan.md tasks.md)

# Compute the SHA256 of a file, lowercase hex, or empty string when missing.
# Args: filepath
compute_artifact_sha256() {
    local p="$1"
    if [ -f "$p" ]; then
        sha256sum "$p" | awk '{print $1}'
    else
        printf ''
    fi
}

# Emit a JSON object for use inside handoff JSON: {"spec.md":hash_or_null, "plan.md":..., "tasks.md":...}.
# Args: feature_full_path
# Stdout: single-line JSON object
build_artifacts_sha256_json() {
    local feature_full="$1"
    local out="{"
    local first=true
    local f h
    for f in "${BRIDGE_ARTIFACTS[@]}"; do
        if [ "$first" = true ]; then first=false; else out="$out,"; fi
        h="$(compute_artifact_sha256 "$feature_full/$f")"
        if [ -z "$h" ]; then
            out="$out\"$f\":null"
        else
            out="$out\"$f\":\"$h\""
        fi
    done
    out="$out}"
    printf '%s' "$out"
}

# Return comma-joined list of drifted filenames (canonical order) by comparing
# stored handoff hashes against live file hashes. Empty string if no drift OR
# the handoff has no artifacts_sha256 snapshot (pre-0.7.0 backward compat).
# Args: handoff_path feature_full
get_drift_list() {
    local handoff_path="$1"
    local feature_full="$2"
    [ -f "$handoff_path" ] || { printf ''; return 0; }
    [ -n "$feature_full" ] || { printf ''; return 0; }
    local has_snap
    has_snap="$(jq -r 'has("artifacts_sha256")' "$handoff_path" 2>/dev/null || printf 'false')"
    [ "$has_snap" = "true" ] || { printf ''; return 0; }
    local drifted=""
    local f stored live
    for f in "${BRIDGE_ARTIFACTS[@]}"; do
        stored="$(jq -r ".artifacts_sha256[\"$f\"] // \"\"" "$handoff_path" 2>/dev/null || printf '')"
        [ "$stored" = "null" ] && stored=""
        live="$(compute_artifact_sha256 "$feature_full/$f")"
        if [ "$stored" != "$live" ]; then
            if [ -z "$drifted" ]; then drifted="$f"; else drifted="$drifted, $f"; fi
        fi
    done
    printf '%s' "$drifted"
}

# Emit drift detail array used by update-handoff for the artifact_drift_detected event.
# Args: handoff_path feature_full
# Stdout: single-line JSON array of {"path","old_sha256","new_sha256"} for drifted artifacts
build_drift_details_json() {
    local handoff_path="$1"
    local feature_full="$2"
    local arr="["
    local first=true
    local f stored live
    [ -f "$handoff_path" ] || { printf '[]'; return 0; }
    for f in "${BRIDGE_ARTIFACTS[@]}"; do
        stored="$(jq -r ".artifacts_sha256[\"$f\"] // null" "$handoff_path" 2>/dev/null)"
        live="$(compute_artifact_sha256 "$feature_full/$f")"
        local stored_json live_json
        if [ -z "$stored" ] || [ "$stored" = "null" ]; then stored_json="null"; else stored_json="\"$stored\""; fi
        if [ -z "$live" ]; then live_json="null"; else live_json="\"$live\""; fi
        if [ "$stored" = "null" ] && [ -z "$live" ]; then continue; fi
        if [ -n "$stored" ] && [ "$stored" != "null" ] && [ "$stored" = "$live" ]; then continue; fi
        if [ "$first" = true ]; then first=false; else arr="$arr,"; fi
        arr="$arr{\"path\":\"$f\",\"old_sha256\":$stored_json,\"new_sha256\":$live_json}"
    done
    arr="$arr]"
    printf '%s' "$arr"
}

# Compute the Next: recommendation per
# specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md.
# Args: repo_root handoff_path
get_next_command_recommendation() {
    local repo_root="$1"
    local handoff_path="$2"
    local has_handoff="false" status="" feature_dir="" has_constitution="false"
    local has_feature_dir="false" has_spec="false" has_plan="false" has_tasks="false"

    [ -f "$repo_root/.specify/memory/constitution.md" ] && has_constitution="true"

    if [ -f "$handoff_path" ]; then
        if jq -e '.' "$handoff_path" >/dev/null 2>&1; then
            has_handoff="true"
            status="$(jq -r '.status // ""' "$handoff_path")"
            feature_dir="$(jq -r '.feature_directory // ""' "$handoff_path")"
            [ "$feature_dir" = "null" ] && feature_dir=""
        else
            printf 'inspect .specify/superpowers-handoff.json'
            return 0
        fi
    fi

    local feature_full=""
    if [ -n "$feature_dir" ]; then
        if [[ "$feature_dir" = /* ]]; then feature_full="$feature_dir"; else feature_full="$repo_root/$feature_dir"; fi
        if [ -d "$feature_full" ]; then
            has_feature_dir="true"
            [ -f "$feature_full/spec.md" ] && has_spec="true"
            [ -f "$feature_full/plan.md" ] && has_plan="true"
            [ -f "$feature_full/tasks.md" ] && has_tasks="true"
        fi
    fi

    # Rule 2: no constitution (highest precedence after corruption)
    [ "$has_constitution" = "false" ] && { printf '/speckit-constitution'; return 0; }
    # Rule 3: no handoff
    [ "$has_handoff" = "false" ] && { printf '/speckit-specify'; return 0; }
    # Rules 4 & 5: feature_dir missing
    if [ "$has_feature_dir" = "false" ]; then
        if [ "$status" = "ready" ] || [ -z "$status" ]; then
            printf '/speckit-specify'
        else
            printf 'clear handoff or restore feature directory'
        fi
        return 0
    fi
    # Rule 6: spec missing
    [ "$has_spec" = "false" ] && { printf '/speckit-specify'; return 0; }
    # Rule 7: plan missing
    [ "$has_plan" = "false" ] && { printf '/speckit-plan'; return 0; }
    # Rule 8: tasks missing
    [ "$has_tasks" = "false" ] && { printf '/speckit-tasks'; return 0; }
    # Rules 9-12: all artifacts present, branch on status
    case "$status" in
        ready)     printf 'start handoff (update-handoff --status executing)' ;;
        executing) printf 'continue implementation via speckit-superpowers-bridge SKILL' ;;
        blocked)   printf 'resolve blocked_reason or rerun /speckit-clarify' ;;
        complete)  printf '/speckit-specify' ;;
        *)         printf '(none)' ;;
    esac
}
