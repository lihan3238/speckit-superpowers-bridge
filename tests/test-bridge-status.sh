#!/usr/bin/env bash
set -uo pipefail

# tests/test-bridge-status.sh — smoke tests for bridge-status.{sh,ps1} (v0.7.0+).
#
# Spec: specs/012-bridge-status-and-hash/spec.md (US1 + US2)
# Contracts:
#   specs/012-bridge-status-and-hash/contracts/bridge-status-output.md
#   specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md
#   specs/012-bridge-status-and-hash/contracts/handoff-v1.1.delta.md
#   specs/012-bridge-status-and-hash/contracts/artifact-drift-event.md
#
# This file initially covers US1 acceptance scenarios + the 6 decision-table
# vectors that do not require artifacts_sha256 (V1, V2, V3, V4, V5, V11) +
# SC-003 idempotency. US2 extensions (drift cases, V6-V10, V12-V14, S-EVT-*,
# pre-070 fixture) are appended in the US2 implementation phase.

REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_BASH_DIR="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge/scripts/bash"
BRIDGE_STATUS="$BRIDGE_BASH_DIR/bridge-status.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

pass_count=0
case_count=0
note() { printf '  %s\n' "$1"; }

run_case() {
    # Args: name body_function
    local name="$1" body="$2"
    case_count=$((case_count + 1))
    if ( "$body" ); then
        pass_count=$((pass_count + 1))
        printf '  PASS: %s\n' "$name"
    else
        printf '  FAIL: %s\n' "$name" >&2
        exit 1
    fi
}

# Build an isolated synthetic repo layout in $1 (a fresh temp directory).
#   $2 = handoff status (or "no-handoff" to skip writing it)
#   $3 = which artifacts to create (csv of {none,constitution,spec,plan,tasks,featuredir-missing})
#   $4 = OPTIONAL handoff feature_directory (default: specs/012-test/)
make_layout() {
    local root="$1" status="$2" parts_csv="$3" fd="${4:-specs/012-test}"
    mkdir -p "$root/.specify/memory" "$root/.specify"
    case ",$parts_csv," in
        *,constitution,*) : > "$root/.specify/memory/constitution.md" ;;
    esac
    case ",$parts_csv," in
        *,featuredir,*|*,spec,*|*,plan,*|*,tasks,*)
            mkdir -p "$root/$fd"
            case ",$parts_csv," in *,spec,*) : > "$root/$fd/spec.md" ;; esac
            case ",$parts_csv," in *,plan,*) : > "$root/$fd/plan.md" ;; esac
            case ",$parts_csv," in
                *,tasks,*) printf -- '- [ ] T001 sample\n- [ ] T002 sample\n- [ ] T003 sample\n' > "$root/$fd/tasks.md" ;;
            esac
            ;;
    esac
    if [ "$status" != "no-handoff" ]; then
        # Build a minimal v1 handoff document
        local fd_field="\"$fd\""
        case ",$parts_csv," in
            *,featuredir-missing,*) fd_field="\"specs/099-does-not-exist\"" ;;
        esac
        jq -n --arg status "$status" --argjson fd "$fd_field" '{
            schema_version: 1,
            updated_at: "2026-05-28T00:00:00Z",
            feature_directory: $fd,
            source_of_truth: {
                constitution: ".specify/memory/constitution.md",
                spec: "x/spec.md", plan: "x/plan.md", tasks: "x/tasks.md"
            },
            supersedes: ["speckit.implement"],
            executor: "speckit",
            capabilities: [],
            status: $status,
            blocked_reason: (if $status == "blocked" then "test block reason" else null end),
            artifact_owner: "claude",
            review_only_agents: [],
            notes: null,
            last_snapshot_id: null,
            instructions: null
        }' > "$root/.specify/superpowers-handoff.json"
    fi
}

# Run bridge-status.sh with $1 as repo dir (cd into a non-git dir so get_repo_root
# falls through to pwd). Captures stdout, stderr, exit code into $STDOUT/$STDERR/$RC.
run_bridge_status() {
    local repo="$1"; shift
    STDOUT_TMP="$(mktemp)"; STDERR_TMP="$(mktemp)"
    ( cd "$repo" && bash "$BRIDGE_STATUS" "$@" ) >"$STDOUT_TMP" 2>"$STDERR_TMP"
    RC=$?
    STDOUT="$(cat "$STDOUT_TMP")"; STDERR="$(cat "$STDERR_TMP")"
    rm -f "$STDOUT_TMP" "$STDERR_TMP"
}

assert_stdout_contains() {
    # Args: needle message
    case "$STDOUT" in
        *"$1"*) : ;;
        *) fail "$2 (stdout was: $STDOUT)" ;;
    esac
}

assert_stdout_line_equals() {
    # Args: line_substring expected_full_line message
    # Find the line containing $1 and verify exact match against $2.
    local found
    found="$(printf '%s\n' "$STDOUT" | grep -F "$1" | head -1)"
    [ "$found" = "$2" ] || fail "$3 (found: '$found' wanted: '$2')"
}

assert_rc_equals() {
    [ "$RC" = "$1" ] || fail "$2 (rc was $RC, wanted $1)"
}

assert_no_stderr() {
    [ -z "$STDERR" ] || fail "$1 (stderr had: $STDERR)"
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------

if [ ! -f "$BRIDGE_STATUS" ]; then
    fail "bridge-status.sh not yet implemented at $BRIDGE_STATUS (expected after T007 lands)"
fi
if [ ! -x "$BRIDGE_STATUS" ]; then
    fail "bridge-status.sh exists but is not executable (chmod +x missing)"
fi

# ---------------------------------------------------------------------------
# US1 — Decision-table vectors V1..V5, V11
# (per specs/012-bridge-status-and-hash/contracts/next-command-decision-table.md)
# ---------------------------------------------------------------------------

printf '\n=== US1: decision-table vectors ===\n'

# V1: bare repo, no constitution → /speckit-constitution
v1() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "no-handoff" "none"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V1 exit 0"
    assert_stdout_line_equals "Next:" "  Next: /speckit-constitution" "V1 next"
    assert_stdout_line_equals "Status:" "  Status: (no handoff)" "V1 status"
    rm -rf "$tmp"
}
run_case "V1 — no constitution → /speckit-constitution" v1

# V2: fresh checkout with constitution but no handoff → /speckit-specify
v2() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "no-handoff" "constitution"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V2 exit 0"
    assert_stdout_line_equals "Next:" "  Next: /speckit-specify" "V2 next"
    assert_stdout_line_equals "Status:" "  Status: (no handoff)" "V2 status"
    assert_stdout_line_equals "Feature directory:" "  Feature directory: (none)" "V2 feature_dir"
    rm -rf "$tmp"
}
run_case "V2 — handoff missing, constitution present → /speckit-specify" v2

# V3: spec exists, plan missing → /speckit-plan
v3() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "ready" "constitution,featuredir,spec"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V3 exit 0"
    assert_stdout_line_equals "Next:" "  Next: /speckit-plan" "V3 next"
    rm -rf "$tmp"
}
run_case "V3 — plan missing → /speckit-plan" v3

# V4: plan exists, tasks missing → /speckit-tasks
v4() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "ready" "constitution,featuredir,spec,plan"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V4 exit 0"
    assert_stdout_line_equals "Next:" "  Next: /speckit-tasks" "V4 next"
    rm -rf "$tmp"
}
run_case "V4 — tasks missing → /speckit-tasks" v4

# V5: all artifacts present, ready → start handoff
v5() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "ready" "constitution,featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V5 exit 0"
    assert_stdout_line_equals "Next:" "  Next: start handoff (update-handoff --status executing)" "V5 next"
    assert_stdout_line_equals "Pending tasks:" "  Pending tasks: 3" "V5 pending"
    rm -rf "$tmp"
}
run_case "V5 — ready with all artifacts → start handoff" v5

# V11: corrupted handoff (rule 1 wins)
v11() {
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$tmp/.specify/memory"
    : > "$tmp/.specify/memory/constitution.md"
    printf 'this is not json {' > "$tmp/.specify/superpowers-handoff.json"
    run_bridge_status "$tmp"
    assert_rc_equals 3 "V11 exit 3"
    assert_stdout_line_equals "Status:" "  Status: (corrupted handoff)" "V11 status"
    assert_stdout_line_equals "Next:" "  Next: inspect .specify/superpowers-handoff.json" "V11 next"
    rm -rf "$tmp"
}
run_case "V11 — corrupted handoff → exit 3 + inspect" v11

# ---------------------------------------------------------------------------
# US1 — Acceptance scenarios S-OUT-1, S-OUT-3, S-OUT-4
# ---------------------------------------------------------------------------

printf '\n=== US1: acceptance scenarios ===\n'

# S-OUT-3: no handoff yet (fresh checkout with constitution)
sout3() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "no-handoff" "constitution"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "S-OUT-3 exit"
    assert_stdout_line_equals "Status:" "  Status: (no handoff)" "S-OUT-3 status"
    assert_stdout_line_equals "Feature directory:" "  Feature directory: (none)" "S-OUT-3 fd"
    assert_stdout_line_equals "Pending tasks:" "  Pending tasks: (no feature_directory)" "S-OUT-3 pending"
    assert_stdout_line_equals "Next:" "  Next: /speckit-specify" "S-OUT-3 next"
    # No Drift line should appear
    case "$STDOUT" in
        *Drift*) fail "S-OUT-3 should not have Drift line (no artifacts_sha256)" ;;
    esac
    rm -rf "$tmp"
}
run_case "S-OUT-3 — fresh checkout, no handoff" sout3

# S-OUT-1: executing state, all artifacts, no drift (artifacts_sha256 absent → no Drift line)
# Note: full Drift-line behavior is tested in US2 phase where artifacts_sha256 exists.
sout1_partial() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "S-OUT-1 exit"
    assert_stdout_line_equals "Status:" "  Status: executing" "S-OUT-1 status"
    assert_stdout_line_equals "Pending tasks:" "  Pending tasks: 3" "S-OUT-1 pending"
    assert_stdout_line_equals "Next:" "  Next: continue implementation via speckit-superpowers-bridge SKILL" "S-OUT-1 next"
    rm -rf "$tmp"
}
run_case "S-OUT-1 (partial, no Drift line) — executing with all artifacts" sout1_partial

# S-OUT-4: corrupted handoff
sout4() {
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$tmp/.specify/memory"
    : > "$tmp/.specify/memory/constitution.md"
    printf '{ not closed' > "$tmp/.specify/superpowers-handoff.json"
    run_bridge_status "$tmp"
    assert_rc_equals 3 "S-OUT-4 exit"
    assert_stdout_line_equals "Status:" "  Status: (corrupted handoff)" "S-OUT-4 status"
    [ -n "$STDERR" ] || fail "S-OUT-4 stderr should carry a parse error message"
    rm -rf "$tmp"
}
run_case "S-OUT-4 — corrupted handoff returns rc 3 + stderr parse error" sout4

# ---------------------------------------------------------------------------
# US1 — SC-003 byte-identical idempotency check
# ---------------------------------------------------------------------------

printf '\n=== US1: SC-003 idempotency ===\n'

sc003() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    local handoff_path="$tmp/.specify/superpowers-handoff.json"
    local handoff_mtime_before handoff_mtime_after
    handoff_mtime_before="$(stat -c '%Y' "$handoff_path")"
    local out1 out2
    out1="$( cd "$tmp" && bash "$BRIDGE_STATUS" 2>/dev/null )"
    out2="$( cd "$tmp" && bash "$BRIDGE_STATUS" 2>/dev/null )"
    handoff_mtime_after="$(stat -c '%Y' "$handoff_path")"
    [ "$out1" = "$out2" ] || fail "SC-003 byte-identical idempotency (outputs differ)"
    [ "$handoff_mtime_before" = "$handoff_mtime_after" ] || fail "SC-003 handoff mtime changed across reads"
    [ ! -f "$tmp/.specify/bridge-events.jsonl" ] || fail "SC-003 bridge-events.jsonl was created by a read (must be append-free)"
    rm -rf "$tmp"
}
run_case "SC-003 — byte-identical across 2 reads + no writes" sc003

# ---------------------------------------------------------------------------
# US1 — Edge cases
# ---------------------------------------------------------------------------

printf '\n=== US1: edge cases ===\n'

# Edge: feature_directory missing (dangling reference, status != ready)
edge_dangling() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir-missing"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "dangling-ref exit"
    # Expect: "clear handoff or restore feature directory" (rule 5)
    assert_stdout_line_equals "Next:" "  Next: clear handoff or restore feature directory" "dangling-ref next"
    rm -rf "$tmp"
}
run_case "edge — dangling feature_directory (executing) → clear handoff" edge_dangling

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

# ===========================================================================
# US2 — Drift detection scenarios (added in US2 implementation phase)
# Tests both bridge-status drift display AND update-handoff drift event emission.
# ===========================================================================

UPDATE_HANDOFF="$BRIDGE_BASH_DIR/update-handoff.sh"

# Helper: inject a fake artifacts_sha256 block into an existing handoff JSON
inject_artifacts_sha256() {
    # Args: handoff_path spec_hash plan_hash tasks_hash
    local hp="$1" sh="$2" ph="$3" th="$4"
    local tmp; tmp="$(mktemp)"
    jq --arg sh "$sh" --arg ph "$ph" --arg th "$th" \
       '.artifacts_sha256 = {"spec.md":($sh|if .=="" then null else . end),
                              "plan.md":($ph|if .=="" then null else . end),
                              "tasks.md":($th|if .=="" then null else . end)}' \
       "$hp" > "$tmp"
    mv "$tmp" "$hp"
}

# Build a self-contained git worktree for tests that exercise update-handoff
# (because update-handoff requires `git rev-parse --show-toplevel` to resolve).
make_layout_git() {
    local root="$1" status="$2" parts_csv="$3" fd="${4:-specs/012-test}"
    make_layout "$root" "$status" "$parts_csv" "$fd"
    ( cd "$root" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -q -m init )
}

# ---- V6..V10, V12..V14 (decision-table vectors) ----

printf '\n=== US2: decision-table vectors V6-V10, V12-V14 ===\n'

v6() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V6 exit"
    assert_stdout_line_equals "Next:" "  Next: continue implementation via speckit-superpowers-bridge SKILL" "V6 next"
    rm -rf "$tmp"
}
run_case "V6 — executing → continue via bridge SKILL" v6

v7() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "complete" "constitution,featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V7 exit"
    assert_stdout_line_equals "Next:" "  Next: /speckit-specify" "V7 next"
    rm -rf "$tmp"
}
run_case "V7 — complete → /speckit-specify (start new feature)" v7

v8() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "blocked" "constitution,featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V8 exit"
    assert_stdout_line_equals "Next:" "  Next: resolve blocked_reason or rerun /speckit-clarify" "V8 next"
    rm -rf "$tmp"
}
run_case "V8 — blocked → resolve blocked_reason" v8

v9() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "ready" "constitution,featuredir-missing"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V9 exit"
    assert_stdout_line_equals "Next:" "  Next: /speckit-specify" "V9 next"
    rm -rf "$tmp"
}
run_case "V9 — ready with missing feature_dir → /speckit-specify" v9

v10() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir-missing"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V10 exit"
    assert_stdout_line_equals "Next:" "  Next: clear handoff or restore feature directory" "V10 next"
    rm -rf "$tmp"
}
run_case "V10 — executing with missing feature_dir → clear handoff" v10

v12() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "ready" "constitution,featuredir"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V12 exit"
    assert_stdout_line_equals "Next:" "  Next: /speckit-specify" "V12 next"
    rm -rf "$tmp"
}
run_case "V12 — feature_dir exists but no spec.md → /speckit-specify" v12

v13() {
    local tmp; tmp="$(mktemp -d)"
    # No constitution; executing handoff with all artifacts
    make_layout "$tmp" "executing" "featuredir,spec,plan,tasks"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "V13 exit"
    assert_stdout_line_equals "Next:" "  Next: /speckit-constitution" "V13 next (constitution missing trumps state)"
    rm -rf "$tmp"
}
run_case "V13 — no constitution + executing → /speckit-constitution" v13

# V14 is a sanity duplicate of V7 — skipping (covered by V7)

# ---- S-OUT-2: drift line shows tasks.md ----

printf '\n=== US2: bridge-status drift display ===\n'

sout2() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    local handoff="$tmp/.specify/superpowers-handoff.json"
    local spec_h plan_h tasks_h
    spec_h="$(sha256sum "$tmp/specs/012-test/spec.md" | awk '{print $1}')"
    plan_h="$(sha256sum "$tmp/specs/012-test/plan.md" | awk '{print $1}')"
    tasks_h="$(sha256sum "$tmp/specs/012-test/tasks.md" | awk '{print $1}')"
    # Inject correct snapshot
    inject_artifacts_sha256 "$handoff" "$spec_h" "$plan_h" "$tasks_h"
    # Then modify tasks.md (drift!)
    printf '\nINJECTED LINE\n' >> "$tmp/specs/012-test/tasks.md"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "S-OUT-2 exit"
    assert_stdout_line_equals "Drift:" "  Drift: tasks.md" "S-OUT-2 drift line"
    assert_no_stderr "S-OUT-2 bridge-status must not emit stderr warning (FR-007)"
    rm -rf "$tmp"
}
run_case "S-OUT-2 — drift line shows tasks.md after modification" sout2

# Drift: (none) when artifacts_sha256 present + all match
sout2_clean() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    local handoff="$tmp/.specify/superpowers-handoff.json"
    local spec_h plan_h tasks_h
    spec_h="$(sha256sum "$tmp/specs/012-test/spec.md" | awk '{print $1}')"
    plan_h="$(sha256sum "$tmp/specs/012-test/plan.md" | awk '{print $1}')"
    tasks_h="$(sha256sum "$tmp/specs/012-test/tasks.md" | awk '{print $1}')"
    inject_artifacts_sha256 "$handoff" "$spec_h" "$plan_h" "$tasks_h"
    run_bridge_status "$tmp"
    assert_rc_equals 0 "S-OUT-2-clean exit"
    assert_stdout_line_equals "Drift:" "  Drift: (none)" "S-OUT-2-clean drift line"
    rm -rf "$tmp"
}
run_case "S-OUT-2-clean — drift line shows (none) when all match" sout2_clean

# S-OUT-5: JSON drift output
sout5() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    local handoff="$tmp/.specify/superpowers-handoff.json"
    local spec_h plan_h tasks_h
    spec_h="$(sha256sum "$tmp/specs/012-test/spec.md" | awk '{print $1}')"
    plan_h="$(sha256sum "$tmp/specs/012-test/plan.md" | awk '{print $1}')"
    tasks_h="$(sha256sum "$tmp/specs/012-test/tasks.md" | awk '{print $1}')"
    inject_artifacts_sha256 "$handoff" "$spec_h" "$plan_h" "$tasks_h"
    printf '\nINJECTED\n' >> "$tmp/specs/012-test/tasks.md"
    run_bridge_status "$tmp" --json
    assert_rc_equals 0 "S-OUT-5 exit"
    # Parse the JSON and check fields
    local detected artifacts next
    detected="$(printf '%s' "$STDOUT" | jq -r '.drift.detected')"
    artifacts="$(printf '%s' "$STDOUT" | jq -r '.drift.artifacts | join(",")')"
    next="$(printf '%s' "$STDOUT" | jq -r '.next')"
    [ "$detected" = "true" ] || fail "S-OUT-5 drift.detected (got: $detected)"
    [ "$artifacts" = "tasks.md" ] || fail "S-OUT-5 drift.artifacts (got: $artifacts)"
    [ "$next" = "continue implementation via speckit-superpowers-bridge SKILL" ] || fail "S-OUT-5 next (got: $next)"
    rm -rf "$tmp"
}
run_case "S-OUT-5 — JSON mode emits drift + next correctly" sout5

# FR-007: bridge-status does NOT append to bridge-events.jsonl
fr007() {
    local tmp; tmp="$(mktemp -d)"
    make_layout "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    local handoff="$tmp/.specify/superpowers-handoff.json"
    local spec_h plan_h tasks_h
    spec_h="$(sha256sum "$tmp/specs/012-test/spec.md" | awk '{print $1}')"
    plan_h="$(sha256sum "$tmp/specs/012-test/plan.md" | awk '{print $1}')"
    tasks_h="$(sha256sum "$tmp/specs/012-test/tasks.md" | awk '{print $1}')"
    inject_artifacts_sha256 "$handoff" "$spec_h" "$plan_h" "$tasks_h"
    printf '\nINJECTED\n' >> "$tmp/specs/012-test/tasks.md"
    # bridge-events.jsonl absent or empty before
    local before_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && before_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    run_bridge_status "$tmp"
    run_bridge_status "$tmp"
    local after_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && after_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    [ "$before_lines" = "$after_lines" ] || fail "FR-007 bridge-status appended to events ($before_lines -> $after_lines)"
    rm -rf "$tmp"
}
run_case "FR-007 — bridge-status with drift does not append events" fr007

# ---- Pre-070 fixture compat (FR-013 + SC-009) ----

printf '\n=== US2: backward-compat (FR-013 / SC-009) ===\n'

fr013() {
    local tmp; tmp="$(mktemp -d)"
    mkdir -p "$tmp/.specify/memory"
    : > "$tmp/.specify/memory/constitution.md"
    cp "$REPO_ROOT/tests/fixtures/pre-070-handoff.json" "$tmp/.specify/superpowers-handoff.json"
    # The fixture's feature_directory points at a non-existent dir; that's the
    # whole point — exercise FR-013 reader-tolerance even with dangling refs.
    run_bridge_status "$tmp"
    assert_rc_equals 0 "FR-013 exit"
    # No Drift line should appear (handoff has no artifacts_sha256)
    case "$STDOUT" in
        *Drift*) fail "FR-013 pre-070 handoff must not have Drift line (no artifacts_sha256)" ;;
    esac
    assert_no_stderr "FR-013 pre-070 read must not warn"
    rm -rf "$tmp"
}
run_case "FR-013 — pre-070 fixture tolerated (no crash, no false-positive drift)" fr013

# ---- update-handoff: S-EVT-1, S-EVT-5, S-EVT-6 ----

printf '\n=== US2: update-handoff drift events (S-EVT-*) ===\n'

# S-EVT-5: no drift → no event
sevt5() {
    local tmp; tmp="$(mktemp -d)"
    make_layout_git "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    # Manually move the handoff feature_directory to match what's on disk
    # (the layout uses specs/012-test which exists)
    # First, snapshot via update-handoff to populate artifacts_sha256
    ( cd "$tmp" && bash "$UPDATE_HANDOFF" --status executing --feature-directory specs/012-test --actor claude --reason "snap" >/dev/null 2>&1 )
    # No changes to artifacts → complete write should NOT emit drift
    local before_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && before_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    local out err
    out="$( cd "$tmp" && bash "$UPDATE_HANDOFF" --status complete --actor claude --reason "done" 2>/tmp/bridge-stderr-$$ )" || true
    err="$(cat /tmp/bridge-stderr-$$)"; rm -f /tmp/bridge-stderr-$$
    local after_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && after_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    local added=$((after_lines - before_lines))
    # Expect exactly 1 new handoff event, NO artifact_drift_detected event
    local drift_lines
    drift_lines="$(tail -n "$added" "$tmp/.specify/bridge-events.jsonl" | grep -c 'artifact_drift_detected' || true)"
    [ "$drift_lines" = "0" ] || fail "S-EVT-5 expected 0 drift events, got $drift_lines"
    case "$err" in
        *"artifact drift"*) fail "S-EVT-5 expected no drift stderr, got: $err" ;;
    esac
    rm -rf "$tmp"
}
run_case "S-EVT-5 — no drift on complete → no event, no warning" sevt5

# S-EVT-1: single-artifact drift
sevt1() {
    local tmp; tmp="$(mktemp -d)"
    make_layout_git "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    ( cd "$tmp" && bash "$UPDATE_HANDOFF" --status executing --feature-directory specs/012-test --actor claude --reason "snap" >/dev/null 2>&1 )
    # Modify tasks.md
    printf '\nINJECTED DRIFT\n' >> "$tmp/specs/012-test/tasks.md"
    local err
    ( cd "$tmp" && bash "$UPDATE_HANDOFF" --status complete --actor claude --reason "done" 2>/tmp/bridge-stderr-$$ >/dev/null ) || true
    err="$(cat /tmp/bridge-stderr-$$)"; rm -f /tmp/bridge-stderr-$$
    case "$err" in
        *"artifact drift since executing snapshot: tasks.md"*) : ;;
        *) fail "S-EVT-1 expected drift stderr for tasks.md, got: $err" ;;
    esac
    # Event log must have exactly one artifact_drift_detected entry
    local drift_count
    drift_count="$(grep -c 'artifact_drift_detected' "$tmp/.specify/bridge-events.jsonl")"
    [ "$drift_count" = "1" ] || fail "S-EVT-1 expected 1 drift event, got $drift_count"
    # Verify the event payload shape
    local payload
    payload="$(grep 'artifact_drift_detected' "$tmp/.specify/bridge-events.jsonl" | tail -1)"
    printf '%s' "$payload" | jq -e '.event=="artifact_drift_detected" and .drifted_artifacts[0].path=="tasks.md" and (.drifted_artifacts[0].new_sha256 | length == 64)' >/dev/null \
        || fail "S-EVT-1 event payload shape (got: $payload)"
    rm -rf "$tmp"
}
run_case "S-EVT-1 — single-artifact drift → stderr warning + event with correct shape" sevt1

# S-EVT-6: pre-070 handoff (no artifacts_sha256) → no false-positive on complete
sevt6() {
    local tmp; tmp="$(mktemp -d)"
    make_layout_git "$tmp" "executing" "constitution,featuredir,spec,plan,tasks"
    # Remove artifacts_sha256 if any (simulate pre-070 doc)
    local handoff="$tmp/.specify/superpowers-handoff.json"
    # The layout-built handoff has no artifacts_sha256 yet, so this is already pre-070.
    local before_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && before_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    local err
    ( cd "$tmp" && bash "$UPDATE_HANDOFF" --status complete --actor claude --reason "done" 2>/tmp/bridge-stderr-$$ >/dev/null ) || true
    err="$(cat /tmp/bridge-stderr-$$)"; rm -f /tmp/bridge-stderr-$$
    case "$err" in
        *"artifact drift"*) fail "S-EVT-6 must NOT emit drift warning on pre-070 handoff (got: $err)" ;;
    esac
    local after_lines=0
    [ -f "$tmp/.specify/bridge-events.jsonl" ] && after_lines="$(wc -l < "$tmp/.specify/bridge-events.jsonl")"
    local added=$((after_lines - before_lines))
    local drift_lines=0
    if [ "$added" -gt 0 ]; then
        drift_lines="$(tail -n "$added" "$tmp/.specify/bridge-events.jsonl" | grep -c 'artifact_drift_detected' || true)"
    fi
    [ "$drift_lines" = "0" ] || fail "S-EVT-6 expected 0 drift events on pre-070, got $drift_lines"
    rm -rf "$tmp"
}
run_case "S-EVT-6 — pre-070 handoff (no artifacts_sha256) → no false-positive on complete" sevt6

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------

printf '\n=== test-bridge-status.sh: %d/%d passed ===\n' "$pass_count" "$case_count"
[ "$pass_count" -eq "$case_count" ] || exit 1
exit 0

