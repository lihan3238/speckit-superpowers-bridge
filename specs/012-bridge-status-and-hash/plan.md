# Implementation Plan: Bridge Status Command + SHA256 Handoff Artifact Hash

**Branch**: `012-bridge-status-and-hash` | **Date**: 2026-05-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/012-bridge-status-and-hash/spec.md`

## Summary

A **v0.7.0 behavioral-additive feature** with two integrated pillars borrowed from rpamis/comet's design and adapted to the bridge's Native-First discipline:

1. **`bridge-status` — on-demand bridge introspection**. A new read-only platform-flavored helper at `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/bridge-status.{sh,ps1}` that reads the current `superpowers-handoff.json` (without writing), prints the existing v0.5.0 `[bridge state]` block (5 lines, contract 008/R-OUT-1..5), then appends two new lines: `Drift: <list>|(none)` (only when the handoff has an `artifacts_sha256` field) and `Next: <recommendation>` (always). The Next recommendation comes from a deterministic decision table over (handoff status × constitution presence × feature-artifact presence) — pure file existence checks, no LLM call.
2. **`artifacts_sha256` — handoff artifact-drift detection**. A new optional top-level object on the handoff JSON, mapping the three Spec Kit source-of-truth filenames (`spec.md`, `plan.md`, `tasks.md`) to lowercase-hex SHA256 strings (or JSON `null` for files that don't yet exist on disk). Written by `update-handoff` on every `executing` and `complete` write. On `complete` writes that compare hashes against the prior snapshot, mismatches surface as exactly one stderr warning line plus one `artifact_drift_detected` event in `.specify/bridge-events.jsonl`. Exit code stays 0; the transition is not blocked.

Native-First gate (Constitution VI) is the binding constraint: SC-010 caps the entire feature at 2 new helper scripts (bash + PowerShell) + 1 new test file + 1 new event type + 1 schema additive field. Zero new state files; zero new slash commands; zero edits to vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}`. The bridge's own SKILL files (`speckit-superpowers-bridge`) may gain exactly one mention-line each (FR-011) — documentation, not behavior.

Technical approach (per Phase 0 research, this plan's [research.md](./research.md)):

- Hash computation via `sha256sum` (ubiquitous on WSL bash) and PowerShell's built-in `Get-FileHash -Algorithm SHA256`. Identical lowercase-hex normalization in both flavors.
- Atomic handoff write via the existing temp-file + `mv` pattern in `update-handoff.{sh,ps1}` — `artifacts_sha256` is merged via jq (bash) or `ConvertFrom-Json`/`ConvertTo-Json` round-trip (PowerShell), reusing the helpers already in `bridge-state.sh` / `common-actor-resolution.sh`.
- Decision table for the `Next:` recommendation: defined inline in each flavor as a sequence of conditional branches keyed off five booleans (`has_handoff`, `has_constitution`, `has_feature_dir`, `has_spec`, `has_plan`, `has_tasks`) plus the handoff `status` enum value. Total cells enumerated in [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md). Exhaustive: every state combination yields exactly one recommendation or the literal string `(none)`.
- The existing 5-line print contract from [008/contracts/bridge-state-summary.md](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md) is preserved verbatim by `update-handoff` and `guard-command` — they continue to emit the 5 lines unchanged. `bridge-status` is the ONLY caller that adds the `Drift:` and `Next:` lines. `update-handoff` surfaces drift via stderr warning + event, not stdout (FR-006 vs FR-007 asymmetry).
- Pre-0.7.0 handoff tolerance (FR-013): both scripts treat a missing `artifacts_sha256` key as "no snapshot recorded, no drift to report" — no migration script, no version-pin requirement.

## Technical Context

**Language/Version**: bash 5.x (WSL Ubuntu primary) + PowerShell 5.1+ (Windows parity). No language additions over v0.5.0/v0.6.0.

**Primary Dependencies**: `jq` (already required by existing bridge scripts); `sha256sum` from GNU coreutils (universally present on WSL bash); PowerShell built-in `Get-FileHash -Algorithm SHA256` (no module install needed). Existing helpers: [.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh](../../.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh), [common-actor-resolution.sh](../../.specify/extensions/speckit-superpowers-bridge/scripts/bash/common-actor-resolution.sh), and the PowerShell counterparts.

**Storage**: filesystem only. Touched files:
- `.specify/superpowers-handoff.json` — extended with new optional `artifacts_sha256` object (schema v1 additive, allowed by `additionalProperties: true`).
- `.specify/bridge-events.jsonl` — gains one new event type `artifact_drift_detected`; append-only as before.
- `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json` — schema delta declaring `artifacts_sha256` as optional object.

No new state files. No new directories beyond the existing bridge extension layout.

**Testing**: existing `tests/test-*.sh` bash smoke suite on WSL bash (per 009 alignment). Exactly ONE new test file `tests/test-bridge-status.sh` covering all 10 acceptance scenarios (5 from US1, 5 from US2) plus 6 edge cases. Suite must stay within the `< 10s` budget per AGENTS.md "Running the smoke-test suite" (SC-006). New test expected to add ≤ 2s.

**Target Platform**: WSL bash dev environment for primary development. PowerShell flavor maintained for parity but verified in-repo only (smoke is bash-only per 009). End-user sandbox verification at `..\test_specify_superpower` on WSL bash per Constitution §"End-User Verification Sandbox" (FR-015 + SC-007).

**Project Type**: Spec Kit extension package (the bridge IS the project). Single-package layout, no `src/` tree, no test framework beyond the bash smoke suite. New files live at well-defined paths inside the bridge extension package.

**Performance Goals**:
- SC-001: `bridge-status` invocation completes in **under 1 second** on the reference WSL bash environment.
- SC-003: byte-identical output across two consecutive same-state invocations (idempotent read).
- Implied: per-file SHA256 of three Markdown files (typically < 100KB each) is < 50ms on WSL bash; the dominant cost is `jq` JSON parse + format (also < 50ms).

**Constraints**:

- Constitution Principle VI (Native-First) — codified by SC-010 lightness budget with 9 sub-constraints (a–i).
- Constitution Principle II — vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}` files MUST NOT be edited (FR-010 (i), SC-005).
- Constitution Principle V — only project-owned `speckit-superpowers-bridge` SKILL.md peers MAY receive the one-line FR-011 mention.
- 5 hardcoded guard rules in `guard-command.{sh,ps1}` remain byte-identical (only the new `Drift:`-aware print is added inside the shared `bridge-state.sh` helper, NOT in guard-command itself — see research D4).
- v1 handoff schema's `schema_version` field stays at 1 (additive field uses the `additionalProperties: true` extension point — no version bump per [research.md D2](./research.md#d2--schema-evolution-additive-vs-version-bump)).

**Scale/Scope**: 2 new helper scripts (bash + PowerShell, ≤ 200 lines each per SC-010 a/b) + ≤ 60 added lines per flavor in `update-handoff.{sh,ps1}` (per SC-010 c/d) + 1 new test file (≤ 250 lines, fits the < 10s budget) + 1 new event type definition + 1 additive schema field. Two README files each gain ≤ 12 added lines (combined ≤ 25 per FR-014). CHANGELOG gains one `[0.7.0]` section. Total scope ceiling: ~ 1100 added LoC across the whole feature. Zero new top-level files at the repo root.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| **I. Lightweight & Repo-Local** | ✅ PASS | 0 daemons, 0 services, 0 new infrastructure. New surface confined to the existing `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/` directory. SC-010 codifies the budget. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | Vendor-managed `.{claude,agents}/skills/speckit-*` files untouched (SC-005 + FR-010 (i)). The Spec Kit contract (constitution / spec / plan / tasks) is *observed* by the hash, not *replaced* by it. Drift detection is a passive integrity layer — it cannot override or amend Spec Kit artifacts. |
| **III. Agent-Neutral Protocol** | ✅ PASS | `bridge-status` reads the same handoff and prints the same block regardless of which actor invokes it. The Next: recommendation logic is identical across flavors and across actors — derived only from on-disk file state. PowerShell flavor reaches feature parity with bash flavor in the same release. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS | `artifacts_sha256` extends — does not replace — the existing handoff schema. The `[bridge state]` print contract is preserved (only bridge-status appends the new lines; update-handoff and guard-command keep emitting the 5-line block unchanged). One new event type (`artifact_drift_detected`); event log remains append-only (Principle IV constraint). |
| **V. Vendor-Managed Boundaries** | ✅ PASS | Only the project-owned `speckit-superpowers-bridge` SKILL.md peers gain the FR-011 documentation line; behavioral instructions in those files unchanged. The new scripts live inside the bridge extension package and the guard rule set is unchanged. |
| **VI. Native-First Compatibility (Trust Upstream Growth)** | ✅ PASS (with gate answers) | See Native-First gate below. |

### Native-First gate (constitution §VI, v1.3.0+)

This feature introduces TWO new pieces of bridge surface — a read-only helper script (`bridge-status`) and a new optional handoff field (`artifacts_sha256`) — plus one new event type. Per the gate template, each must answer Q1 and Q2:

**Pillar 1 — `bridge-status` introspection helper**:

- **Q1: Does upstream Spec Kit / Superpowers / the LLM agent already do this?** No. Spec Kit's `/speckit-*` slash commands all *act on* state (specify, plan, tasks, implement); none of them are pure introspectors of the *bridge's* handoff JSON. Superpowers has no equivalent — its skills do not know about the bridge. The LLM agent can be asked to `cat` the JSON, but that's not a deterministic single-command UX and it cannot generate the `Next:` recommendation without project-specific decision-table logic. The bridge's `[bridge state]` block itself is a project-local convention introduced in feature 008. Status: **no, upstream does not do this**.
- **Q2: Is upstream the right place to fix this?** No. The handoff JSON is project-local. Spec Kit cannot reasonably ship a generic introspection command for it; the recommendation table depends on the *bridge's* protocol (executing/blocked/complete states, supersedes list, artifact_owner enum). Status: **no, this is local-owned**.

**Pillar 2 — `artifacts_sha256` field on handoff**:

- **Q1: Does upstream already do this?** No. Neither Spec Kit nor Superpowers tracks SHA256 of artifacts between phase transitions. The handoff JSON is a project-owned contract introduced by this bridge (feature 002 / refined by 006). The closest precedent is Git's commit hashes — but Git tracks the *repo* state at commit time, not the *bridge's* phase-transition state. A developer could grep `git log` to reconstruct artifact drift, but that's manual and slow; the spec's SC-001 (< 1s recovery) rules out manual reconstruction. Status: **no, upstream does not do this**.
- **Q2: Is upstream the right place to fix this?** No — the handoff JSON is the bridge's contract; only the bridge knows when "executing" begins and "complete" ends. Spec Kit's lifecycle doesn't have phase transitions to anchor a snapshot against. Status: **no, this is local-owned**.

Both pillars: Q1 + Q2 both "no" → new surface is justified. Total justified surface: **2 helper scripts + 1 schema field + 1 event type + 1 helper test**, all inside the existing bridge extension package and protocol — no new top-level files, no new commands at the slash/extension layer, no new state files.

The feature also actively *reuses* upstream-of-the-bridge surface: the existing `[bridge state]` print contract from feature 008, the existing v1 handoff schema's `additionalProperties: true` extension point, the existing temp-file + `mv` atomic write pattern in `update-handoff.{sh,ps1}`, the existing actor-resolution helper. This reuse is a Principle VI win, not a violation.

### Release gate (constitution §"End-User Verification Sandbox", v1.2.0+)

v0.7.0 ships a release artifact (new bridge ZIP with the new scripts + schema delta) → sandbox gate applies. Polish phase MUST include one task: install the v0.7.0 ZIP fresh in `..\test_specify_superpower` via the published release URL (the v0.6.0-decoupled stable-alias `releases/latest/download/speckit-superpowers-bridge.zip` is the install target — no per-release URL edit needed), run one complete bridge cycle on WSL bash that exercises both `bridge-status` and one demonstrated `artifact_drift_detected` event, record outcome in `specs/012-bridge-status-and-hash/verification.md` per FR-015 + SC-007. The 009 bash-only smoke surface narrows sandbox to WSL bash; PowerShell sandbox coverage remains deferred to a future feature.

## Project Structure

### Documentation (this feature)

```text
specs/012-bridge-status-and-hash/
├── plan.md              # This file
├── research.md          # Phase 0 — decision log (D1..D7) covering: hash tool choice, schema evolution
│                        #   strategy, decision-table source, print-contract responsibility split,
│                        #   JSON output mode shape, race-window analysis, sandbox scope.
├── data-model.md        # Phase 1 — 4 entities (bridge-status command, artifacts_sha256 field,
│                        #   decision table, artifact_drift_detected event) + negative-space list.
├── quickstart.md        # Phase 1 — maintainer's WSL-bash implementation + test walkthrough,
│                        #   step-by-step, including sandbox verification of v0.7.0 release.
├── contracts/
│   ├── bridge-status-output.md          # Print contract for the new helper — extends 008's R-OUT-*.
│   ├── handoff-v1.1.delta.md            # Schema delta for the new artifacts_sha256 optional field.
│   ├── next-command-decision-table.md   # Exhaustive (status × constitution × artifacts) → Next cells.
│   └── artifact-drift-event.md          # JSONL event schema for artifact_drift_detected entries.
├── checklists/
│   └── requirements.md  # Spec quality (already passing 16/16 from /speckit-specify)
└── tasks.md             # Phase 2 — created by /speckit-tasks, not this command.
```

### Source / artifact paths touched (repo root)

```text
.specify/extensions/speckit-superpowers-bridge/
├── scripts/
│   ├── bash/
│   │   ├── bridge-status.sh                          # FR-001: NEW helper (≤ 200 lines)
│   │   ├── update-handoff.sh                         # FR-005/FR-006/FR-008: ≤ 60 added lines
│   │   ├── bridge-state.sh                           # shared print helper, gains the conditional
│   │   │                                             #   Drift: + Next: emit logic for bridge-status
│   │   │                                             #   callers only (gated by an env or arg flag)
│   │   ├── common-actor-resolution.sh                # UNCHANGED
│   │   ├── guard-command.sh                          # UNCHANGED (5 guard rules byte-frozen)
│   │   └── auto-archive-handoff.sh                   # UNCHANGED
│   └── powershell/
│       ├── bridge-status.ps1                         # FR-001: NEW helper (≤ 200 lines)
│       ├── update-handoff.ps1                        # FR-005/FR-006/FR-008: ≤ 60 added lines
│       ├── bridge-state.ps1                          # shared print helper, parallel to .sh version
│       ├── common-actor-resolution.ps1               # UNCHANGED
│       ├── guard-command.ps1                         # UNCHANGED
│       └── auto-archive-handoff.ps1                  # UNCHANGED
├── extension.yml                                     # version 0.6.0 -> 0.7.0
└── verified-versions.json                            # OPTIONAL refresh if v0.7.0 verifies new upstream

specs/006-trim-to-thin-bridge/
└── contracts/
    └── handoff.v1.schema.json                        # FR-009: declare optional artifacts_sha256

marketplace/
└── catalog-entry.json                                # version 0.6.0 -> 0.7.0; download_url unchanged
                                                     #   (stable-alias permanent per v0.6.0 decoupling)

CHANGELOG.md                                          # FR-014: new [0.7.0] section
README.md                                             # FR-014: ≤ 13 added lines (Skills/Commands details)
README.zh-CN.md                                       # FR-014: ≤ 12 added lines (mirror)
CLAUDE.md                                             # SPECKIT marker updated by this command
AGENTS.md                                             # OPTIONAL: one-line mention of bridge-status

.claude/skills/speckit-superpowers-bridge/SKILL.md    # FR-011: +1 line referencing bridge-status
.agents/skills/speckit-superpowers-bridge/SKILL.md    # FR-011: +1 line referencing bridge-status

tests/
├── test-bridge-status.sh                             # FR-012: NEW test file (≤ 250 lines)
├── fixtures/
│   └── pre-070-handoff.json                          # FR-013: fixture for backwards-compat assertion
└── run-all.sh                                        # No change (auto-picks up test-*.sh)

# Files NOT changed by this feature (explicitly byte-frozen):
.claude/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/   # SC-005
.agents/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/  # SC-005
.specify/extensions.yml                                                                                             # no new hooks
guard-command.{sh,ps1}                                                                                              # 5 rules byte-frozen
```

**Structure Decision**: The project is a Spec Kit extension package; the structure above is the existing v0.6.0 layout with three additions inside the bridge package (`bridge-status.{sh,ps1}` and minimal edits to `update-handoff.{sh,ps1}` + the shared `bridge-state.{sh,ps1}` print helper). No new top-level directories. No new entries in `.specify/extensions.yml`. The new test file lives alongside the existing 12 smoke tests at `tests/test-*.sh`. The schema delta lives in the existing `specs/006-.../contracts/` directory (the v1 schema's canonical home) rather than this feature's contracts/ to keep the schema versioning history linear — this feature's `contracts/handoff-v1.1.delta.md` is the *documentation* of the delta, not a parallel schema file.

## Complexity Tracking

> No Constitution Check violations. Section intentionally minimal.

The two new pieces of bridge surface — `bridge-status` script and `artifacts_sha256` field — were each evaluated against Principle VI's Q1+Q2 gate. All four answers are "no" (upstream does not do this; upstream is not the right place to fix this). Both pieces of surface are justified as local-owned extensions of the bridge's existing protocol.

The one design choice that *could* be flagged as complexity — adding a `Drift:` line to the existing 5-line `[bridge state]` print contract — was deliberately scoped to the new `bridge-status` caller only (not `update-handoff` or `guard-command`). This preserves the 008 contract verbatim for existing callers (SC-008) and keeps the asymmetry rule from FR-006 vs FR-007 enforceable: writes that detect drift surface it as stderr warnings; reads that detect drift surface it as a stdout line. One signal, two channels, no duplication.

| Candidate complexity | Why kept | Simpler alternative rejected because |
|---|---|---|
| New script vs. flag on existing update-handoff | The whole point is a *read-only* surface — overloading update-handoff with a `--no-write --dry-run` flag would couple read and write code paths and risk accidental writes. SC-003 (byte-identical idempotency) is easier to defend with a separate script. | A `--print-only` flag was considered but rejected: it adds a code path to update-handoff that must be tested in two modes (write + dry-run) and confuses the audit trail. |
| Separate `Drift:` line in bridge-status output vs. inlining into Status: | The 008 contract orders fields in a specific way; adding new conditional content to existing lines would force a contract rewrite. Appending optional lines after the existing block is backward-compatible per R-OUT-2 phrasing. | Inlining (`Status: executing (drift: tasks.md)`) was considered but rejected: it changes a contract that downstream automation may rely on. |
| New event type vs. piggybacking existing `update_handoff` event | The event log is consumed for audit; mixing drift signal into the generic update_handoff entries would make queries like "show all drift incidents" require a substring scan instead of a type filter. A separate event type is cleaner. | A `drift_detected_in_update` flag inside the existing event was rejected: it complicates the event schema while saving one event-type definition. The audit story is more important. |

## Post-Design Constitution Re-check (after Phase 1)

Re-run after [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), and [quickstart.md](./quickstart.md) were written. Same 6 principles, same table form — all still pass, and Phase 1 added concrete evidence:

| Principle | Status | Phase-1 evidence |
|---|---|---|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | [data-model.md](./data-model.md) "Negative space" table explicitly lists 9 byte-frozen paths and caps the modifiable set at 4 new files + 8 in-place edits. Contracts impose hard line-count budgets matched to SC-010. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ STILL PASS | The hash field *observes* Spec Kit artifacts without modifying them. [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) keeps `source_of_truth` untouched; the new field sits alongside it. Drift detection is advisory (exit code 0, warning + event only) — never blocks a Spec Kit flow. |
| **III. Agent-Neutral Protocol** | ✅ STILL PASS | [contracts/bridge-status-output.md](./contracts/bridge-status-output.md) defines identical output rules for bash and PowerShell. [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md) defines an actor-agnostic event shape (actor field carries the value, doesn't differentiate behavior). PowerShell and bash reach feature parity in the same release. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL PASS | [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) preserves the v1 schema's `additionalProperties: true` extension point and stays at `schema_version: 1` — backward-compat tables document the full v0.4..v0.7 reader/writer matrix. The new event type appends to the same `bridge-events.jsonl` file as existing events, append-only. The new `bridge-status` helper is the third caller of the same shared print logic that already serves `update-handoff` and `guard-command`. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | [data-model.md](./data-model.md) "Negative space" enumerates `.claude/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` (and the `.agents/` mirror) as byte-frozen. The only SKILL.md edits permitted are 1 line each in the project-owned `speckit-superpowers-bridge` SKILL files (FR-011) — documentation, not behavioral. SC-005's `git diff` filter scopes the lint precisely. |
| **VI. Native-First Compatibility (Trust Upstream Growth)** | ✅ STILL PASS | Phase 1 reinforces native-first three ways: (a) [research D2](./research.md#d2--schema-evolution-additive-field-vs-version-bump) avoids a schema-version bump by reusing the v1 `additionalProperties: true` extension point — upstream-style additive evolution. (b) [research D4](./research.md#d4--print-contract-who-emits-the-new-drift-and-next-lines) preserves the existing 008 print contract by confining new output to the new caller — reuse, not duplicate. (c) [research D1](./research.md#d1--cross-flavor-sha256-tool-choice) chooses tools already required by the bridge baseline — zero new dependencies. New surface remains justified: bridge-status + artifacts_sha256 + artifact_drift_detected event, all local-owned by Q1+Q2 gate. |

### Native-First gate re-check

- **Q1: Does upstream already do this?** Still "no" after Phase 1. The contracts in this directory ([bridge-status-output.md](./contracts/bridge-status-output.md), [handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md), [next-command-decision-table.md](./contracts/next-command-decision-table.md), [artifact-drift-event.md](./contracts/artifact-drift-event.md)) all reference *project-local* state (the handoff JSON, the event log, the decision table over project-local file presence). Spec Kit and Superpowers have no equivalent.
- **Q2: Is upstream the right place to fix this?** Still "no". The handoff JSON, event log, and `[bridge state]` print contract are all the bridge's own contracts introduced by features 002/006/008. Upstream cannot reasonably ship a generic introspection layer for them.

### Release gate re-check

[quickstart.md](./quickstart.md) Step 11 codifies the sandbox verification on WSL bash with concrete `specify init` + `specify extension add` + drift-injection commands. The verification record at `specs/012-bridge-status-and-hash/verification.md` is gated to exist before the feature's handoff transitions to `complete` (FR-015 + SC-007).

### SC-010 lightness budget re-check

Every Phase 1 artifact reinforces the budget:

- [data-model.md](./data-model.md) "Negative space" table caps modifiable files at the explicit allow list — SC-010 (i) is checkable by `git diff` filter.
- [contracts/bridge-status-output.md](./contracts/bridge-status-output.md) C-S1 enforces the 1-second performance budget (SC-001).
- [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) keeps schema_version=1 and `additionalProperties: true` — SC-010 (g) "zero new state files" is preserved (the new field is additive on the existing handoff, not a new file).
- [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md) keeps the table inline in scripts — SC-010 (g) is preserved (no new YAML/JSON data file).
- [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md) defines exactly one new event type — SC-010 (e) "exactly one new event type" is checkable by grep for `event ==` against the project.

### Conclusion

Design phase complete; all six principles still PASS; Native-First gate's Q1+Q2 still "no" for both pillars; release gate planned via quickstart Step 11; SC-010 budget enforced by contracts. Ready for `/speckit-tasks`.
