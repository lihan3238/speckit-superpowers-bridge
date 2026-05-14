# Requirements-Quality Checklist: Complete Bridge Protocol

**Purpose**: "Unit tests for English" — validate that the spec for feature 002 is complete, clear, consistent, and measurable BEFORE planning. Tests the requirements themselves, not the implementation.
**Created**: 2026-05-15
**Reviewed**: 2026-05-15 (post-implementation retrospective pass)
**Feature**: [spec.md](../spec.md)

**Legend**:
- `[x]` PASS — the item is satisfied as written
- `[~]` PARTIAL — the item is partly satisfied; minor wording or detail gap recorded under Findings
- `[ ]` FAIL — the item is a genuine gap; recorded under Findings, with disposition (fixed-this-pass / deferred-to-004 / out-of-scope / accepted-defect)
- Items annotated `(plan-level)` are intentionally deferred from spec to plan; the plan and contracts cover them

## Requirement Completeness

- [~] CHK001 - Are all four dispositions (COMBINE, FORBID-UNDER-HANDOFF, SUPERSEDED-BY, REVIEW-ONLY) defined with at least one named example each in the spec? [Completeness, Spec §FR-001]
- [ ] CHK002 - Is the behavior of the bridge guard specified when a requested command has no disposition entry at all (e.g., unrecognized capability)? [Gap, Spec §FR-003]
- [x] CHK003 - Are the fields of the verified-versions metadata enumerated (which exact values must be recorded, beyond just "version")? [Gap, Spec §FR-006] (plan-level: data-model.md §Verified Versions Record)
- [x] CHK004 - Is the schema / required fields of a Disposition Entry specified (rationale, scope, replacement pointer, applicability)? [Completeness, Spec §FR-001, §FR-002] (plan-level: data-model.md + contracts/disposition-matrix.schema.json)
- [x] CHK005 - Is the schema / required fields of a Compatibility Gap Record specified (severity levels, ID scheme, resolution status)? [Gap, Key Entities] (plan-level: data-model.md + contracts/compat-gap-record-contract.md)
- [x] CHK006 - Is the output format of the parity check report defined (machine-readable? human-readable? both?)? [Gap, Spec §FR-005] (plan-level: contracts/parity-check-contract.md)
- [ ] CHK007 - Are auto-archive transition rules covered for handoff statuses other than `complete` (e.g., a stale `blocked` from an abandoned feature)? [Coverage, Spec §FR-015]
- [ ] CHK008 - Does the spec define what the bridge does when the disposition matrix file itself is missing or unparseable? [Edge Case, Gap]

## Requirement Clarity

- [x] CHK009 - Is "machine-readable" (FR-001, FR-006) quantified — i.e. is a specific format / set of acceptable formats named, or is it intentionally left to planning? [Ambiguity, Spec §FR-001] (plan-level: research.md §R1 — JSON)
- [ ] CHK010 - Is "remediable error" (FR-008) defined — what specific user action options are presented when a missing invocation surface is hit? [Clarity, Spec §FR-008]
- [x] CHK011 - Is "single canonical location" for verified-versions (FR-006) constrained to a specific file path or directory? [Ambiguity, Spec §FR-006] (plan-level: `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`)
- [x] CHK012 - Is the difference between "active handoff" and "terminal-but-no-longer-active" defined in terms a script can test (i.e. unambiguous status values)? [Clarity, Spec §FR-015]
- [x] CHK013 - Is "documented happy path" (FR-009, SC-003) explicitly enumerated as a list of commands, or left implicit? [Clarity, Spec §FR-009]
- [x] CHK014 - Is "short-term recovery path" (FR-009) bounded in time or scope (e.g., "must be tracked in compat-gaps backlog; not allowed past P0/P1 close-out")? [Clarity, Spec §FR-009]

## Requirement Consistency

- [x] CHK015 - Does the constitution disposition in FR-004 (FORBID applicability scope `{executing}`) match the Clarifications section verbatim? [Consistency, Spec §FR-004, Clarifications] (FIXED this pass — Clarifications wording aligned)
- [x] CHK016 - Are the disposition-kind names used consistently across FR-001, FR-002, FR-004, FR-012, FR-013 (no drift like "FORBID-WHEN-EXECUTING" vs "FORBID-UNDER-HANDOFF")? [Consistency, Spec §FR-*] (FIXED this pass)
- [~] CHK017 - Is "Agent Invocation Surface" the canonical term across FR-007, FR-008, FR-009 and Key Entities (vs "invocation surface" or "slash command surface")? [Consistency, Terminology]
- [x] CHK018 - Do FR-007 (parity check fails on missing surface) and Assumptions (Codex-only hooks are temporarily acceptable was deleted) tell a single story without contradiction? [Consistency, Spec §FR-007, Assumptions]
- [x] CHK019 - Does SC-003 ("zero unrecorded fallbacks") align with FR-009 ("permitted only as short-term recovery") — i.e., are both saying "recorded short-term, otherwise zero"? [Consistency, Spec §SC-003, §FR-009]

## Acceptance Criteria Quality

- [~] CHK020 - Is SC-005's "under 30 seconds" parity-check budget testable on a defined hardware/runtime baseline, or open to interpretation? [Measurability, Spec §SC-005]
- [x] CHK021 - Is SC-007's "P0/P1" gap severity defined anywhere in the spec? [Gap, Spec §SC-007] (plan-level: contracts/compat-gap-record-contract.md defines P0–P3)
- [x] CHK022 - Is SC-008's "positive and negative test for each command" specific enough to derive concrete test cases (e.g., named handoff statuses to test)? [Measurability, Spec §SC-008]
- [~] CHK023 - Is SC-006's "simulated upstream version bump" reproducible — does the spec define what the simulation looks like? [Measurability, Spec §SC-006] (plan-level: `tests/test-parity-drift.ps1` is the canonical simulation)
- [x] CHK024 - Can SC-009's "passes the guard out of the box" be objectively verified with a deterministic command sequence? [Measurability, Spec §SC-009]

## Scenario Coverage

- [x] CHK025 - Are requirements defined for the primary flow (specify → clarify → plan → tasks → handoff → bridge → implement) end-to-end on each agent? [Coverage, US3]
- [ ] CHK026 - Are requirements defined for alternate flows (e.g., re-opening a `complete` feature; re-running clarify after plan)? [Coverage, Gap]
- [ ] CHK027 - Are exception flows specified — what happens when the guard script itself fails or is missing? [Gap, Exception Flow]
- [ ] CHK028 - Are recovery flows specified for a corrupted handoff state file (not just missing skills)? [Gap, Recovery]
- [ ] CHK029 - Are concurrent-edit flows covered when both agents are running simultaneously against the same handoff file? [Coverage, Edge Case]

## Edge Case Coverage

- [x] CHK030 - Does the spec address the case where an upstream tool renames a capability (vs adding or removing one)? [Coverage, Edge Cases]
- [x] CHK031 - Does the spec address the case where two disposition entries conflict (same command, two rules)? [Gap, Conflict] (implicit via JSON Schema uniqueness; test T011 enforces)
- [x] CHK032 - Does the spec address the case where the verified-versions record is missing entirely (first-run / fresh install)? [Gap, Edge Case]
- [x] CHK033 - Does the spec define what the bridge does on a clone-without-PowerShell environment (e.g., a Linux contributor)? [Coverage, Gap] (deferred to `specs/003-bridge-cross-platform-scripts/`, CG-005)

## Non-Functional Requirements

- [x] CHK034 - Are observability requirements specified for the new auto-archive transition events (which fields, which log)? [Gap, Observability] (plan-level: data-model.md §Bridge Event lists `auto_archive` action + fields)
- [x] CHK035 - Are performance requirements specified for the bridge guard under handoff-state queries (the constitution says <1s; does this spec reaffirm or supersede)? [Gap, Performance] (plan-level: plan.md §Performance Goals reaffirms <1s)
- [ ] CHK036 - Are security/privacy considerations specified for the bridge events log (does it record user identities? PII?)? [Coverage, Spec §FR-014]
- [ ] CHK037 - Are compliance / audit-retention requirements specified for `.specify/bridge-events.jsonl` (rotation? size cap?)? [Gap, Reliability]

## Dependencies & Assumptions

- [x] CHK038 - Is the assumption that Spec Kit 0.8.9 actually exposes every command the spec references validated (or only asserted)? [Assumption, Spec §Assumptions] (validated by `verified-versions.json` + parity check)
- [x] CHK039 - Is the assumption that the Superpowers skill set is uniformly exposed to both Codex and Claude Code validated, or implicit? [Assumption, Spec §Assumptions] (validated by `verified-versions.json` + parity check)
- [x] CHK040 - Are external dependencies (PowerShell version, git version, encoding) documented for cross-platform contributors? [Dependency, Gap] (plan-level: plan.md §Technical Context + quickstart.md §Prerequisites)

## Ambiguities & Conflicts

- [x] CHK041 - Is the term "the bridge" used distinctly from "the bridge guard" throughout, or are they sometimes conflated? [Ambiguity, Terminology]
- [x] CHK042 - Is "applicability scope" (used in FR-002 and Key Entities) a single concept, or does it mean different things in those two places (handoff-status subset vs always/under-handoff/per-agent enum)? [Ambiguity, Spec §FR-002, Key Entities] (FIXED this pass — Key Entities now matches FR-002)
- [x] CHK043 - Is the relationship between "Disposition Entry" and "Disposition Matrix" formally one-to-many, or could the matrix be expressed inline in other files? [Ambiguity, Key Entities] (plan-level: data-model.md "1: contained-in 1")
- [x] CHK044 - Is "feature" consistently used to mean "Spec Kit feature directory" vs "capability / skill we're classifying"? [Terminology, Conflict] ("feature" = directory; "capability/skill" = matrix entry)

## Traceability

- [x] CHK045 - Is a requirement & acceptance-criteria ID scheme established (FR-NNN and SC-NNN currently)? Is it referenced from edge cases and assumptions? [Traceability]
- [x] CHK046 - Does every Compatibility Gap Record format support back-referencing to the FR that the gap violates? [Traceability, Gap] (plan-level: contracts/compat-gap-record-contract.md `related_requirements` field)

---

## Summary

- **PASS** (`[x]`): 32 items
- **PARTIAL** (`[~]`): 4 items (CHK001, CHK017, CHK020, CHK023)
- **FAIL** (`[ ]`): 10 items (CHK002, CHK007, CHK008, CHK010, CHK026, CHK027, CHK028, CHK029, CHK036, CHK037)
- **FIXED this pass**: CHK015, CHK016, CHK042 (textual edits to spec.md Clarifications and Key Entities)

## Findings

### Genuinely deferred gaps (out-of-scope for feature 002's stated focus)

These are real gaps in the spec, but they describe behaviors orthogonal to feature 002's three user stories (disposition matrix, constitution/checklist, Claude parity). Captured here for traceability; each carries an explicit disposition.

- **CHK002** (no disposition entry behavior) — current implementation silently falls through to legacy rules; the parity check separately catches missing entries as P0 findings. The "what the guard does at request time" gap is acceptable because the parity check is the gating mechanism, not the guard. **Disposition: ACCEPTED — covered by parity check at config time, not by guard at request time.**
- **CHK007** (auto-archive for non-`complete` statuses) — out of scope; feature 002 only auto-archives `complete`. Stale `blocked` is a manual recovery scenario. **Disposition: OUT-OF-SCOPE.**
- **CHK008** (matrix file missing/unparseable) — current implementation: parity check raises P0; guard falls through to legacy rules. Spec does not explicitly state this contract. **Disposition: DEFERRED-TO-004** — feature 004 US2 (install-state audit) is the natural place to codify the missing-file response.
- **CHK010** (remediable error definition) — current implementation: throws with the matrix entry's rationale + a "suggested fix" line. Spec says "remediable" without defining. **Disposition: DEFERRED-TO-004** — the install-state audit's error UX will set the bar.
- **CHK026** (re-opening `complete` feature) — not addressed. The disposition matrix already classifies `speckit.specify`/`speckit.clarify`/`speckit.plan`/`speckit.tasks` as COMBINE so a re-run is technically allowed; the guard's same-feature-complete deny would block it. **Disposition: ACCEPTED-DEFECT** — re-open requires manual `update-handoff.ps1 -Status blocked` first; documented behavior, not silent failure.
- **CHK027** (guard script missing) — PowerShell file-not-found error propagates; no graceful degradation. **Disposition: ACCEPTED-DEFECT** — the script's absence is itself a P0 install state and should fail loudly.
- **CHK028** (corrupted handoff recovery) — current implementation: `ConvertFrom-Json` failure propagates. **Disposition: DEFERRED-TO-004** — install-state audit can detect + recommend restore-snapshot.
- **CHK029** (concurrent-edit flows) — constitution mandates single-writer ownership; no file-level locking. **Disposition: ACCEPTED** — single-writer model is the design; concurrent writes are policy-level, not file-system-level, prevented.
- **CHK036** (events log PII) — current log records `actor` (codex/claude/unknown) + free-text `reason`. No structured PII fields; reasons are author-controlled. **Disposition: DEFERRED-TO-004** — marketplace listing audit should set a no-PII guideline.
- **CHK037** (events log retention) — append-only with no rotation or size cap. **Disposition: DEFERRED-TO-004** — marketplace install needs a documented retention/cleanup story.

### Partial items not worth a full pass

- **CHK001** — spec body names examples only for COMBINE (`speckit.checklist`) and FORBID-UNDER-HANDOFF (`speckit.constitution`); SUPERSEDED-BY and REVIEW-ONLY appear only in the matrix data, not in spec prose. **Disposition: ACCEPTED** — the matrix and contracts cover the gap; adding two named examples to the spec body is editorial polish for a future feature.
- **CHK017** — "invocation surface" used in FRs; "Agent Invocation Surface" used in Key Entities. Same concept, two casings. **Disposition: ACCEPTED** — clear from context.
- **CHK020** — "under 30 seconds on a clean checkout" lacks a hardware baseline, but is testable on the dev machine (which is what the test scripts use). **Disposition: ACCEPTED** — typical CI/dev-laptop class.
- **CHK023** — `tests/test-parity-drift.ps1` is the canonical simulation; spec doesn't reference it by name. **Disposition: ACCEPTED** — implementation evidence sits in the test.

### Fixed this retrospective pass (3 edits to spec.md)

- **CHK015 + CHK016**: changed Clarifications #2 wording from "FORBID-DURING-EXECUTING" to canonical "FORBID-UNDER-HANDOFF with applicability scope `{executing}`".
- **CHK042**: Key Entities "Disposition Entry" definition updated to align "applicability scope" with FR-002's "subset of `executing`, `blocked`, `complete`" rather than the orthogonal `always / under-handoff / per-agent` enum.

## Ship gate verdict

**Pass-with-deferrals.** Feature 002 is shipping with:
- 32 items satisfied as written
- 4 items partially satisfied (acceptable as written)
- 3 items fixed in this retrospective pass
- 10 items genuinely gapped, all dispositioned (5 deferred to feature 004, 4 accepted as design choices, 1 out-of-scope)

No gap is severe enough to block feature 002. The deferred items have a named follow-up (feature 004 polish-and-publish).
