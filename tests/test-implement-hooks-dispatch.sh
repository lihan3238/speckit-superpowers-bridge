#!/usr/bin/env bash
# tests/test-implement-hooks-dispatch.sh
#
# Feature 017 — the bridge must fire speckit.implement's `before_implement` /
# `after_implement` extension hooks so user/third-party hooks stay plug-and-play.
#
# This is a markdown-instruction surface (mirroring Spec Kit's own `implement`
# command, which dispatches hooks purely through agent instructions), so the
# smoke test asserts the instruction contract is present and correct across the
# authoritative command file and both per-agent skill peers:
#
#   1. every file references `before_implement` AND `after_implement`;
#   2. every file carries the skip-own-guard rule (extension is
#      `speckit-superpowers-bridge`) so the bridge does not fire its own guard
#      hook (which blocks speckit.implement) and self-block;
#   3. mandatory hooks emit Spec Kit's EXECUTE_COMMAND directive, are actually
#      invoked, and are awaited;
#   4. after_implement runs before the handoff becomes complete, so a failed
#      mandatory post-hook cannot leave a false-success state.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_ROOT="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

EXECUTE_MD="$BRIDGE_ROOT/commands/speckit.speckit-superpowers-bridge.execute.md"
CODEX_SKILL="$REPO_ROOT/.agents/skills/speckit-superpowers-bridge/SKILL.md"
CLAUDE_SKILL="$REPO_ROOT/.claude/skills/speckit-superpowers-bridge/SKILL.md"

for f in "$EXECUTE_MD" "$CODEX_SKILL" "$CLAUDE_SKILL"; do
    [ -f "$f" ] || fail "missing file: $f"
done

check_file() {
    local f="$1"
    local label="$2"
    grep -q 'before_implement' "$f" \
        || fail "$label: missing 'before_implement' reference"
    grep -q 'after_implement' "$f" \
        || fail "$label: missing 'after_implement' reference"
    grep -q 'Skip any hook whose `extension` is `speckit-superpowers-bridge`' "$f" \
        || fail "$label: missing skip-own-guard rule (extension is speckit-superpowers-bridge)"
    grep -q 'before the handoff transitions to `executing`' "$f" \
        || fail "$label: missing before_implement ordering (fires before executing)"
    grep -q 'EXECUTE_COMMAND: <dotted-command-id>' "$f" \
        || fail "$label: missing Spec Kit mandatory-hook EXECUTE_COMMAND directive"
    grep -q '\*\*Automatic Pre-Hook\*\*' "$f" \
        || fail "$label: missing Spec Kit automatic pre-hook block"
    grep -q '\*\*Automatic Hook\*\*' "$f" \
        || fail "$label: missing Spec Kit automatic post-hook block"
    grep -q 'Executing: `/<dotted-command-id>`' "$f" \
        || fail "$label: missing automatic-hook executing line"
    grep -q 'Actually invoke the rendered agent command and wait for its result' "$f" \
        || fail "$label: missing actual invocation-and-wait requirement"
    grep -q 'Dispatch `after_implement` before transitioning the handoff to `complete`' "$f" \
        || fail "$label: missing post-hook-before-complete ordering"
    grep -q 'If a mandatory `after_implement` hook fails, do not transition the handoff to `complete`' "$f" \
        || fail "$label: missing mandatory post-hook failure-state guarantee"
    if grep -q 'after it transitions to `complete`' "$f"; then
        fail "$label: retains obsolete after-complete hook ordering"
    fi
}

check_file "$EXECUTE_MD" "execute.md"
check_file "$CODEX_SKILL" ".agents SKILL.md"
check_file "$CLAUDE_SKILL" ".claude SKILL.md"

echo "implement-hooks-dispatch-tests-ok (bash)"
