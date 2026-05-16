#!/usr/bin/env bash
set -euo pipefail

# Bash port of tests/test-bridge-state-summary.ps1 (Port 3 per
# specs/009-wsl-dev-env-alignment/contracts/tests-bash-port-contract.md).
#
# Verifies the v0.5.0 `[bridge state]` summary block contract (spec 008 FR-009,
# .specify/contracts equivalent: specs/008-bridge-hardening-0-5-0/contracts/
# bridge-state-summary.md). Both guard-command.sh and update-handoff.sh MUST
# emit the block to stdout in the documented order. Native bash only: no path
# translation, no flavor dispatch (those concerns live in
# test-claude-codex-skill-parity.sh per Port 4).

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_true() {
    # assert_true <condition-exit-code> <message>
    # Caller evaluates the predicate inline; we just check the captured exit.
    if [ "$1" -ne 0 ]; then
        fail "$2"
    fi
}

# ---------------------------------------------------------------------------
# Dependency probe
# ---------------------------------------------------------------------------

command -v jq >/dev/null 2>&1 || { printf 'Missing dependency: jq\n' >&2; exit 2; }
command -v bash >/dev/null 2>&1 || { printf 'Missing dependency: bash\n' >&2; exit 2; }
command -v git >/dev/null 2>&1 || { printf 'Missing dependency: git\n' >&2; exit 2; }

# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_BASH_DIR="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge/scripts/bash"
GUARD_SCRIPT="$BRIDGE_BASH_DIR/guard-command.sh"
UPDATE_SCRIPT="$BRIDGE_BASH_DIR/update-handoff.sh"
HANDOFF_PATH="$REPO_ROOT/.specify/superpowers-handoff.json"
EVENT_LOG_PATH="$REPO_ROOT/.specify/bridge-events.jsonl"

if [ ! -f "$GUARD_SCRIPT" ]; then
    printf 'Missing bridge script: %s\n' "$GUARD_SCRIPT" >&2
    exit 2
fi
if [ ! -f "$UPDATE_SCRIPT" ]; then
    printf 'Missing bridge script: %s\n' "$UPDATE_SCRIPT" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Snapshot & restore (so we don't pollute the live handoff or event log)
# ---------------------------------------------------------------------------

BACKUP_HANDOFF=""
HANDOFF_EXISTED=false
if [ -f "$HANDOFF_PATH" ]; then
    HANDOFF_EXISTED=true
    BACKUP_HANDOFF="$(mktemp)"
    cp -p "$HANDOFF_PATH" "$BACKUP_HANDOFF"
fi

EVENT_LOG_SIZE_BEFORE=0
if [ -f "$EVENT_LOG_PATH" ]; then
    EVENT_LOG_SIZE_BEFORE="$(wc -c <"$EVENT_LOG_PATH" | tr -d ' ')"
fi

# Provision a transient feature directory so update-handoff has spec.md+plan.md.
TEMP_FEATURE_SLUG="bridge-state-summary-$$"
TEMP_FEATURE_ABS="$REPO_ROOT/tests/fixtures/.temp-$TEMP_FEATURE_SLUG"
TEMP_FEATURE_REL="tests/fixtures/.temp-$TEMP_FEATURE_SLUG"

restore() {
    local status=$?
    if [ "$HANDOFF_EXISTED" = true ] && [ -n "$BACKUP_HANDOFF" ] && [ -f "$BACKUP_HANDOFF" ]; then
        cp -p "$BACKUP_HANDOFF" "$HANDOFF_PATH"
        rm -f "$BACKUP_HANDOFF"
    elif [ "$HANDOFF_EXISTED" = false ] && [ -f "$HANDOFF_PATH" ]; then
        rm -f "$HANDOFF_PATH"
    fi
    if [ -f "$EVENT_LOG_PATH" ]; then
        # Truncate the event log back to its pre-test length so we don't pollute audit history.
        local size_now
        size_now="$(wc -c <"$EVENT_LOG_PATH" | tr -d ' ')"
        if [ "$size_now" -gt "$EVENT_LOG_SIZE_BEFORE" ]; then
            # Use dd to truncate to exact byte length (portable across BSD/GNU).
            dd if="$EVENT_LOG_PATH" of="$EVENT_LOG_PATH.trimmed" bs=1 count="$EVENT_LOG_SIZE_BEFORE" status=none 2>/dev/null || true
            if [ -f "$EVENT_LOG_PATH.trimmed" ]; then
                mv "$EVENT_LOG_PATH.trimmed" "$EVENT_LOG_PATH"
            fi
        fi
    fi
    if [ -d "$TEMP_FEATURE_ABS" ]; then
        rm -rf "$TEMP_FEATURE_ABS"
    fi
    exit "$status"
}
trap restore EXIT INT TERM

mkdir -p "$TEMP_FEATURE_ABS"
# Minimal tasks.md so the "Pending tasks: N" line resolves to a number, not "(no tasks.md)".
cat >"$TEMP_FEATURE_ABS/tasks.md" <<'EOF'
# Tasks (test fixture)

- [ ] T001 fixture task one
- [ ] T002 fixture task two
EOF
printf '# Stub spec (test fixture)\n' >"$TEMP_FEATURE_ABS/spec.md"
printf '# Stub plan (test fixture)\n' >"$TEMP_FEATURE_ABS/plan.md"

# ---------------------------------------------------------------------------
# Assertion helper: validate the [bridge state] block against captured stdout
# ---------------------------------------------------------------------------

# assert_bridge_state_block <label> <expected_actor> <stdout-file>
assert_bridge_state_block() {
    local label="$1"
    local expected_actor="$2"
    local out_file="$3"

    grep -qE '^\[bridge state\]$' "$out_file"
    assert_true $? "$label: stdout missing literal '[bridge state]' header line"

    grep -qE '^  Feature directory: ' "$out_file"
    assert_true $? "$label: stdout missing '  Feature directory: ' line"

    grep -qE '^  Status: ' "$out_file"
    assert_true $? "$label: stdout missing '  Status: ' line"

    grep -qE '^  Artifact owner: ' "$out_file"
    assert_true $? "$label: stdout missing '  Artifact owner: ' line"

    grep -qE '^  Actor: ' "$out_file"
    assert_true $? "$label: stdout missing '  Actor: ' line"

    # The Actor line may be "Actor: <actor>" OR "Actor: <prior> → <actor>";
    # in either form the *new* actor (the --actor value we passed) must appear.
    grep -qE "^  Actor: (.* → )?${expected_actor}$" "$out_file"
    assert_true $? "$label: '  Actor:' line did not end with expected actor '${expected_actor}'"

    grep -qE '^  Pending tasks: [0-9]+$' "$out_file"
    assert_true $? "$label: stdout missing '  Pending tasks: <non-negative integer>' line"

    # R-OUT-2: enforce the documented field order. Extract just the block lines
    # (header + the five indented sub-fields) and compare against expected labels.
    local order
    order="$(grep -E '^(\[bridge state\]|  (Feature directory|Status|Artifact owner|Actor|Pending tasks): )' "$out_file" \
        | sed -E 's/^(  [A-Za-z ]+: ).*/\1/' \
        | head -n 6)"
    local expected
    expected="$(printf '%s\n' \
        '[bridge state]' \
        '  Feature directory: ' \
        '  Status: ' \
        '  Artifact owner: ' \
        '  Actor: ' \
        '  Pending tasks: ')"
    if [ "$order" != "$expected" ]; then
        fail "$label: bridge state field order incorrect. Got:
$order
Expected:
$expected"
    fi
}

# ---------------------------------------------------------------------------
# Test 1: guard-command.sh prints the [bridge state] block (allow path)
# ---------------------------------------------------------------------------

GUARD_OUT="$(mktemp)"
GUARD_ERR="$(mktemp)"
set +e
bash "$GUARD_SCRIPT" --action speckit.plan --actor claude >"$GUARD_OUT" 2>"$GUARD_ERR"
GUARD_EXIT=$?
set -e

if [ "$GUARD_EXIT" -ne 0 ]; then
    printf 'guard-command.sh stderr:\n%s\n' "$(cat "$GUARD_ERR")" >&2
    fail "guard-command.sh --action speckit.plan --actor claude exited $GUARD_EXIT (expected 0)"
fi

assert_bridge_state_block "guard/speckit.plan/claude" "claude" "$GUARD_OUT"

rm -f "$GUARD_OUT" "$GUARD_ERR"

# ---------------------------------------------------------------------------
# Test 2: update-handoff.sh prints the [bridge state] block
# ---------------------------------------------------------------------------

UPDATE_OUT="$(mktemp)"
UPDATE_ERR="$(mktemp)"
set +e
bash "$UPDATE_SCRIPT" \
    --status executing \
    --feature-directory "$TEMP_FEATURE_REL" \
    --actor claude \
    --reason "smoke" \
    >"$UPDATE_OUT" 2>"$UPDATE_ERR"
UPDATE_EXIT=$?
set -e

if [ "$UPDATE_EXIT" -ne 0 ]; then
    printf 'update-handoff.sh stderr:\n%s\n' "$(cat "$UPDATE_ERR")" >&2
    fail "update-handoff.sh --status executing --feature-directory $TEMP_FEATURE_REL --actor claude exited $UPDATE_EXIT (expected 0)"
fi

assert_bridge_state_block "update-handoff/executing/claude" "claude" "$UPDATE_OUT"

rm -f "$UPDATE_OUT" "$UPDATE_ERR"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

printf 'bridge-state-summary-tests-ok (bash)\n'
