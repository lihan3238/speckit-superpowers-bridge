#!/usr/bin/env bash
# Smoke test for the v1 handoff schema (FR-006 + FR-009), bash port of
# tests/test-handoff-shape.ps1 (009-wsl-dev-env-alignment, Port 1).
#
# Covers, for the bash flavor of update-handoff only:
#   (a) update-handoff.sh writes a JSON document matching the v1 shape
#   (b) reading a fabricated v3-shape handoff does not error, and the new
#       write does not echo back v3-only fields
#   (c) artifact_owner is preserved when --artifact-owner is omitted, and
#       overridden when it is provided explicitly
set -euo pipefail

# ---------- helpers ----------
fail() {
    printf 'ASSERTION FAILED: %s\n' "$1" >&2
    exit 1
}

assert_true() {
    # assert_true <condition-as-shell-eval-string> <message>
    if ! eval "$1"; then
        fail "$2"
    fi
}

# ---------- dependency probe ----------
if ! command -v jq >/dev/null 2>&1; then
    printf 'Missing dependency: jq\n' >&2
    exit 2
fi
if ! command -v bash >/dev/null 2>&1; then
    printf 'Missing dependency: bash\n' >&2
    exit 2
fi

# ---------- paths ----------
REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_ROOT="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge"
UPDATE_BASH_SCRIPT="$BRIDGE_ROOT/scripts/bash/update-handoff.sh"
HANDOFF_PATH="$REPO_ROOT/.specify/superpowers-handoff.json"

if [ ! -f "$UPDATE_BASH_SCRIPT" ]; then
    printf 'Bridge bash script missing: %s\n' "$UPDATE_BASH_SCRIPT" >&2
    exit 2
fi

# ---------- snapshot + cleanup ----------
BACKUP_FILE=""
if [ -f "$HANDOFF_PATH" ]; then
    BACKUP_FILE="$(mktemp)"
    cp "$HANDOFF_PATH" "$BACKUP_FILE"
fi

cleanup() {
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$HANDOFF_PATH"
        rm -f "$BACKUP_FILE"
    fi
}
trap cleanup EXIT

# ---------- invoker (bash flavor only) ----------
invoke_update_handoff() {
    bash "$UPDATE_BASH_SCRIPT" "$@" >/dev/null
}

flavor="bash"

# ---------- (a) v1 write shape ----------
invoke_update_handoff \
    --status executing \
    --feature-directory specs/006-trim-to-thin-bridge \
    --artifact-owner claude \
    --actor claude \
    --reason "smoke (a)"

[ -f "$HANDOFF_PATH" ] || fail "[$flavor] (a) handoff file not created"

schema_version="$(jq -r '.schema_version // empty' "$HANDOFF_PATH")"
[ "$schema_version" = "1" ] || fail "[$flavor] (a) schema_version should be 1, got '$schema_version'"

status_val="$(jq -r '.status // empty' "$HANDOFF_PATH")"
case "$status_val" in
    ready|executing|blocked|complete) ;;
    *) fail "[$flavor] (a) status not in v1 enum, got '$status_val'" ;;
esac

assert_true 'jq -e "has(\"source_of_truth\")" "$HANDOFF_PATH" >/dev/null' \
    "[$flavor] (a) source_of_truth missing"

constitution="$(jq -r '.source_of_truth.constitution // empty' "$HANDOFF_PATH")"
[ "$constitution" = ".specify/memory/constitution.md" ] \
    || fail "[$flavor] (a) constitution path wrong, got '$constitution'"

owner="$(jq -r '.artifact_owner // empty' "$HANDOFF_PATH")"
case "$owner" in
    codex|claude|unknown) ;;
    *) fail "[$flavor] (a) artifact_owner not in v1 enum, got '$owner'" ;;
esac

updated_at="$(jq -r '.updated_at // empty' "$HANDOFF_PATH")"
[ -n "$updated_at" ] || fail "[$flavor] (a) updated_at missing"

for dropped in autonomous_mode resume_context archive_history; do
    if jq -e --arg k "$dropped" 'has($k)' "$HANDOFF_PATH" >/dev/null; then
        fail "[$flavor] (a) v1 write should not contain v3 field: $dropped"
    fi
done

# ---------- (b) backward-read of v3 JSON ----------
jq -n '{
    schema_version: 3,
    updated_at: "2026-05-15T00:00:00Z",
    feature_directory: "specs/006-trim-to-thin-bridge",
    source_of_truth: {
        constitution: ".specify/memory/constitution.md",
        spec: "specs/006-trim-to-thin-bridge/spec.md",
        plan: "specs/006-trim-to-thin-bridge/plan.md",
        tasks: "specs/006-trim-to-thin-bridge/tasks.md"
    },
    executor: "superpowers",
    status: "executing",
    artifact_owner: "claude",
    autonomous_mode: true,
    resume_context: { last_task: "Tsmoke" },
    archive_history: [ { feature_directory: "specs/005-marketplace-alignment" } ]
}' > "$HANDOFF_PATH"

# Reading via update-handoff must NOT throw on v3-only fields.
invoke_update_handoff \
    --status executing \
    --actor claude \
    --reason "smoke (b)"

post_schema="$(jq -r '.schema_version // empty' "$HANDOFF_PATH")"
[ "$post_schema" = "1" ] || fail "[$flavor] (b) post-write schema_version should be 1, got '$post_schema'"

for dropped in autonomous_mode resume_context archive_history; do
    if jq -e --arg k "$dropped" 'has($k)' "$HANDOFF_PATH" >/dev/null; then
        fail "[$flavor] (b) after reading v3, new write echoed back v3 field: $dropped"
    fi
done

# ---------- (c) artifact_owner preservation ----------
write_synthetic_v1() {
    jq -n '{
        schema_version: 1,
        updated_at: "2026-05-15T00:00:00Z",
        feature_directory: "specs/006-trim-to-thin-bridge",
        source_of_truth: {
            constitution: ".specify/memory/constitution.md",
            spec: "specs/006-trim-to-thin-bridge/spec.md",
            plan: "specs/006-trim-to-thin-bridge/plan.md",
            tasks: "specs/006-trim-to-thin-bridge/tasks.md"
        },
        executor: "superpowers",
        status: "executing",
        artifact_owner: "claude"
    }' > "$HANDOFF_PATH"
}

# (c.1) implicit preservation: --actor codex but NO --artifact-owner
write_synthetic_v1
invoke_update_handoff \
    --status executing \
    --actor codex \
    --reason "smoke (c) implicit preservation"

preserved="$(jq -r '.artifact_owner // empty' "$HANDOFF_PATH")"
[ "$preserved" = "claude" ] \
    || fail "[$flavor] (c) artifact_owner should preserve prior 'claude', got '$preserved'"

# (c.2) explicit override: --artifact-owner codex
write_synthetic_v1
invoke_update_handoff \
    --status executing \
    --actor codex \
    --artifact-owner codex \
    --reason "smoke (c) explicit override"

overridden="$(jq -r '.artifact_owner // empty' "$HANDOFF_PATH")"
[ "$overridden" = "codex" ] \
    || fail "[$flavor] (c) explicit --artifact-owner codex should override prior, got '$overridden'"

# ---------- pass ----------
printf 'handoff-shape-tests-ok (bash)\n'
exit 0
