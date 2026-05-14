# Validation Pass Contract

**Feature**: 004-polish-and-publish
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1`
**Slash command (Claude)**: `/speckit-superpowers-validate`
**Codex command**: `$speckit-superpowers-validate`
**Internal Spec Kit command ID**: `speckit.superpowers.validate`

## Purpose

End-to-end check that the bridge's documented happy path works on the current host. Produces a deterministic pass/fail report; emits Compatibility Gap Records for any deviation. SC-005 / SC-006 are this script's acceptance criteria.

## Synopsis

```
validation-pass.ps1 [-Json] [-Strict] [-Actor <codex|claude|unknown>] [-FeatureDirectory <path>]
```

| Param | Default | Meaning |
|---|---|---|
| `-FeatureDirectory` | resolved from `.specify/feature.json` | Which feature to validate against (the docs say `specs/<feature>/spec.md` etc. exist for this one). |
| `-Json` | off | Emit a single JSON Validation Pass Report on stdout. Otherwise human-readable per-step summary. |
| `-Strict` | off | Treat P2 findings as failure. |
| `-Actor` | resolved per common-actor-resolution.ps1 | Recorded on bridge events. |

## Steps performed (in order)

| # | Step | Check | Failure → severity |
|---|---|---|---|
| 1 | Read `.specify/superpowers-handoff.json` | exists, parses, schema_version ∈ {2,3} | P0 |
| 2 | Read disposition matrix + verified-versions | both files exist + parse | P0 |
| 3 | Run `parity-check.ps1 -Json` | exit 0 | severity = parity-check's worst severity |
| 4 | Run `audit-install-state.ps1 -Json` | exit 0 | severity = audit's worst severity |
| 5 | Check feature artifacts present | constitution.md, `<feat>/spec.md`, `<feat>/plan.md`, `<feat>/tasks.md` exist | P0 |
| 6 | Read `bridge-events.jsonl` for the last 24h | at least one `skill_invocation` event AND it has all required fields | P1 (`skill_invocations_absent`) |
| 7 | Verify Superpowers skill invocation coverage | for the current feature's tasks, at least one `skill_invocation` event per declared phase (before-implementation-task, before-phase-completion, before-feature-completion) | P1 (`skill_phase_uncovered`) |
| 8 | Verify the bridge SKILL.md content explicitly enumerates Superpowers invocations | regex match against canonical phrases in `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` | P1 (`bridge_skill_missing_explicit_invocation`) |
| 9 | Run the full `test-bridge-guard.ps1` smoke suite | exits 0 | P1 (`bridge_guard_tests_failed`) |
| 10 | Emit a final `feature_validation_pass` event if everything green | success | informational |

## Outputs

### stdout (`-Json`)

```json
{
  "schema_version": 1,
  "generated_at": "...",
  "feature_directory": "specs/004-polish-and-publish",
  "steps": [{"step": "handoff-state", "passed": true, "details": "..."}, ...],
  "findings": [...],
  "summary": {"total": 0, "by_severity": {"P0":0,"P1":0,"P2":0,"P3":0}},
  "exit_code": 0
}
```

### stdout (default)

One line per step, with PASS/FAIL prefix and details on failure.

### Exit codes

Same convention as audit + parity-check.

## Side effects

- Appends one `validation_pass` bridge event per run (action = `validation_pass`, decision = `pass`/`fail`, reason = summary).
- On failure: appends one CG row per finding to `specs/<feature>/compat-gaps.md` (using the existing CG record schema). Idempotent: if a CG with the same `code`+`target` is already present and OPEN, the script does NOT duplicate it — it just notes "previously logged".

## Performance

Target: under 10 minutes on this repository per SC-005. Most of the budget is parity-check (≤30s) + audit (≤5s) + test-bridge-guard.ps1 (≤30s); the remaining time is for event-log walking and CG dedup.

## Testing

`tests/test-validation-pass.ps1` (note: this is a meta-test that the validation-pass script ITSELF runs correctly) covers:
- Synthetic missing-phase: temporarily delete the last 100 lines of `bridge-events.jsonl` so the `skill_invocation` count is 0 → expect P1 + `skill_invocations_absent` finding; restore in `finally`.
- Synthetic broken bridge SKILL.md: temporarily remove the "Skill" invocation phrases from the bridge SKILL.md → expect P1 + `bridge_skill_missing_explicit_invocation`; restore.
- Idempotency: run twice in succession; the second run must not duplicate CG records.

## How the validation pass fits the broader bridge lifecycle

- Triggered manually at any point: `/speckit-superpowers-validate`.
- Triggered automatically by the after_implement hook (when added): the bridge's "before declaring complete" step calls this script; non-zero exit blocks completion.
- The compat-gaps.md it appends to is the same file feature 002 established; same schema; same CG-NNN ID series continues.
