# Phase 0 Research: Bridge Status Command + SHA256 Handoff Artifact Hash

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Date**: 2026-05-28

This file records the seven decision points that needed concrete research before Phase 1 design. Each decision is recorded in the canonical Decision / Rationale / Alternatives form. No NEEDS CLARIFICATION markers remained after the spec; this file resolves the remaining *technical* unknowns that the spec deliberately left unspecified (per "what" vs "how" separation).

## D1 — Cross-flavor SHA256 tool choice

**Decision**: Use **`sha256sum`** on bash (GNU coreutils, present everywhere we already require `jq`) and **`Get-FileHash -Algorithm SHA256`** on PowerShell (built-in since PowerShell 4.0 — well below the 5.1 floor). Normalize output to lowercase hex with no `sha256:` prefix and no filename suffix.

**Rationale**: Both tools are already part of the runtime environment the bridge has assumed since v0.5.0 (009 WSL bash alignment + Windows PowerShell 5.1+). Verified locally: `sha256sum --version` → `sha256sum (GNU coreutils) 9.4`. Lowercase hex is the de-facto JSON convention and is what `sha256sum` emits natively; PowerShell's `Get-FileHash` emits uppercase, requiring one `.ToLower()` call. No external libraries, no platform forks, no Python subprocess.

**Alternatives considered**:

- `openssl dgst -sha256` (bash) + `[System.Security.Cryptography.SHA256]::Create()` (PowerShell): more verbose, openssl is not guaranteed on minimal containers but is on WSL Ubuntu. Rejected — `sha256sum` is leaner and matches the existing tooling baseline.
- Embedding a SHA256 routine in pure bash: rejected outright; reinventing crypto inside shell is a maintenance and correctness liability.
- Python one-liner via `python3 -c`: rejected; adds a Python runtime assumption that the current scripts do not make.
- Skipping verification by storing file *size* + *mtime* instead of hash: rejected; mtime moves on touch, size can match by coincidence, and the spec explicitly requires SHA256 per the Comet precedent.

## D2 — Schema evolution: additive field vs. version bump

**Decision**: Treat `artifacts_sha256` as a purely **additive optional field** on schema_version=1. No schema_version bump. The v1 schema's `additionalProperties: true` clause at line 7 of [handoff.v1.schema.json](../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json) is the intended extension point. Update the schema doc in place to *declare* the field (so a reader using strict validation knows it's recognized), but keep `additionalProperties: true` and the existing `required:` list unchanged.

**Rationale**: The 006 trim explicitly designed the v1 schema to tolerate additive fields without version bumps — the integer-range `schema_version: 1..3` and `additionalProperties: true` exist precisely so that the project can add fields like this without re-versioning the world. Bumping to v4 would force every reader to update their schema-version range, which is more invasive than the change deserves. Existing v1/v2/v3 readers see the new field as a tolerated extra; new v0.7.0+ writers continue to emit `schema_version: 1`.

**Alternatives considered**:

- Bump `schema_version` to 4 and add `artifacts_sha256` to `required` when status is executing/complete: rejected — forces a coordinated reader update across all bridge scripts and any external consumers; SC-009 (pre-0.7.0 handoff tolerance) becomes harder to test; benefit (strict validation) is small at our scale.
- Store hashes in a sibling file (`.specify/superpowers-handoff.sha256.json`): rejected — Constitution Principle I "smallest diff", FR-010 "zero new state files", and SC-010 (f) "exactly two new files in the bridge package per flavor (bridge-status + the new test)" all push against a new file. The hashes belong to the handoff conceptually; co-locating them eliminates a class of "two files out of sync" bugs.
- Store hashes inside `bridge-events.jsonl` only (not on handoff): rejected — bridge-status needs to read drift on demand; scanning the entire event log for the most recent snapshot per file is O(N) per invocation and incompatible with the SC-001 < 1s budget for non-trivial event logs.

## D3 — Decision-table source: code vs. data

**Decision**: Encode the Next-command decision table **inline in both flavors as a sequence of conditional branches** (case/if in bash, switch/if in PowerShell) keyed off a small set of booleans + the handoff status enum. Mirror the table verbatim across flavors. Publish the canonical table in [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md) — humans read the doc; scripts implement the doc.

**Rationale**: A separate YAML/JSON data file would be Principle VI-illegal new state surface (SC-010 (g)) and would require a parser at runtime. The decision table is small enough (≤ 12 cells per exhaustive analysis — see [next-command-decision-table.md](./contracts/next-command-decision-table.md)) that inline branches are clear, fast, and trivially testable. Same approach as the 5 guard rules in `guard-command.{sh,ps1}` — they're hardcoded for exactly the same reasons (AGENTS.md "Guard rules"). Cross-flavor consistency is verified by the smoke test exhaustiveness check (SC-004).

**Alternatives considered**:

- External YAML/JSON decision-table file: rejected — adds a new state file (SC-010 (g) violation), requires a parser, and creates a "table got edited but scripts forgot to re-read" failure mode.
- Looking up next command from `.specify/extensions.yml` hook chains: rejected — `extensions.yml` declares hooks, not recommendations; semantic overload would confuse maintainers.
- Returning *multiple* recommendations and letting the user pick: rejected — `bridge-status` is a "tell me what to do next" tool; ambiguity defeats its purpose. The spec's SC-001 (< 1s recovery) implies a single recommendation.

## D4 — Print contract: who emits the new `Drift:` and `Next:` lines?

**Decision**: Only **`bridge-status`** emits the new lines. `update-handoff` and `guard-command` continue to emit the existing 5-line `[bridge state]` block from feature 008 unchanged. This preserves SC-008 (no regression in the 008 print contract) and matches the FR-006/FR-007 asymmetry: writes surface drift via stderr + event log; reads surface drift via stdout `Drift:` line.

The shared `bridge-state.{sh,ps1}` helper that produces the print block accepts a new optional argument (e.g., `--with-recommendation`) that turns on the additional lines. `bridge-status` always passes it; `update-handoff` and `guard-command` never do.

**Rationale**: The 008 contract at R-OUT-2 lists the *five required fields in order*. Adding optional lines after the block is backward-compatible only if existing callers do not start emitting them — otherwise downstream automation parsing the 008 contract sees extra unannounced output. Gating via a helper argument keeps the existing callers' output byte-identical to v0.5.0+ and concentrates the new behavior in the single new caller. The bridge-status caller is a fresh contract surface that *starts* with the 7-line shape, so no compatibility concern there.

This is also the cleanest way to enforce FR-007's read-only constraint: bridge-status calls the print helper with the recommendation flag *and* the drift-comparison flag; update-handoff calls the print helper without either (writes have their own drift code path that emits stderr + event).

**Alternatives considered**:

- Add the new lines to all three callers: rejected — silently breaks the 008 print contract for downstream automation (SC-008 violation).
- Add only `Next:` (not `Drift:`) to all three, and keep `Drift:` exclusive to bridge-status: rejected — inconsistent and makes the decision table run on every guard check (small cost but unnecessary).
- Make the new lines opt-in via env var on the existing callers: rejected — adds a discoverability problem and a second test surface for the same callers.

## D5 — JSON output mode (`--json` / `-Json`)

**Decision**: Both flavors accept a `--json` (bash) / `-Json` (PowerShell) flag that emits a single JSON object on stdout in place of the human block. Shape:

```json
{
  "feature_directory": "specs/012-bridge-status-and-hash" or null,
  "status": "ready|executing|complete|blocked|no_handoff|corrupted_handoff",
  "artifact_owner": "claude|codex|unknown|null",
  "actor": "claude|codex|human|null",
  "pending_tasks": 12 or null,
  "drift": {"detected": false, "artifacts": []} or null,
  "next": "/speckit-plan" or "(none)",
  "exit_code": 0
}
```

`drift` is `null` (not `{}`) when the handoff lacks `artifacts_sha256`. `actor` is sourced from the most recent `handoff` event entry in `bridge-events.jsonl` (matching update-handoff's existing logic); `null` when no handoff event exists yet.

**Rationale**: A machine-readable output mode is essential for any future tooling that wants to consume the status — and even today, it makes the smoke test simpler (assert structured fields rather than parse human text). Field names are snake_case to match the existing event log entries. Including the exit_code as a body field as well as the process exit code lets downstream automation log it without a separate capture step. Keeping the JSON shape isomorphic to the human block (one field per printed line) keeps the spec → contract → test → docs alignment trivial.

**Alternatives considered**:

- Pretty-printed multi-line JSON: rejected — single-line JSON is what every existing JSONL consumer expects; pretty-print is for `bridge-status --json | jq`.
- TSV/CSV output: rejected — modern tooling expects JSON.
- Mode-shifting via env var instead of CLI flag: rejected — flags are more discoverable and the precedent in update-handoff/guard-command is flag-based.

## D6 — Race-window analysis: concurrent writes

**Decision**: Accept the existing atomic temp-file + `mv` write pattern in update-handoff.{sh,ps1} as sufficient. No new locking. Document the race window in [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) as "single-writer assumed per Constitution Principle V; bridge-status read may see a write in progress only during the microsecond between rename-old and rename-new, which is benign because both states are valid JSON".

**Rationale**: Constitution Principle V says exactly one agent at a time holds write ownership; the bridge guard rule set further blocks `speckit.implement` from running while Superpowers owns execution. Parallel update-handoff calls from the same actor are not a normal flow. The temp+mv pattern guarantees that bridge-status either sees the pre-write state or the post-write state — never a partial write. SHA256 in particular cannot read a half-flushed file with this pattern (the rename is atomic on POSIX, and PowerShell's `Move-Item` is atomic on NTFS within a volume). The only failure mode is "bridge-status read happens in the same microsecond as the rename" → bridge-status sees the older snapshot. Acceptable.

**Alternatives considered**:

- Adding a `flock`-style advisory lock: rejected — adds dependency on `util-linux` (not guaranteed on minimal WSL) and complicates the PowerShell flavor. The cost is real; the benefit (defending against a flow Principle V already forbids) is zero.
- Read-and-retry loop on JSON parse failure: rejected — if the parse fails on a real corruption (not a transient mid-rename), retrying loops infinitely. The corrupted-handoff exit code 3 (FR-004) is the right answer.

## D7 — Sandbox scope for v0.7.0 verification

**Decision**: Verify both pillars end-to-end in `..\test_specify_superpower` on **WSL bash only**. PowerShell sandbox verification is explicitly deferred to a future feature that restores PowerShell smoke coverage broadly. Record at least: bridge SHA256, one successful `bridge-status` invocation in each of (no handoff) / (executing handoff with all artifacts) states, one demonstrated drift detection from an `executing` → `complete` transition with an injected modification to tasks.md, the resulting stderr warning text, the `artifact_drift_detected` event line.

**Rationale**: Matches the 011 sandbox-scope precedent (WSL bash only per 009 alignment). The PowerShell flavor is implementation parity, not sandbox coverage — the smoke suite plus a manual PowerShell run on the developer's Windows host is enough confidence for v0.7.0. SC-007 requires "at least one passing scenario from each of US1 and US2" — the planned sandbox run covers two from each, with headroom.

**Alternatives considered**:

- Full multi-platform sandbox (bash + PowerShell): rejected — PowerShell sandbox tooling isn't aligned post-009; the cost is a separate spec, not a sub-task.
- Skip sandbox entirely on a "behavioral-only" change: rejected — the feature ships a release artifact (new scripts in the ZIP, new schema doc), so the Constitution §"End-User Verification Sandbox" gate applies unambiguously.

---

## Summary of resolved unknowns

| # | Topic | Decision | Section |
|---|---|---|---|
| 1 | SHA256 tool per flavor | `sha256sum` + `Get-FileHash -Algorithm SHA256`, lowercase hex | [D1](#d1--cross-flavor-sha256-tool-choice) |
| 2 | Schema evolution | Additive field on v1 (no version bump) | [D2](#d2--schema-evolution-additive-field-vs-version-bump) |
| 3 | Decision-table source | Inline branches in scripts; canonical doc in contracts/ | [D3](#d3--decision-table-source-code-vs-data) |
| 4 | Print-contract responsibility | bridge-status emits new lines; update-handoff + guard-command unchanged | [D4](#d4--print-contract-who-emits-the-new-drift-and-next-lines) |
| 5 | JSON output mode | `--json` flag emits flat object with all printed fields | [D5](#d5--json-output-mode---json---json) |
| 6 | Race window | Existing temp+mv atomicity is sufficient; document the assumption | [D6](#d6--race-window-analysis-concurrent-writes) |
| 7 | Sandbox scope | WSL bash only, PowerShell deferred (matches 011 precedent) | [D7](#d7--sandbox-scope-for-v070-verification) |

All Phase 0 unknowns resolved. Ready for Phase 1.
