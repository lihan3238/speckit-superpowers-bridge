#!/usr/bin/env bash
# Smoke test for the 5 hardcoded guard rules (FR-007 + research.md R3 + CLAUDE.md):
#   R1: deny speckit.implement when handoff status == executing
#   R2: deny superpowers:writing-plans when active feature has spec.md + plan.md
#   R3: deny superpowers:brainstorming when active feature has spec.md + plan.md
#   R4: deny speckit.constitution when handoff status == executing
#   R5: allow all other speckit.* (and other non-planning skills) — default allow
#   Default: allow when no handoff file exists
#
# Bash port of tests/test-guard-hardcoded-rules.ps1 per
# specs/009-wsl-dev-env-alignment/contracts/tests-bash-port-contract.md "Port 2".
# Runs the bash flavor of guard-command.sh directly — no path translation,
# no cross-flavor dispatch.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_ROOT="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge"
GUARD_SCRIPT="$BRIDGE_ROOT/scripts/bash/guard-command.sh"
HANDOFF_PATH="$REPO_ROOT/.specify/superpowers-handoff.json"
HANDOFF_BACKUP="$HANDOFF_PATH.bak.guard-hardcoded-rules.$$"
HANDOFF_HAD_FILE=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_true() {
    # assert_true <condition-bool: 0/1> <message>
    if [ "$1" -ne 0 ]; then
        fail "$2"
    fi
}

restore_handoff() {
    if [ "$HANDOFF_HAD_FILE" -eq 1 ]; then
        if [ -f "$HANDOFF_BACKUP" ]; then
            mv -f "$HANDOFF_BACKUP" "$HANDOFF_PATH"
        fi
    else
        # No handoff file existed before; remove any we created during the test.
        rm -f "$HANDOFF_PATH"
        # Also remove any leftover backup (defensive).
        rm -f "$HANDOFF_BACKUP"
    fi
}
trap restore_handoff EXIT

# Dependency probe (common contract).
command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 2; }
command -v bash >/dev/null 2>&1 || { printf 'Missing dependency: bash\n' >&2; exit 2; }

if [ ! -f "$GUARD_SCRIPT" ]; then
    printf 'Missing dependency: %s\n' "$GUARD_SCRIPT" >&2
    exit 2
fi

# Snapshot the current handoff state so the trap can restore exactly what we found.
if [ -f "$HANDOFF_PATH" ]; then
    HANDOFF_HAD_FILE=1
    cp -p "$HANDOFF_PATH" "$HANDOFF_BACKUP"
fi

# --- Helpers --------------------------------------------------------------

write_executing_handoff() {
    # Writes a v1-shape handoff pinned to feature 006 (which has spec.md + plan.md).
    local feature_dir="$1"
    local ts
    ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    mkdir -p "$(dirname "$HANDOFF_PATH")"
    jq -n \
        --arg ts "$ts" \
        --arg fd "$feature_dir" \
        --arg spec "$feature_dir/spec.md" \
        --arg plan "$feature_dir/plan.md" \
        --arg tasks "$feature_dir/tasks.md" \
        '{
            schema_version: 1,
            updated_at: $ts,
            feature_directory: $fd,
            source_of_truth: {
                constitution: ".specify/memory/constitution.md",
                spec: $spec,
                plan: $plan,
                tasks: $tasks
            },
            executor: "superpowers",
            status: "executing",
            artifact_owner: "claude"
        }' > "$HANDOFF_PATH"
}

# run_guard <action> [target-feature-directory]
# Captures combined stdout+stderr into RUN_OUTPUT and exit code into RUN_EXIT.
RUN_OUTPUT=""
RUN_EXIT=0
run_guard() {
    local action="$1"
    local target="${2:-}"
    local rc=0
    if [ -n "$target" ]; then
        RUN_OUTPUT="$(bash "$GUARD_SCRIPT" --action "$action" --actor claude --target-feature-directory "$target" 2>&1)" || rc=$?
    else
        RUN_OUTPUT="$(bash "$GUARD_SCRIPT" --action "$action" --actor claude 2>&1)" || rc=$?
    fi
    RUN_EXIT=$rc
}

# Decide pass/fail booleans expected by assert_true (0 == pass per shell convention).
bool_pass() { if [ "$1" = "true" ]; then echo 0; else echo 1; fi; }

# --- Scenarios ------------------------------------------------------------

ACTIVE_FEATURE="specs/006-trim-to-thin-bridge"

# Pre-flight: confirm feature 006 has spec.md + plan.md (required for R2/R3).
if [ ! -f "$REPO_ROOT/$ACTIVE_FEATURE/spec.md" ] || [ ! -f "$REPO_ROOT/$ACTIVE_FEATURE/plan.md" ]; then
    printf 'Missing dependency: %s/{spec.md,plan.md}\n' "$ACTIVE_FEATURE" >&2
    exit 2
fi

# R1: deny speckit.implement when handoff status == executing
write_executing_handoff "$ACTIVE_FEATURE"
run_guard "speckit.implement"
case "$RUN_EXIT" in
    1) ;;
    *) fail "R1: speckit.implement should be denied (exit 1) during executing; got exit $RUN_EXIT" ;;
esac
case "$RUN_OUTPUT" in
    *"Guard denied"*) ;;
    *) fail "R1: speckit.implement deny output missing 'Guard denied' marker; output: $RUN_OUTPUT" ;;
esac

# R2: deny superpowers:writing-plans when active feature has spec.md + plan.md
write_executing_handoff "$ACTIVE_FEATURE"
run_guard "superpowers:writing-plans"
case "$RUN_EXIT" in
    1) ;;
    *) fail "R2: superpowers:writing-plans should be denied (exit 1) when spec+plan exist; got exit $RUN_EXIT" ;;
esac
case "$RUN_OUTPUT" in
    *"Guard denied"*) ;;
    *) fail "R2: superpowers:writing-plans deny output missing 'Guard denied' marker; output: $RUN_OUTPUT" ;;
esac

# R3: deny superpowers:brainstorming when active feature has spec.md + plan.md
# (Guard treats brainstorming the same as writing-plans when artifacts exist;
# contract phrasing uses tasks.md but the implemented predicate is spec+plan.)
write_executing_handoff "$ACTIVE_FEATURE"
run_guard "superpowers:brainstorming"
case "$RUN_EXIT" in
    1) ;;
    *) fail "R3: superpowers:brainstorming should be denied (exit 1) when spec+plan exist; got exit $RUN_EXIT" ;;
esac
case "$RUN_OUTPUT" in
    *"Guard denied"*) ;;
    *) fail "R3: superpowers:brainstorming deny output missing 'Guard denied' marker; output: $RUN_OUTPUT" ;;
esac

# R4: deny speckit.constitution when handoff status == executing
write_executing_handoff "$ACTIVE_FEATURE"
run_guard "speckit.constitution"
case "$RUN_EXIT" in
    1) ;;
    *) fail "R4: speckit.constitution should be denied (exit 1) during executing; got exit $RUN_EXIT" ;;
esac
case "$RUN_OUTPUT" in
    *"Guard denied"*) ;;
    *) fail "R4: speckit.constitution deny output missing 'Guard denied' marker; output: $RUN_OUTPUT" ;;
esac

# R5: allow all other speckit.* — also covers non-planning superpowers skills and unknown actions
write_executing_handoff "$ACTIVE_FEATURE"
for allow_action in "speckit.plan" "speckit.tasks" "speckit.clarify" \
                    "superpowers:test-driven-development" "some.random.action"; do
    run_guard "$allow_action"
    case "$RUN_EXIT" in
        0) ;;
        *) fail "R5: $allow_action should be allowed (exit 0); got exit $RUN_EXIT" ;;
    esac
    case "$RUN_OUTPUT" in
        *"Guard allowed"*) ;;
        *) fail "R5: $allow_action allow output missing 'Guard allowed' marker; output: $RUN_OUTPUT" ;;
    esac
done

# Default: allow when no handoff file exists.
# Move the handoff aside, run guard, assert exit 0, then restore via trap-managed backup.
if [ -f "$HANDOFF_PATH" ]; then
    mv -f "$HANDOFF_PATH" "$HANDOFF_PATH.tmp.default-allow.$$"
fi
run_guard "speckit.implement"
case "$RUN_EXIT" in
    0) ;;
    *)
        # Restore before failing so trap still finds a sensible state.
        [ -f "$HANDOFF_PATH.tmp.default-allow.$$" ] && mv -f "$HANDOFF_PATH.tmp.default-allow.$$" "$HANDOFF_PATH"
        fail "Default: guard should allow (exit 0) when no handoff file exists; got exit $RUN_EXIT"
        ;;
esac
case "$RUN_OUTPUT" in
    *"Guard allowed"*) ;;
    *)
        [ -f "$HANDOFF_PATH.tmp.default-allow.$$" ] && mv -f "$HANDOFF_PATH.tmp.default-allow.$$" "$HANDOFF_PATH"
        fail "Default: allow output missing 'Guard allowed' marker; output: $RUN_OUTPUT"
        ;;
esac
# Put the file back so the trap-based restore operates from a normal state.
if [ -f "$HANDOFF_PATH.tmp.default-allow.$$" ]; then
    mv -f "$HANDOFF_PATH.tmp.default-allow.$$" "$HANDOFF_PATH"
fi

echo "guard-hardcoded-rules-tests-ok (bash)"
