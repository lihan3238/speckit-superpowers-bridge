# Compatibility Gap Log: Marketplace Alignment

**Feature**: 005-marketplace-alignment
**Last updated**: 2026-05-15

Live log of compatibility gaps observed during validation. Append-only; rows never deleted.
Schema: see [contracts/compat-gap-record-contract.md from feature 002](../002-complete-bridge-protocol/contracts/compat-gap-record-contract.md).

## Records

_None at plan time._ This feature is documentation + packaging + cleanup; no runtime bridge changes are introduced, so no new CGs are expected. If validation surfaces any during implementation, append rows here.

## How to append

When a future validation run on this branch surfaces a gap, append a row at the bottom following the schema. Use the next sequential `CG-NNN` ID (continuing from the highest used across all features, currently `CG-006`). Do not edit existing rows except to flip `Status` and add `Closes In` when a fix lands.

## CG-007 - skill_phase_uncovered

- Status: CLOSED-IN-FEATURE
- Closes In: 005-marketplace-alignment
- Severity: P1
- Target: .specify/bridge-events.jsonl
- Signature: skill_phase_uncovered|.specify/bridge-events.jsonl
- Observed: Missing invocation phase(s): before-phase-completion.
- Proposed fix: Emit events for each required lifecycle phase.
- Resolution: Emitted the missing `before-phase-completion` event at the Phase-3 boundary; subsequent validation-pass run reports all 11 checks PASS.

