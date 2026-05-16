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
