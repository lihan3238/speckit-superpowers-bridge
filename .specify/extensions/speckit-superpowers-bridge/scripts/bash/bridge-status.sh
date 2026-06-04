#!/usr/bin/env bash
set -euo pipefail

# bridge-status.sh — read-only bridge state introspection (v0.7.0+).
#
# Spec:      specs/012-bridge-status-and-hash/spec.md (FR-001..FR-007)
# Contract:  specs/012-bridge-status-and-hash/contracts/bridge-status-output.md
#            specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md
#
# Prints the existing [bridge state] block (008 contract, 5 lines) plus a
# conditional `  Drift:` line (when handoff has artifacts_sha256) and a
# `  Next:` recommendation line. Read-only: does NOT write the handoff,
# does NOT append to bridge-events.jsonl, does NOT invoke guard logic.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common-actor-resolution.sh
. "$SCRIPT_DIR/common-actor-resolution.sh"
# shellcheck source=bridge-state.sh
. "$SCRIPT_DIR/bridge-state.sh"

JSON_MODE=false
ACTOR=""
NO_DRIFT_CHECK=false
READINESS_MODE=false

usage_error() { printf 'Usage error: %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
    case "$1" in
        --json)            JSON_MODE=true; shift ;;
        --readiness)       READINESS_MODE=true; shift ;;
        --actor)           ACTOR="${2:-}"; shift 2 ;;
        --no-drift-check)  NO_DRIFT_CHECK=true; shift ;;
        *) usage_error "unknown argument: $1" ;;
    esac
done

command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 2; }

REPO_ROOT="$(get_repo_root)"
SPECIFY_DIR="$REPO_ROOT/.specify"
if [ ! -d "$SPECIFY_DIR" ]; then
    printf '[bridge] not inside a Spec Kit repository\n' >&2
    exit 2
fi
HANDOFF_PATH="$SPECIFY_DIR/superpowers-handoff.json"
ACTOR="$(resolve_bridge_actor "$ACTOR")"

# Determine state classification: no-handoff | corrupted | parseable
STATE="parseable"
if [ ! -f "$HANDOFF_PATH" ]; then
    STATE="no-handoff"
elif ! jq -e '.' "$HANDOFF_PATH" >/dev/null 2>&1; then
    STATE="corrupted"
fi

# Pull fields based on state
feature_dir="" status="" owner=""
case "$STATE" in
    no-handoff)
        feature_dir="(none)"
        status="(no handoff)"
        owner="unknown"
        ;;
    corrupted)
        feature_dir="(unknown)"
        status="(corrupted handoff)"
        owner="(unknown)"
        ;;
    parseable)
        feature_dir="$(jq -r '.feature_directory // ""' "$HANDOFF_PATH")"
        [ "$feature_dir" = "null" ] && feature_dir=""
        status="$(jq -r '.status // ""' "$HANDOFF_PATH")"
        owner="$(jq -r '.artifact_owner // ""' "$HANDOFF_PATH")"
        [ -z "$feature_dir" ] && feature_dir="(none)"
        [ -z "$status" ] && status="(unknown)"
        [ -z "$owner" ] && owner="unknown"
        ;;
esac

# Pending tasks
pending_label=""
pending_int=""
if [ "$STATE" = "corrupted" ]; then
    pending_label="(unknown)"
elif [ "$feature_dir" = "(none)" ] || [ -z "$feature_dir" ]; then
    pending_label="(no feature_directory)"
else
    if [[ "$feature_dir" = /* ]]; then feature_full="$feature_dir"; else feature_full="$REPO_ROOT/$feature_dir"; fi
    if [ ! -d "$feature_full" ]; then
        pending_label="(no feature_directory)"
    else
        pending_count="$(get_pending_task_count "$feature_full/tasks.md")"
        if [ "$pending_count" = "-1" ]; then pending_label="(no tasks.md)"
        else pending_label="$pending_count"; pending_int="$pending_count"; fi
    fi
fi

# Drift detection (only when state is parseable AND not skipped)
drift_list=""
drift_present=false
if [ "$STATE" = "parseable" ] && [ "$NO_DRIFT_CHECK" = false ] && [ "$feature_dir" != "(none)" ]; then
    has_snap="$(jq -r 'has("artifacts_sha256")' "$HANDOFF_PATH" 2>/dev/null || printf 'false')"
    if [ "$has_snap" = "true" ]; then
        drift_present=true
        if [[ "$feature_dir" = /* ]]; then feature_full="$feature_dir"; else feature_full="$REPO_ROOT/$feature_dir"; fi
        drift_list="$(get_drift_list "$HANDOFF_PATH" "$feature_full")"
    fi
fi

# Next-command recommendation
next_rec="$(get_next_command_recommendation "$REPO_ROOT" "$HANDOFF_PATH")"

# Emit output

if [ "$READINESS_MODE" = true ]; then
    BRIDGE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

    tools_status="ready"
    jq_version="$(jq --version 2>/dev/null | sed 's/^jq-//')"
    bash_version="${BASH_VERSION%%(*}"
    tools_detail="jq: ${jq_version:-unknown}; bash: ${bash_version:-unknown}"
    tools_json="$(jq -nc --arg jqv "${jq_version:-unknown}" --arg bashv "${bash_version:-unknown}" '[{name:"jq",status:"ready",version:$jqv},{name:"bash",status:"ready",version:$bashv}]')"

    namespace_status="ready"
    namespace_detail="speckit.speckit-superpowers-bridge.*"
    extension_id=""
    manifest="$BRIDGE_DIR/extension.yml"
    if [ ! -f "$manifest" ]; then
        namespace_status="failed"
        namespace_detail="missing extension.yml"
    else
        extension_id="$(sed -nE 's/^[[:space:]]{2,}id:[[:space:]]*["'\'']?([^"'\''[:space:]#]+).*/\1/p' "$manifest" | head -1)"
        expected_prefix="speckit.${extension_id}."
        bad_commands="$(grep -E '^[[:space:]]*-[[:space:]]+name:[[:space:]]*["'\'']?speckit\.' "$manifest" 2>/dev/null | grep -vF "$expected_prefix" || true)"
        bad_hooks="$(grep -E '^[[:space:]]*command:[[:space:]]*["'\'']?speckit\.' "$manifest" 2>/dev/null | grep -vF "$expected_prefix" || true)"
        if [ "$extension_id" != "speckit-superpowers-bridge" ] || [ -n "$bad_commands$bad_hooks" ]; then
            namespace_status="failed"
            namespace_detail="expected prefix speckit.speckit-superpowers-bridge.*"
        fi
    fi

    missing=()
    for rel in \
        extension.yml \
        verified-versions.json \
        commands/speckit.speckit-superpowers-bridge.execute.md \
        commands/speckit.speckit-superpowers-bridge.guard.md \
        commands/speckit.speckit-superpowers-bridge.handoff.md \
        scripts/bash/bridge-status.sh \
        scripts/bash/guard-command.sh \
        scripts/bash/update-handoff.sh \
        scripts/powershell/bridge-status.ps1 \
        scripts/powershell/guard-command.ps1 \
        scripts/powershell/update-handoff.ps1
    do
        [ -e "$BRIDGE_DIR/$rel" ] || missing+=("$rel")
    done
    package_status="ready"
    package_detail="required bridge files present"
    if [ "${#missing[@]}" -gt 0 ]; then
        package_status="failed"
        package_detail="missing: ${missing[*]}"
    fi
    if [ "${#missing[@]}" -gt 0 ]; then
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -Rsc 'split("\n")[:-1]')"
    else
        missing_json='[]'
    fi

    bridge_state_status="ready"
    bridge_state_detail="status: $status; pending tasks: $pending_label"
    if [ "$STATE" = "corrupted" ]; then
        bridge_state_status="failed"
        bridge_state_detail="corrupted handoff"
    elif [ "$STATE" = "no-handoff" ]; then
        bridge_state_status="warning"
        bridge_state_detail="no handoff file"
    fi

    agents_status="not checked"
    agents_detail="verified-versions.json has no agent rows"
    agents_json='[]'
    verified="$BRIDGE_DIR/verified-versions.json"
    if [ -f "$verified" ] && jq -e '.agents? // empty' "$verified" >/dev/null 2>&1; then
        agents_json="$(jq -c '.agents' "$verified")"
        if jq -e '(.agents // []) | length > 0 and all(.status == "passed")' "$verified" >/dev/null 2>&1; then
            agents_status="ready"
        else
            agents_status="warning"
        fi
        agents_detail="$(jq -r '(.agents // []) | map(.name + ": " + .status) | join("; ")' "$verified")"
        [ -n "$agents_detail" ] || agents_detail="no agent rows"
    fi

    overall_status="ready"
    if [ "$tools_status" = "failed" ] || [ "$namespace_status" = "failed" ] || [ "$package_status" = "failed" ] || [ "$bridge_state_status" = "failed" ]; then
        overall_status="failed"
    elif [ "$tools_status" = "warning" ] || [ "$bridge_state_status" = "warning" ] || [ "$agents_status" = "warning" ] || [ "$agents_status" = "not checked" ]; then
        overall_status="warning"
    fi

    if [ "$JSON_MODE" = true ]; then
        jq -nc \
            --arg script_flavor "sh" \
            --arg tools_status "$tools_status" --argjson tools_items "$tools_json" \
            --arg namespace_status "$namespace_status" --arg extension_id "$extension_id" --arg command_prefix "speckit.speckit-superpowers-bridge." \
            --arg package_status "$package_status" --argjson missing "$missing_json" \
            --arg bridge_status "$bridge_state_status" --arg feature_directory "$([ "$feature_dir" = "(none)" ] && printf '' || printf '%s' "$feature_dir")" --arg next "$next_rec" \
            --arg agents_status "$agents_status" --argjson agents_items "$agents_json" \
            --arg overall_status "$overall_status" \
            '{script_flavor:$script_flavor,
              required_tools:{status:$tools_status,items:$tools_items},
              namespace:{status:$namespace_status,extension_id:$extension_id,command_prefix:$command_prefix},
              package_files:{status:$package_status,missing:$missing},
              bridge_state:{status:$bridge_status,feature_directory:(if $feature_directory=="" then null else $feature_directory end),next:$next},
              agents:{status:$agents_status,items:$agents_items},
              overall_status:$overall_status,
              next:$next}'
    else
        printf '[bridge readiness]\n'
        printf '  Script flavor: sh\n'
        printf '  Required tools: %s (%s)\n' "$tools_status" "$tools_detail"
        printf '  Namespace: %s (%s)\n' "$namespace_status" "$namespace_detail"
        printf '  Package files: %s (%s)\n' "$package_status" "$package_detail"
        printf '  Bridge state: %s (%s)\n' "$bridge_state_status" "$bridge_state_detail"
        printf '  Agents: %s (%s)\n' "$agents_status" "$agents_detail"
        printf '  Next: %s\n' "$next_rec"
    fi
    [ "$overall_status" = "failed" ] && exit 1
    exit 0
fi

if [ "$JSON_MODE" = true ]; then
    # JSON output mode (R-JSON-1..R-JSON-8). Use jq -n to build the object.
    rc=0; [ "$STATE" = "corrupted" ] && rc=3
    json_status="null"; json_owner="null"
    case "$STATE" in
        no-handoff) json_status='no_handoff'; json_owner='unknown' ;;
        corrupted)  json_status='corrupted_handoff' ;;
        parseable)
            json_status="$(jq -r '.status // empty' "$HANDOFF_PATH")"
            json_owner="$(jq -r '.artifact_owner // empty' "$HANDOFF_PATH")"
            ;;
    esac
    drift_arr_json="null"
    if [ "$drift_present" = true ]; then
        if [ -z "$drift_list" ]; then
            drift_arr_json='{"detected":false,"artifacts":[]}'
        else
            drift_arr_json="$(printf '%s' "$drift_list" | jq -Rsc 'split(", ") | {detected:true, artifacts:.}')"
        fi
    fi
    jq -nc \
        --arg fd "$([ "$feature_dir" = "(none)" ] && printf '' || printf '%s' "$feature_dir")" \
        --arg st "$json_status" --arg ow "$json_owner" --arg ac "$ACTOR" \
        --argjson pt "${pending_int:-null}" --argjson dr "$drift_arr_json" \
        --arg nx "${next_rec:-(none)}" --argjson rc "$rc" \
        '{feature_directory:(if $fd=="" then null else $fd end),
          status:(if $st=="" then null else $st end),
          artifact_owner:(if $ow=="" then null else $ow end),
          actor:$ac, pending_tasks:$pt, drift:$dr, next:$nx, exit_code:$rc}'
    if [ "$STATE" = "corrupted" ]; then
        jq -e '.' "$HANDOFF_PATH" 2>&1 >/dev/null | head -1 >&2 || true
        exit 3
    fi
    exit 0
fi

# Human-mode output
printf '[bridge state]\n'
printf '  Feature directory: %s\n' "$feature_dir"
printf '  Status: %s\n' "$status"
printf '  Artifact owner: %s\n' "$owner"
printf '  Actor: %s\n' "$ACTOR"
printf '  Pending tasks: %s\n' "$pending_label"
if [ "$drift_present" = true ]; then
    if [ -z "$drift_list" ]; then
        printf '  Drift: (none)\n'
    else
        printf '  Drift: %s\n' "$drift_list"
    fi
fi
printf '  Next: %s\n' "$next_rec"

if [ "$STATE" = "corrupted" ]; then
    # Emit parse error to stderr for downstream consumers
    jq -e '.' "$HANDOFF_PATH" 2>&1 >/dev/null | head -1 >&2 || true
    # Fallback if jq didn't produce output for some reason
    [ -s /dev/stderr ] || printf 'jq: parse error reading %s\n' "$HANDOFF_PATH" >&2
    exit 3
fi
exit 0
