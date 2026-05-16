# Contract: Bash Port of `tests/*.ps1`

**Feature**: `009-wsl-dev-env-alignment` | **Plan**: [../plan.md](../plan.md) | **Research**: [../research.md R3](../research.md#r3--bash-idiom-inventory-for-the-four-test-ports)

This contract pins what each of the four bash ports MUST assert. The bash port is a behavioral replacement, not a transliteration: the `.ps1` original is the **assertion-contract reference**; the bash port preserves the contract using idiomatic bash. Once the bash port proves green on WSL, the `.ps1` original is deleted in the same commit (FR-007).

---

## Common contract (applies to all 4 ports)

| Property | Constraint |
|---|---|
| Shebang | `#!/usr/bin/env bash` |
| Header | `set -euo pipefail` |
| Helpers | `REPO_ROOT="$(git rev-parse --show-toplevel)"`; `assert_true()` and `fail()` defined inline at top |
| Dependency probe | First action checks `command -v jq` and `command -v bash`; exits 2 with "Missing dependency: jq" if absent |
| Cleanup | `trap` restores any handoff/snapshot file mutated during the test |
| Exit code on full pass | `0` |
| Exit code on assertion failure | non-zero, with diagnostic to stderr |
| Exit code on missing dependency | `2` |
| Final stdout line on pass | `<test-name>-ok (bash)` — matching the PS final-line convention but reporting `bash` flavor exercised |
| Skip semantics | Explicit `  [skip] <reason>` line in stdout for any assertion that cannot run; the script as a whole still exits 0 if every assertion ran-or-skipped (NO silent absence per FR-007) |
| Path translation | NONE — bash port runs natively in bash; no `cygpath` / `/mnt/<drive>` / MSYS shims |
| Cross-flavor dispatch | NONE — bash port exercises only the bash flavor of bridge scripts; cross-flavor parity is the dedicated job of `test-claude-codex-skill-parity.sh` |

---

## Port 1: `tests/test-handoff-shape.sh`

**Source**: `tests/test-handoff-shape.ps1` (190+ lines). Tests three properties of `update-handoff.sh`:

**(a) v1 write shape**

After invoking `update-handoff.sh --status executing --feature-directory specs/006-trim-to-thin-bridge --artifact-owner claude --actor claude --reason "smoke (a)"`, the resulting `.specify/superpowers-handoff.json` MUST satisfy:

| Assertion | Bash check |
|---|---|
| `schema_version == 1` | `[ "$(jq -r '.schema_version' "$h")" = "1" ]` |
| `status ∈ {ready, executing, blocked, complete}` | `case ... in ready\|executing\|blocked\|complete) ;; *) fail ;; esac` |
| `source_of_truth.constitution == ".specify/memory/constitution.md"` | `jq -re '.source_of_truth.constitution'` matches |
| `artifact_owner ∈ {codex, claude, unknown}` | `case` enum check |
| `updated_at` non-empty | `[ -n "$(jq -r '.updated_at')" ]` |
| v3-only fields ABSENT (`autonomous_mode`, `resume_context`, `archive_history`) | `for k in ...; do jq -e "has(\"$k\")" "$h" && fail "v1 write should not contain $k" ; done` |

**(b) Backward-read of v3 JSON**

After writing a synthetic v3-shape JSON to `.specify/superpowers-handoff.json` (with `schema_version=3`, `autonomous_mode=true`, `resume_context={...}`, `archive_history=[...]`) and then invoking `update-handoff.sh --status executing --actor claude --reason "smoke (b)"`, the resulting file MUST:

| Assertion | Bash check |
|---|---|
| Re-shape to `schema_version == 1` | jq check |
| Drop the v3-only fields in the new write | per-field `has` check |
| Not crash on the read (exit 0) | already enforced by `set -e` |

**(c) `artifact_owner` preservation**

When `--artifact-owner` is NOT passed and the prior handoff had `artifact_owner=claude`, the new write MUST preserve `claude`. When `--artifact-owner codex` IS passed explicitly, the new write MUST overwrite to `codex`. Two sub-assertions, both via `jq -r`.

**Skip conditions**:

- If bash version < 4.0 (no associative arrays needed but `mapfile` is — port avoids `mapfile`, so this skip likely never fires).
- If `jq` is missing → exits 2 per common contract.

---

## Port 2: `tests/test-guard-hardcoded-rules.sh`

**Source**: `tests/test-guard-hardcoded-rules.ps1`. Tests the five hardcoded guard rules described in `CLAUDE.md`:

| Rule | Bash test scenario |
|---|---|
| **R1**: Deny `speckit.implement` when handoff status == `executing` | Set handoff status to `executing`; run `guard-command.sh --action speckit.implement --actor claude`; assert exit 1 + stderr contains "denied" |
| **R2**: Deny `superpowers:writing-plans` when active feature has `plan.md` | Ensure 008's plan.md exists (it does); run `guard-command.sh --action superpowers:writing-plans --actor claude`; assert exit 1 |
| **R3**: Deny `superpowers:brainstorming` when active feature has `tasks.md` | Same setup; action = `superpowers:brainstorming`; assert exit 1 |
| **R4**: Deny `speckit.constitution` when handoff status == `executing` | Set status `executing`; action = `speckit.constitution`; assert exit 1 |
| **R5**: Allow all other `speckit.*` | Action = `speckit.plan`; assert exit 0 + stdout contains "Guard allowed" |
| **Default**: Allow on no-handoff-file | Move handoff file aside; action = any; assert exit 0 |

Per-scenario `trap` restores the prior handoff state.

**Skip conditions**:

- Bridge bash script `guard-command.sh` not present → exits 2.

---

## Port 3: `tests/test-bridge-state-summary.sh`

**Source**: `tests/test-bridge-state-summary.ps1`. Tests SC-001/SC-002/SC-003 from feature 008 — the `[bridge state]` summary block format:

| Assertion | Bash check |
|---|---|
| Every invocation of `guard-command.sh` (allow OR deny) prints a `[bridge state]` block | `output="$(guard-command.sh --action speckit.plan --actor claude 2>&1)"`; `grep -q '^\[bridge state\]$' <<< "$output"` |
| Block contains `Feature directory:` | `grep -q '^  Feature directory: ' <<< "$output"` |
| Block contains `Status: ` | `grep -q '^  Status: ' <<< "$output"` |
| Block contains `Artifact owner: ` | `grep -q '^  Artifact owner: ' <<< "$output"` |
| Block contains `Actor: ` (matching the `--actor` flag) | regex check |
| Block contains `Pending tasks: ` with a non-negative integer | regex `Pending tasks: [0-9]+` |
| Block prints on `update-handoff` invocation as well | repeat the check against `update-handoff.sh --status executing ...` |

**Skip conditions**:

- Bridge bash scripts missing → exits 2.

---

## Port 4: `tests/test-claude-codex-skill-parity.sh`

**Source**: `tests/test-claude-codex-skill-parity.ps1`. Tests that the project's own `speckit-superpowers-bridge` skill files are byte-equivalent (or specified-difference-only) between `.claude/skills/` and `.agents/skills/`:

| Assertion | Bash check |
|---|---|
| `diff -q .claude/skills/speckit-superpowers-bridge/SKILL.md .agents/skills/speckit-superpowers-bridge/SKILL.md` returns no difference OR only differences in the front-matter `name:` field (codex uses `$` prefix; claude uses `/`) | `diff` + `grep -v '^name:'` filter; fail if remaining diff is non-empty |
| Both files declare the same `description:` line | extract with `grep '^description:'`, compare |
| Both files reference the same bridge script paths (e.g., `.specify/extensions/speckit-superpowers-bridge/scripts/...`) | extract with `grep -oE '\.specify/extensions[^ ]*'` and compare sorted unique sets |

**Skip conditions**:

- Either skill file missing → fail (not skip), because the parity gate is a hard project invariant per CLAUDE.md.

---

## Marketplace docs update (R5 follow-on)

After all four ports prove green and the `.ps1` originals are deleted in their respective commits, Phase B updates:

- `marketplace/README.md:41` — replace `tests/test-*.ps1` with `tests/test-*.sh`.
- `marketplace/extension-submission-body.md:113-116` — replace each of the four `.ps1` names with the `.sh` equivalent.
- `CHANGELOG.md` — add an `## [Unreleased]` section (if not present) with a one-line entry: `- 009: ported `tests/*.ps1` → `tests/*.sh`; deleted PowerShell smoke tests after bash equivalents verified green on WSL`.

These three edits live in a single commit at the end of Phase B.

## Runner

`tests/run-all.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
for f in "$SCRIPT_DIR"/test-*.sh; do
    [ -f "$f" ] || continue
    printf '\n=== %s ===\n' "$(basename "$f")"
    if ! bash "$f"; then
        printf 'FAIL: %s\n' "$(basename "$f")" >&2
        fail=1
    fi
done
[ "$fail" -eq 0 ] || exit 1
echo
echo "All bash smoke tests passed."
```

The runner is the single SC-001 entrypoint. It also enforces the FR-007 "silent absence forbidden" rule transitively — any test file missing fails the pattern match silently, but the runner prints per-test headers so a missing test name is visually apparent in the output.
