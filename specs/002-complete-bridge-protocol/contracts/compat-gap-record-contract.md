# Compatibility Gap Record Contract

**Feature**: 002-complete-bridge-protocol

## Purpose

A Compatibility Gap Record (CG) captures one observed bridge-compat defect during a
live validation run. The record is the bridge between "this hurt" and "we
mechanically fixed it" — it must be specific enough that a follow-up task can act
on it without guessing.

## Storage format

CG records live in `specs/<feature>/compat-gaps.md` as a Markdown table, one row
per record. The header is fixed:

```markdown
| ID    | Severity | Description | Proposed Resolution | Status | Closes In | Related | Observed At | Observed By |
|-------|----------|-------------|---------------------|--------|-----------|---------|-------------|-------------|
| CG-001| P1       | …           | …                   | OPEN   |           | FR-007  | 2026-05-15  | claude      |
```

(`Closes In` is the feature directory ID when status is `CLOSED-IN-FEATURE`; blank
otherwise.)

## Field rules

- `ID` MUST be `CG-NNN` with a 3-digit sequential number, globally unique within
  the feature.
- `Severity` MUST be one of `P0` / `P1` / `P2` / `P3`:
  - **P0** — bridge unusable on either agent for this case
  - **P1** — documented happy path cannot complete without a recovery path
  - **P2** — extra steps required but the user can complete the flow
  - **P3** — quality-of-life / nice-to-have
- `Description` MUST be one paragraph stating the observed behavior (not the
  desired behavior).
- `Proposed Resolution` MUST reference a concrete artifact: a file path, a script,
  a script-flag change, or a contract section. No vague verbs like "investigate".
- `Status` MUST be one of `OPEN` / `CLOSED-IN-FEATURE` / `DEFERRED`.
- `Closes In` MUST be non-empty if `Status` is `CLOSED-IN-FEATURE`; MUST be empty
  for `OPEN`; MAY name a follow-up feature ID for `DEFERRED`.
- `Related` MUST list at least one FR or SC identifier from `spec.md` (e.g.
  `FR-007, SC-003`). If a CG truly has no related requirement, the spec is wrong
  and MUST be amended (the CG itself is evidence that a missing requirement
  exists).
- `Observed At` is ISO 8601 date (UTC).
- `Observed By` is the actor name (`codex` / `claude`).

## Lifecycle

```
OPEN ──fix lands in this feature──► CLOSED-IN-FEATURE
OPEN ──explicitly deferred──► DEFERRED (Closes In = follow-up feature ID)
DEFERRED ──follow-up feature lands──► CLOSED-IN-FEATURE (Closes In updated)
```

CG records are never deleted. A `CLOSED-IN-FEATURE` record may carry a note linking to the commit/PR that closed it.

## Validation by parity check

The parity check (`parity-check.ps1`) does NOT validate the CG log directly; CG
records are human-curated. However, the parity check's findings overlap
conceptually with CGs: a `missing_invocation_surface` finding at run time should
correspond to a logged CG in `compat-gaps.md` until the finding goes away. This is
enforced by review, not automation.

## Source of truth for the current feature

`specs/002-complete-bridge-protocol/compat-gaps.md` is initialized with the five
records observed during this clarify/plan run (CG-001 … CG-005) as documented in
[plan.md](../plan.md#compatibility-gap-records-from-live-claude-run-this-session).
Subsequent Claude/Codex runs on this branch MAY append new records but MUST NOT
edit prior ones.

## Ship gate

A feature MAY be marked complete only when:

1. Every CG with `Severity == P0` or `Severity == P1` for the current feature is
   `CLOSED-IN-FEATURE`, OR
2. Each such CG is explicitly `DEFERRED` with a named follow-up feature, AND that
   follow-up feature has been recorded in the project backlog (e.g. as a Spec Kit
   feature directory or a GitHub issue).

P2/P3 records MAY remain `OPEN` past feature completion. SC-007 in spec.md
codifies this gate.
