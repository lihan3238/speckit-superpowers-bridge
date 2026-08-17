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
#      hook (which blocks speckit.implement) and self-block.

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
    grep -q 'after it transitions to `complete`' "$f" \
        || fail "$label: missing after_implement ordering (fires after complete)"
}

check_file "$EXECUTE_MD" "execute.md"
check_file "$CODEX_SKILL" ".agents SKILL.md"
check_file "$CLAUDE_SKILL" ".claude SKILL.md"

echo "implement-hooks-dispatch-tests-ok (bash)"
