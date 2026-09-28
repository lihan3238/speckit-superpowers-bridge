#!/usr/bin/env bash
# Validate the Spec Kit checkbox -> Superpowers 6.4.2 heading adapter contract.
# The bridge keeps this adapter ephemeral; this test exercises its required
# mapping without creating a tracked runtime surface.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
# Use a stable fixture so this contract test remains meaningful after the
# current feature's tasks.md reaches its terminal all-checked state.
TASKS="$REPO_ROOT/tests/fixtures/tasks-with-pending.md"
CODEX_SKILL="$REPO_ROOT/.agents/skills/speckit-superpowers-bridge/SKILL.md"
EXECUTE_MD="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md"

[ -f "$TASKS" ] || { echo "FAIL: missing feature tasks.md" >&2; exit 1; }
for f in "$CODEX_SKILL" "$EXECUTE_MD"; do
    grep -q '### Task N: T###' "$f" || { echo "FAIL: missing Task N adapter heading contract in $f" >&2; exit 1; }
    grep -q 'stable repository/feature-derived' "$f" || { echo "FAIL: missing stable adapter path contract in $f" >&2; exit 1; }
done

python3 - "$TASKS" <<'PY'
from pathlib import Path
import re
import sys

tasks = Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
unchecked = [line for line in tasks if re.match(r"^- \[ \] T\d{3}\b", line)]
checked = [line for line in tasks if re.match(r"^- \[x\] T\d{3}\b", line, re.I)]
assert unchecked, "fixture must contain unchecked canonical tasks"
assert all("TXXX" not in line for line in unchecked), "placeholder tasks must not enter adapter"

adapter = []
for n, line in enumerate(unchecked, 1):
    task_id = re.match(r"^- \[ \] (T\d{3})\b", line).group(1)
    adapter.extend([f"### Task {n}: {task_id}", line, ""])

text = "\n".join(adapter)
headings = re.findall(r"^#+\s+Task\s+(\d+)\s*:\s*(T\d{3})\b", text, re.M)
assert len(headings) == len(unchecked), (len(headings), len(unchecked))
assert [task_id for _, task_id in headings] == [re.match(r"^- \[ \] (T\d{3})", line).group(1) for line in unchecked]
for line in unchecked:
    assert text.count(line) == 1, line
for line in checked:
    assert line not in text, line
assert "Task 1" in text and "Task 2" in text
print(f"superpowers-adapter-contract-tests-ok ({len(headings)} mapped tasks)")
PY
