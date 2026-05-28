---
description: "Task list for v0.7.0 — bridge-status command + SHA256 handoff artifact hash"
---

# Tasks: v0.7.0 — Bridge-Status Command + SHA256 Handoff Artifact Hash

**Input**: Design documents from `specs/012-bridge-status-and-hash/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md) (required for user stories), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: REQUIRED for this feature per spec FR-012 (smoke-test suite MUST gain `tests/test-bridge-status.sh` covering all 10 acceptance scenarios + 6 edge cases + 14 decision-table vectors). Test tasks live inside each user story phase.

**Organization**: Tasks are grouped by user story (US1 = on-demand bridge introspection, US2 = SHA256 artifact-drift detection) so each story can be implemented and tested independently as MVP increments.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks).
- **[Story]**: Maps tasks to user stories (US1 / US2). Setup, Foundational, and Polish phases have no story label.
- Every task includes the exact file path it touches.

## Path Conventions

This is a Spec Kit extension package (the bridge IS the project). Source files live at well-defined paths inside `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/` and tests at `tests/`. No `src/` tree, no test framework beyond bash smoke. Schema delta lives at `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json` (canonical v1 schema home).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Pre-flight verification — branch state, tool availability, design-doc readiness.

- [ ] T001 Verify working tree is on `012-bridge-status-and-hash` branch with clean status (`git status` reports only untracked `specs/012-*` artifacts from prior phases); verify WSL proxy reachable per CLAUDE.md (`curl -sI --proxy http://10.88.0.6:10808 https://github.com | head -1` returns `HTTP/2 200`).
- [ ] T002 [P] Verify required toolchain available: `command -v jq && jq --version` (≥ 1.6) and `command -v sha256sum && sha256sum --version | head -1` (GNU coreutils 8+). Record versions in [specs/012-bridge-status-and-hash/quickstart.md](./quickstart.md) Pre-flight section if drift from research [D1](./research.md#d1--cross-flavor-sha256-tool-choice).
- [ ] T003 [P] Read the four contract docs side-by-side to internalize the print contract, schema delta, decision table, and event shape: [contracts/bridge-status-output.md](./contracts/bridge-status-output.md), [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md), [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md), [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md). Confirm all 12 decision-table cells + 5+5+6 acceptance scenarios are concrete enough to implement against.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema delta and shared print helper — both pillars depend on these.

**⚠️ CRITICAL**: T004 and T005 MUST land before any US1 or US2 work begins.

- [ ] T004 Apply schema delta per [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) to [specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json](../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json): add the `artifacts_sha256` property declaration (3-key object with `string|null` 64-hex pattern) and the conditional `allOf` rule requiring the field when `status` is `executing` or `complete`. Keep `schema_version` integer range and top-level `additionalProperties: true` unchanged. Verify with `jq -e '.properties.artifacts_sha256.properties["tasks.md"].pattern == "^[0-9a-f]{64}$"' specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`.
- [ ] T005 Extend the shared print helper in [.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh](../../.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh) to expose the existing `[bridge state]` formatter with an optional `--with-recommendation` flag that toggles the new `Drift:` and `Next:` lines per [research D4](./research.md#d4--print-contract-who-emits-the-new-drift-and-next-lines) + [contracts/bridge-status-output.md R-OUT-7..R-OUT-14](./contracts/bridge-status-output.md). Existing callers (`update-handoff`, `guard-command`) MUST NOT receive the flag — verify by running `bash tests/run-all.sh` and confirming all existing 008-contract tests stay green (SC-008).
- [ ] T006 [P] Mirror T005 in [.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1](../../.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1): add a `-WithRecommendation` switch parameter that toggles the same two conditional lines. Parallel to bash flavor; same print order, same field labels.

**Checkpoint**: Schema accepts `artifacts_sha256`; shared print helpers can emit the new lines on demand. US1 and US2 work can now begin in parallel.

---

## Phase 3: User Story 1 — On-demand bridge state introspection (Priority: P1) 🎯 MVP

**Goal**: Developers and agents resuming an interrupted session can identify the active feature, status, owner, pending task count, drift state (when applicable), and recommended next command via a single read-only command invocation that completes in under 1 second.

**Independent Test**: Run `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` from any state (no handoff, ready, executing, complete, blocked, corrupted) and confirm the printed block matches the corresponding acceptance scenario from [contracts/bridge-status-output.md](./contracts/bridge-status-output.md) §Acceptance Scenarios + the decision-table vectors V1..V14 from [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md). Two consecutive invocations produce byte-identical stdout (SC-003); `superpowers-handoff.json` mtime and `bridge-events.jsonl` line count are unchanged before and after.

### Implementation for User Story 1

- [ ] T007 [P] [US1] Create [.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh](../../.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh): argument parser (`--json`, `--actor`, `--no-drift-check`) following the case-loop pattern from `guard-command.sh`; source `common-actor-resolution.sh` + `bridge-state.sh`; resolve repo root + actor; read `.specify/superpowers-handoff.json` handling missing/parseable/malformed per [FR-004](./spec.md) + [R-OUT-13/14](./contracts/bridge-status-output.md); compute pending-tasks count (reuse the existing regex from bridge-state); evaluate the 12-rule decision table inline per [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md); print 7-line human block OR single-line JSON per `--json`. Stay within SC-010 (a): ≤ 200 lines. Set `chmod +x`.
- [ ] T008 [P] [US1] Create [.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1](../../.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1): mirror T007 in PowerShell — `[CmdletBinding()]` param block with `-Json`, `-Actor`, `-NoDriftCheck`; use `ConvertFrom-Json`/`ConvertTo-Json` for parsing; `Get-FileHash -Algorithm SHA256` available for the drift line but `bridge-status` itself does not perform writes; same 12-rule decision table; same 7-line print order. Stay within SC-010 (b): ≤ 200 lines.
- [ ] T009 [US1] Create [tests/test-bridge-status.sh](../../tests/test-bridge-status.sh) initial scaffold covering US1 only: scenarios S-OUT-1, S-OUT-3, S-OUT-4 + decision-table vectors V1, V2, V3, V4, V5, V11 from [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md). Each assertion fixtures up a temp `.specify/superpowers-handoff.json` + temp feature_directory layout, runs `bridge-status.sh`, and diffs the captured output against the expected block. Include the SC-003 idempotency check: run bridge-status twice in unchanged state, `diff` outputs, assert empty. Add the run to the existing test discovery loop in `tests/run-all.sh` (no edit needed if the loop is `for f in tests/test-*.sh`).

**Checkpoint**: `bridge-status` works against any handoff/feature state; the 7-line block prints correctly; the decision-table recommendations are correct for 6 of the 14 vectors (US2-dependent vectors deferred to Phase 4). MVP scope satisfied — US1 is independently deployable.

---

## Phase 4: User Story 2 — SHA256 artifact-drift detection on phase transitions (Priority: P2)

**Goal**: Mid-execution edits to `spec.md` / `plan.md` / `tasks.md` between an `executing` handoff write and a `complete` handoff write surface as a stderr warning + `artifact_drift_detected` event on the complete write, and as a `Drift:` line on subsequent `bridge-status` invocations. The transition is not blocked; exit codes stay 0.

**Independent Test**: With US1 already in place, write the handoff to `status: executing` for the current feature (the script snapshots hashes). Modify `tasks.md` by appending a line. Run `bridge-status` — it must show `Drift: tasks.md` on the new line. Transition the handoff to `complete` via `update-handoff --status complete` — stderr must contain exactly one `[bridge] WARNING:` line; the event log gains exactly one `artifact_drift_detected` entry; exit code is 0. A pre-0.7.0 handoff (fixture) processed by v0.7.0+ tooling does NOT emit a false-positive drift warning.

### Implementation for User Story 2

- [ ] T010 [P] [US2] Extend [.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh](../../.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh) per [spec.md FR-005 + FR-006 + FR-008](./spec.md) and [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md): on every `executing` or `complete` write, compute `sha256sum` for the three source-of-truth files (emit JSON `null` for missing files); merge into handoff JSON as `artifacts_sha256: {...}` via `jq --argjson` reusing the existing temp-file + `mv` atomic write pattern. On `complete` writes only: read the prior handoff snapshot BEFORE merging fresh hashes, compare per-file in canonical order (`spec.md, plan.md, tasks.md`), emit exactly one stderr `[bridge] WARNING: artifact drift since executing snapshot: <comma-joined filenames> (sha256 mismatch)` line on any mismatch, append exactly one `artifact_drift_detected` event to `.specify/bridge-events.jsonl` per [contracts/artifact-drift-event.md R-EVT-1..R-EVT-8](./contracts/artifact-drift-event.md). Preserve exit code 0. Stay within SC-010 (c): ≤ 60 added lines.
- [ ] T011 [P] [US2] Mirror T010 in [.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1](../../.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1): use `Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash | ForEach-Object { $_.ToLower() }` for each artifact; use `ConvertFrom-Json` → splat → `ConvertTo-Json -Depth 10` for the merge; same atomic temp+`Move-Item` pattern; same canonical artifact order; same stderr warning shape; same event shape. Stay within SC-010 (d): ≤ 60 added lines.
- [ ] T012 [US2] Add drift-check support to bridge-status helpers: T007's `bridge-status.sh` and T008's `bridge-status.ps1` MUST now compute drift when the live handoff has `artifacts_sha256` AND `--no-drift-check` is not set, then surface mismatches as the `Drift:` line per [contracts/bridge-status-output.md R-OUT-9](./contracts/bridge-status-output.md). Read-only enforcement: bridge-status MUST NOT call any write path; MUST NOT emit the `[bridge] WARNING:` stderr line; MUST NOT append to `bridge-events.jsonl` (FR-007, FR-008 second sentence). This task may already be done as part of T007/T008 — verify and otherwise add the remaining drift code path here.
- [ ] T013 [P] [US2] Create the pre-0.7.0 fixture at [tests/fixtures/pre-070-handoff.json](../../tests/fixtures/pre-070-handoff.json): a literal v0.5.0/v0.6.0-shaped handoff document with `status: executing`, `schema_version: 1`, populated `source_of_truth` block, and NO `artifacts_sha256` key. Hand-author or copy from a real prior-release handoff scrubbed of feature-specific paths. Used by T014's SC-009 backward-compat assertion.
- [ ] T014 [US2] Extend [tests/test-bridge-status.sh](../../tests/test-bridge-status.sh) (the file created in T009) with US2 coverage: acceptance scenarios S-EVT-1, S-EVT-2, S-EVT-3, S-EVT-4, S-EVT-5, S-EVT-6 from [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md); decision-table vectors V6, V7, V8, V9, V10, V12, V13, V14 from [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md); FR-007/FR-008 read-only assertion (bridge-status invocation during drift must not append to `bridge-events.jsonl`); FR-013 backward-compat fixture assertion (load `tests/fixtures/pre-070-handoff.json`, run bridge-status, assert no crash, no drift line, exit 0); FR-006 stderr-warning-format assertion (parse the `[bridge] WARNING:` line and verify filename list ordering). All 14 V-vectors from US1+US2 combined must now pass per SC-004 exhaustiveness.

**Checkpoint**: Both pillars functional end-to-end. Drift events appear in the audit log; warnings fire on `complete`; bridge-status surfaces drift passively. The smoke test exercises the full 14-vector decision table and all 11 acceptance scenarios. The feature is ready for release polish.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, version bumps, lightness-budget audit, and the mandatory end-user sandbox verification. None of these block US1 or US2 functionality; they prepare the v0.7.0 release.

- [ ] T015 [P] Append one bullet (≤ 1 line each, per FR-011) to [.claude/skills/speckit-superpowers-bridge/SKILL.md](../../.claude/skills/speckit-superpowers-bridge/SKILL.md) AND [.agents/skills/speckit-superpowers-bridge/SKILL.md](../../.agents/skills/speckit-superpowers-bridge/SKILL.md) referencing the new `bridge-status` command. Suggested wording: `- bridge-status.{sh,ps1} (v0.7.0+) — read-only state introspection + recommended-next-command + drift detection.` Verify with `git diff --stat .claude/skills/speckit-superpowers-bridge/SKILL.md .agents/skills/speckit-superpowers-bridge/SKILL.md` showing exactly ` | 1 +` (no behavioral changes).
- [ ] T016 [P] Update [README.md](../../README.md) (≤ 13 added lines) and [README.zh-CN.md](../../README.zh-CN.md) (≤ 12 added lines) per FR-014: append one bullet to the existing collapsed Skills/Commands details section mentioning `bridge-status` with the absolute script path. Total combined delta ≤ 25 lines (SC-010 (g) implicit budget). Mirror EN ↔ zh-CN content.
- [ ] T017 [P] Bump [.specify/extensions/speckit-superpowers-bridge/extension.yml](../../.specify/extensions/speckit-superpowers-bridge/extension.yml) `version` from `0.6.0` to `0.7.0`. Bump [marketplace/catalog-entry.json](../../marketplace/catalog-entry.json) `version` from `0.6.0` to `0.7.0`. DO NOT modify `download_url` — permanently aliased to `releases/latest/download/speckit-superpowers-bridge.zip` per v0.6.0 decoupling (constitution §VI Q2). Verify with `jq -r '.version' marketplace/catalog-entry.json` returns `"0.7.0"` and `grep -E '^download_url:' marketplace/catalog-entry.json` (or equivalent) is unchanged from main.
- [ ] T018 Prepend a new `## [0.7.0] — YYYY-MM-DD` section to [CHANGELOG.md](../../CHANGELOG.md) per FR-014 covering: `### Added` (bridge-status.{sh,ps1}, artifacts_sha256 optional field on handoff, artifact_drift_detected event type), `### Changed` (none beyond version metadata), `### Compatibility` (pre-0.7.0 handoffs tolerated read-side, schema_version remains 1, additive on `additionalProperties: true`). Cite [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md) for the schema delta.
- [ ] T019 Run the full smoke suite and confirm SC-006 + SC-008: `time bash tests/run-all.sh` must complete in under 10 seconds AND all existing tests + the new `test-bridge-status.sh` must pass. If any existing test broke, the change in T005/T010/T011 violated SC-008 (the 008 print contract) — fix the regression by gating new output behind the helper-arg flag from T005/T006 instead of modifying the existing caller paths.
- [ ] T020 Lightness-budget audit per SC-010 (a..i). Run a single audit command and capture results:
  ```bash
  wc -l .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh \
        .specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1
  git diff main --stat .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh \
                       .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1
  git diff main --name-only -- .claude/skills/speckit-* .agents/skills/speckit-*
  ```
  Verify: (a) bash bridge-status ≤ 200 lines, (b) PowerShell bridge-status ≤ 200 lines, (c) update-handoff bash delta ≤ 60 added lines, (d) update-handoff PowerShell delta ≤ 60 added lines, (e) exactly one new event type definition (grep `artifact_drift_detected` returns matches only in expected files), (f) exactly two new files in bridge package per flavor (bridge-status + new test), (g) zero new state files (no new entries under `.specify/` besides expected event log appends), (h) zero new commands at slash/extension layer (grep `.specify/extensions.yml` for changes — none expected), (i) zero edits to vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` (only `speckit-superpowers-bridge/` files appear in the diff).
- [ ] T021 Commit on `012-bridge-status-and-hash` and open the PR per [quickstart.md Step 9](./quickstart.md) — title `v0.7.0 — bridge-status command + SHA256 handoff artifact hash`; body cites Constitution VI gate Q1+Q2 answers for both pillars, the SC-010 audit output from T020, and the test plan checklist. Verify PR opens cleanly via `gh pr create` and CI (if any) passes.
- [ ] T022 (After PR merges to main and v0.7.0 tag is pushed per [quickstart.md Step 10](./quickstart.md)): Execute End-User Verification Sandbox per constitution §"End-User Verification Sandbox" and [quickstart.md Step 11](./quickstart.md): in `..\test_specify_superpower`, `specify init . --integration claude --script sh --here --force`; `specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`; drive one complete bridge cycle (specify → plan → tasks → handoff `executing` → inject drift in tasks.md → run bridge-status → confirm `Drift: tasks.md` → handoff `complete` → observe stderr warning + event log entry). Record outcome in `specs/012-bridge-status-and-hash/verification.md`: bridge SHA256, platform = WSL bash, pass/fail per US1 + US2 acceptance scenarios (per FR-015 + SC-007).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories. T004 (schema delta) and T005/T006 (shared print helper) must land first.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. Within US1: T007 + T008 in parallel (different flavors, different files), then T009 (tests reference T007's script).
- **User Story 2 (Phase 4)**: Depends on Foundational completion AND T007/T008 for the drift-display logic (T012 explicitly amends them). Within US2: T010 + T011 in parallel; T013 in parallel; T014 depends on T009 + T010 + T011 + T013.
- **Polish (Phase 5)**: Depends on US1 and US2 complete. T021 (PR) gates T022 (sandbox); T022 must complete before this feature's own handoff can transition to `complete`.

### Within-story task DAG

**US1**:

```
T007 (bash bridge-status) ──┐
                            ├──> T009 (tests for US1)
T008 (ps bridge-status)  ───┘
```

**US2**:

```
T010 (bash update-handoff) ──┐
T011 (ps update-handoff)  ───┤
T012 (drift in bridge-status) ──> T014 (tests for US2)
T013 (pre-070 fixture)    ───┘
```

**Polish**:

```
T015, T016, T017, T018 ──┐
                          ├──> T019 (smoke run) ──> T020 (audit) ──> T021 (PR) ──> [merge + tag] ──> T022 (sandbox)
all US1 + US2 done    ───┘
```

### Parallel Opportunities

- **Phase 1**: T002 and T003 in parallel after T001.
- **Phase 2**: T005 (bash) and T006 (powershell) in parallel; T004 (schema) independent of both — all three potentially parallel.
- **Phase 3 (US1)**: T007 and T008 in parallel (different files).
- **Phase 4 (US2)**: T010, T011, T013 all in parallel (different files); T012 sequentially after T007/T008.
- **Phase 5 (Polish)**: T015, T016, T017, T018 all in parallel.

---

## Parallel Example: User Story 1

```bash
# In the same terminal session (e.g., a parallel-task agent dispatcher), launch:
Task: "Create bash bridge-status.sh per spec FR-001..FR-004 and contract bridge-status-output.md"
Task: "Create powershell bridge-status.ps1 per spec FR-001..FR-004 and contract bridge-status-output.md"
# These touch different files (.sh vs .ps1) and have no shared mutable state.
# After both complete, dispatch:
Task: "Create tests/test-bridge-status.sh covering US1 scenarios S-OUT-1, S-OUT-3, S-OUT-4 and vectors V1..V5 + V11"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational) — schema delta + shared print helpers.
2. Complete Phase 3 (US1) — `bridge-status.{sh,ps1}` + initial test scaffold.
3. **STOP and VALIDATE**: `bash tests/run-all.sh` green, all 6 US1 vectors pass, the byte-identical idempotency check (SC-003) passes.
4. Demo: in a working session, `bash bridge-status.sh` from various handoff states shows the correct `Next:` recommendation. Drift line is omitted (correct — no `artifacts_sha256` exists yet).
5. US1 alone is a deployable MVP: developers gain on-demand state introspection. Could ship as v0.6.1 patch if US2 is deferred. (Per the spec, both pillars ship together as v0.7.0.)

### Incremental Delivery (full feature)

1. Complete Setup + Foundational + US1 (MVP).
2. Add US2 — drift detection on writes + drift display on reads.
3. **STOP and VALIDATE**: smoke suite covers all 14 vectors + 11 acceptance scenarios; sandbox-friendly mechanical drift injection works on a throwaway feature.
4. Polish + version bumps + sandbox verification → PR → merge → tag → release.

### Parallel Team Strategy

With multiple developers (or parallel agents):

1. One developer runs Phase 1 + Phase 2 (foundational + schema + shared helpers).
2. Once T004/T005/T006 land:
   - Developer A: US1 (T007, T008, T009).
   - Developer B: US2 backend logic (T010, T011, T013).
   - These two streams converge at T012 (drift display in bridge-status) and T014 (combined US2 tests).
3. Polish phase is single-owner — the maintainer who cuts the v0.7.0 release.

---

## Notes

- `[P]` tasks = different files, no shared mutable state.
- `[Story]` label maps each task to US1 (bridge-status command) or US2 (SHA256 drift).
- US1 is independently deployable; US2 extends but does not break US1.
- Tests are required per FR-012 — T009 (US1) and T014 (US2) live inside the same `tests/test-bridge-status.sh` file, exercised by the existing `tests/run-all.sh` discovery loop.
- Verify lightness budget (T020) BEFORE committing the PR (T021) — failing the budget means refactoring before merge, not after.
- Sandbox verification (T022) is the LAST task; it depends on the published release artifact which only exists after PR-merge + tag-push.
- Commit cadence: per [quickstart.md Step 9](./quickstart.md), a single bundled commit at PR-creation time. Do not commit each task individually.
- Avoid: editing vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` files (constitution §II + §V); modifying `marketplace/catalog-entry.json.download_url` (v0.6.0 decoupling permanent); bumping `schema_version` (additive on v1 per research D2); adding new state files (SC-010 (g) zero new state).
