#!/usr/bin/env bash
# tests/run-all.sh — single SC-001 entrypoint for the bash smoke-test suite.
# Runs every tests/test-*.sh sequentially, printing a header per test.
# Exits non-zero if any test fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail=0
ran=0

for f in "$SCRIPT_DIR"/test-*.sh; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    printf '\n=== %s ===\n' "$name"
    if bash "$f"; then
        ran=$((ran + 1))
    else
        printf 'FAIL: %s\n' "$name" >&2
        fail=1
    fi
done

echo
if [ "$ran" -eq 0 ]; then
    echo "No tests found under $SCRIPT_DIR (pattern: test-*.sh)."
    exit 1
fi
if [ "$fail" -eq 0 ]; then
    echo "All $ran bash smoke tests passed."
    exit 0
fi
echo "One or more tests FAILED — see output above."
exit 1
