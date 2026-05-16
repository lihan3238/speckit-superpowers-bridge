﻿﻿﻿---

description: "Tasks for feature 008-bridge-hardening-0-5-0 —bridge drift hardening + v0.5.0 cleanup release (D1 mac defer inherited; D2 catalog research; G1/G2/G3 alignment; Q1 main merge; Q2 catalog issue rotation; Q3 bridge hardening root-fix)"
---

# Tasks: Bridge Hardening & 0.5.0 Cleanup Release

**Input**: Design documents from `specs/008-bridge-hardening-0-5-0/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: TDD is mandatory for US1 (Phase A in plan.md). One new regression test file under `tests/`. Existing smoke tests must continue passing.

**Organization**: 7 phases. Setup + Foundational + 5 user-story phases + Polish. Phase order matches plan.md A-G with the polish phase folded into the final user-story phase (US5/release) and into a closing Cross-Cutting / branch-merge phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5). Setup/Foundational/Polish phases have NO story label.
- Include exact file paths in descriptions

## Path Conventions

- Bridge runtime (this release will modify): `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/`
- Tests: `tests/` (PowerShell harness driving bash via path translation)
- Skill peers: `.agents/skills/speckit-superpowers-bridge/`, `.claude/skills/speckit-superpowers-bridge/`
- Marketplace: `marketplace/`
- Specs being cleaned up: `specs/003-bridge-cross-platform-scripts/`, `specs/007-catalog-distribution-polish/`
- This spec: `specs/008-bridge-hardening-0-5-0/`

---

## Phase 1: Setup (Shared infrastructure)

**Purpose**: Capture baseline state so post-implementation deltas are auditable.

- [x] T001 Confirm clean working tree on branch `008-bridge-hardening-0-5-0` via `git status -sb`; abort with operator-confirmation prompt if anything is staged but uncommitted. Record current `git rev-parse HEAD` in a scratchpad note for use in T003 baseline diffs. *(HEAD=29235e2; tree had only Phase 1 design-package changes as expected)*
- [x] T002 Confirm `.specify/feature.json` points to `specs/008-bridge-hardening-0-5-0` and `.specify/superpowers-handoff.json` is either absent or in a benign state (007 already `complete`). Note: do NOT open the 008 handoff yet —that happens via the bridge after `/speckit-tasks` finishes. *(verified before bridge opened 008)*
- [x] T003 Capture pre-implementation baseline values for SC-005 and SC-006 to `specs/008-bridge-hardening-0-5-0/baseline.txt` (gitignored or scratch —not committed). Commands: `git diff v0.4.3..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/ | wc -l` and `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin`. These let later steps verify "no regression introduced" vs the v0.4.3 starting point. *(SC-005=0 lines; SC-006=96e3dffe—identical to v0.4.1 baseline)*

---

## Phase 2: Foundational (Blocking prerequisites for all stories)

**Purpose**: Test fixtures and the new shared helper's stub files must exist before US1 implementation can be TDD-driven. No user story may begin until Phase 2 completes.

**CRITICAL**: T004-T006 are TDD prerequisites for US1. T007 is the empty-stub for the helper (RED-phase placeholder so update-handoff/guard-command can `dot-source` / `source` it before the helper body exists).

- [x] T004 [P] Create directory `tests/fixtures/` and an empty `.gitkeep` so the dir exists on a fresh clone.
- [x] T005 [P] Author `tests/fixtures/tasks-with-pending.md`: a synthetic tasks.md containing 3 `- [ ] T###` lines outside any deferred section, 2 `- [x] T###` lines, and 2 `- [ ] T###` lines under a `## Deferred (later cycle)` H2 header. Used by SC-001 / SC-002 / SC-004 assertions.
- [x] T006 [P] Author `tests/fixtures/tasks-all-deferred.md`: synthetic tasks.md with 5 `- [ ] T###` lines all under a `## Deferred` section. Used to assert no warning fires (SC-002 false-positive prevention).
- [x] T007 Create stub files `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1` and `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh`. Each contains only a comment header + an empty function definition (PS: `function Write-BridgeState { Write-Host '[bridge state] (stub)' }`; bash: `bridge_state() { echo '[bridge state] (stub)'; }`). Stubs exist so T011-T012 can wire dot-sourcing without breaking.

**Checkpoint**: Fixtures + stub helpers in place. US1 TDD can begin.

---

## Phase 3: User Story 1 —Bridge Drift Hardening (Priority: P1) 🎯 MVP

**Goal**: Surface authoritative bridge state (`feature_directory`, `status`, `artifact_owner`, `actor`, `prior_actor` when differs, `Pending tasks: N`) on every bridge-script invocation. Emit a warning to stderr when transitioning to `complete` with non-deferred unchecked tasks. Log `prior_actor` to the event log on every handoff transition.

**Independent Test**: `tests/test-bridge-state-summary.ps1` exits 0 with all SC-001 / SC-002 / SC-003 assertions passing on both PowerShell and bash flavors. Manual: drive a synthetic handoff per [quickstart.md Playbook 1](./quickstart.md), observe the state-summary block and the deliberate-mismatch warning.

### Tests for User Story 1 (TDD —write FIRST, must FAIL before implementation) ⚠️

- [x] T008 [P] [US1] Author `tests/test-bridge-state-summary.ps1` covering SC-001 (pending count visible in first 20 lines), SC-002 (warning fires on complete-with-unchecked AND no false-positive when all unchecked are deferred), SC-003 (event log has `prior_actor` field, jq-parseable for the bash flavor —falls back to PS JSON parse if jq missing). Test harness pattern: copy structure from `tests/test-handoff-shape.ps1` including the v0.4.2 B2 path-translation strategy chain for the bash flavor and graceful skip-on-failure semantics. Run the test once —expect RED (failing) because helper is still a stub.

### Implementation for User Story 1

- [x] T009 [P] [US1] Implement PowerShell helper `bridge-state.ps1` at `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1` per [contracts/bridge-state-summary.md](./contracts/bridge-state-summary.md) and [research.md R1/R2/R3](./research.md). Functions exposed: `Write-BridgeStateSummary -HandoffPath <path> -TasksPath <path> -PriorActor <string> -OutputStream <stdout|stderr>` and `Get-PendingTaskCount -TasksPath <path>` (separate so it can be unit-tested independently). Helper imports `common-actor-resolution.ps1` for actor resolution parity.
- [x] T010 [P] [US1] Implement bash helper `bridge-state.sh` at `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh`. Functions: `write_bridge_state_summary <handoff_path> <tasks_path> <prior_actor> <stream>` and `get_pending_task_count <tasks_path>`. Use `awk` per [research.md R4](./research.md) with `IGNORECASE=1` for the gawk path; fall back to a `tolower()` form if `awk` is the POSIX subset. Same regex as PS per [research.md R2](./research.md).
- [x] T011 [US1] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1`: dot-source `bridge-state.ps1` near the existing `common-actor-resolution.ps1` source; capture `prior_actor` from handoff.json BEFORE the write; on successful write, append `prior_actor` to the JSONL event-log entry; if explicit `-Reason` was supplied, prepend `actor change <prior> 鈫?<new>; ` when actors differ; after the JSON write completes, invoke `Write-BridgeStateSummary` and (per FR-003) detect `complete`-with-`Pending > 0` and write the WARNING line to stderr. Depends on T009 (helper must exist).
- [x] T012 [US1] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh`: identical semantic changes as T011 but in bash. Source `bridge-state.sh`. Use `jq` for the JSON manipulation (already a project dependency). Depends on T010.
- [x] T013 [US1] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`: after the existing 5-rule evaluation and event-log append, invoke `Write-BridgeStateSummary` prefixed with `[bridge state]` (no warning emission —guard never transitions status). Depends on T009.
- [x] T014 [US1] Modify `.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh`: identical semantic changes as T013 but bash. Depends on T010.
- [x] T015 [US1] Run `tests/test-bridge-state-summary.ps1`. MUST exit 0 with `(ps, bash)` or `(ps)` summary line. If bash flavor skips with reason "awk not found" or "jq not found", that is acceptable per the v0.4.2 B2 chain; PowerShell flavor MUST pass either way. Depends on T011-T014.
- [x] T016 [US1] Run all 3 existing smoke tests (`tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`). All MUST still pass —confirms the additive changes (new printed lines, new event-log field) did NOT break existing shape assertions. If `test-handoff-shape.ps1` asserts on stdout content of update-handoff calls, adjust it minimally to accept the new state-summary lines.
- [x] T017 [P] [US1] Refresh `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` step descriptions to mention that the new bridge-script output begins with a `[bridge state]` block; do NOT add a banner per Clarifications Q3=C. Both peers MUST stay byte-equivalent except for path-style differences (slash for both).

**Checkpoint**: US1 fully functional. The bridge now surfaces state and warns on drift. SC-001 / SC-002 / SC-003 / SC-013 verifiable. T008 RED 鈫?GREEN cycle complete. Existing smoke tests pass.

---

## Phase 4: User Story 2 —Reality Alignment of 007 and 003 Artifacts (Priority: P2)

**Goal**: tasks.md state matches reality. Specifically: 007 T022-T028 checked with evidence; 003 user-side verification tasks moved under a clearly-labeled `## Deferred` H2; 007 verification.md gains a `## Gate evidence` subsection recording SC-005 + SC-006 computed values.

**Independent Test**: After US2: `grep -c '^- \[ \] T' specs/007-catalog-distribution-polish/tasks.md` returns 鈮?1 (only the optional T029 may remain). `grep -c '^- \[ \] T' specs/003-bridge-cross-platform-scripts/tasks.md` returns a number matching only deferred user-side verification tasks (which now live under `## Deferred (...)`). `grep -A 5 '## Gate evidence' specs/007-catalog-distribution-polish/verification.md` shows SC-005 and SC-006 rows.

### Implementation for User Story 2

- [x] T018 [US2] Edit `specs/007-catalog-distribution-polish/tasks.md`: mark T022, T023, T024, T025, T026, T027, T028 as `[x]` and append a one-line evidence pointer to each (e.g., `*(handoff snapshot 20260516T0735280570309Z-ready)*`, `*(commit 29235e2)*`, `*(SC-005 baseline: 0 lines diff)*`). For T029, either mark `[x]` if US3's catalog-issue rotation closes it OR move it under a new `## Deferred` H2 at the bottom of the file with the tag "Optional, deferred to v0.5.0+ if Q5 minor/major policy says skip-on-patch".
- [x] T019 [US2] Edit `specs/003-bridge-cross-platform-scripts/tasks.md`: scan for `^- \[ \] T` lines that map to user-side cross-platform verification work (T065 Linux end-to-end, T066 macOS end-to-end, and any other user-machine-bound tasks). Move those lines under a new `## Deferred (user-side verification, awaiting future cycles)` H2 at the bottom of the file. Tag each moved line with a one-line note like `Deferred because: requires a real macOS host that is not currently available.` All other `[ ]` lines (covering v0.4.2 work that actually shipped) should become `[x]` with brief evidence pointers (e.g., commit ref).
- [x] T020 [US2] Append `## Gate evidence` subsection to `specs/007-catalog-distribution-polish/verification.md` per [research.md R8](./research.md) schema. Compute values: SC-005 = `git diff v0.4.2..v0.4.3 -- .specify/extensions/speckit-superpowers-bridge/scripts/ | wc -l` (expected: 0); SC-006 = `git ls-tree -r v0.4.3 specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin` (capture full sha256). Both dated 2026-05-16, operator `claude`.
- [x] T021 [US2] Run the US1 drift-hardening helper against 007 and 003 to verify alignment: `pwsh -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1 -Action speckit.tasks -Actor claude` (or any guard invocation pointing at 007 / 003 via temporary feature.json swap). The `[bridge state]` block MUST report `Pending tasks: 0` (or only the count of intentionally-deferred items now under `## Deferred`). If non-zero, return to T018/T019 and address the residual.

**Checkpoint**: 007 + 003 artifacts reflect actual state. SC-004 + SC-005 (the v0.5.0 version of these —they refer to the v0.5.0 SCs which test the same conditions). The bridge now reports clean.

---

## Phase 5: User Story 3 —Official Catalog Update Path (Priority: P2) [research + materials only; issue-filing deferred to Phase 7]

**Goal**: Research upstream catalog-update flow as of 2026-05-16, document the policy in `marketplace/README.md`, and refresh all marketplace artifacts to v0.5.0. Filing the actual v0.5.0 catalog-update issue and closing the v0.4.3 issue happens AFTER the v0.5.0 tag publishes (Phase 7) so the issue body carries the real SHA256.

**Independent Test**: `marketplace/README.md` contains a `## Catalog update policy` section with an upstream permalink citation dated 2026-05-16 and a 3-row policy table per [contracts/catalog-update-policy.md](./contracts/catalog-update-policy.md). `marketplace/{catalog-entry.json, extension-submission-body.md, extensions-readme-row.md}` all reference v0.5.0.

### Implementation for User Story 3

- [x] T022 [US3] Research upstream catalog-update flow per [research.md R5 + R6](./research.md). Targets: `https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md` (capture commit SHA at fetch time for permalink), `https://github.com/github/spec-kit/blob/main/docs/community/extensions.md`, PR #2586 thread, open + closed issues mentioning `catalog.community.json` or `extensions/catalog`. Record findings (URL + 1-3 line summary each) in a scratch note. Expected hypothesis (research.md): one issue per release, no automated path —confirm or disprove.
- [x] T023 [US3] Edit `marketplace/README.md`: add `## Catalog update policy` section per [contracts/catalog-update-policy.md](./contracts/catalog-update-policy.md) template. Fill in: `As of 2026-05-16`, the one-line summary from T022 research, the permalink-pinned `Source:` URL, the 3-row bump-magnitude table (Patch 鈫?Skip, Minor 鈫?File, Major 鈫?File per Q5=C), rationale paragraph linking back to `specs/008-bridge-hardening-0-5-0/spec.md 搂 Clarifications Q5`, and "How to file" steps. Existing R-POL-6 prohibition on PRs against `catalog.community.json` MUST appear verbatim.
- [x] T024 [P] [US3] Edit `marketplace/catalog-entry.json`: bump `version` to `"0.5.0"`; update `download_url` to `https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.5.0/speckit-superpowers-bridge-v0.5.0.zip`; update `updated_at` to current UTC. Preserve the v0.4.3 shape (no `git` in `requires.tools`; no per-tool `description`).
- [x] T025 [P] [US3] Edit `marketplace/extension-submission-body.md`: bump version to `0.5.0`; replace versioned URL with `v0.5.0` form; keep stable-alias URL as-is (path unchanged); replace SHA256 with the placeholder string `<filled-by-workflow-on-tag>` until T039 fills it; update `### Testing Details` `Release ZIP SHA256:` to the same placeholder; update `Release workflow:` URL placeholder for the v0.5.0 run.
- [x] T026 [P] [US3] Edit `marketplace/extensions-readme-row.md`: confirm columns match the upstream `docs/community/extensions.md` shape captured in T022 research (Name | Description | Category | Permissions | Repository). If upstream's shape changed since 2026-05-15 (PR #2586), realign; otherwise leave intact.

**Checkpoint**: marketplace materials are v0.5.0-ready. Catalog-issue-filing tasks (T046, T047) wait for the actual tag.

---

## Phase 6: User Story 4 —Release prep (Priority: P2) [branch consolidation moved to Phase 8 per plan Phase G]

**Goal**: Bump the extension version + write the CHANGELOG entry that declares v0.4.2 as the new minimum direct-upgrade baseline + prune AGENTS.md references to pre-0.4.2 versions. Run pre-tag validators green.

**Independent Test**: `extension.yml` `extension.version` is `"0.5.0"`. `CHANGELOG.md` has a complete `[0.5.0] - 2026-05-16` section including `### Compatibility` subsection. `AGENTS.md` has no references to v0.4.0 or v0.4.1 outside historical context. `scripts/release/validate-release-readiness.ps1 -Version 0.5.0` exits 0.

### Implementation for User Story 4

- [x] T027 [P] [US4] Edit `.specify/extensions/speckit-superpowers-bridge/extension.yml`: bump `extension.version` from `0.4.3` to `0.5.0`. Confirm there is no second `extension.yml` elsewhere in the repo that needs synchronizing (`grep -rn 'version.*0\.4\.3' --include='extension.yml' .`).
- [x] T028 [US4] Append `[0.5.0] - 2026-05-16` section to `CHANGELOG.md`, immediately above the existing `[0.4.3]` entry. Subtitle: "Bridge drift hardening + v0.5.0 cleanup release". Sections under it: `### Added` (US1 state-summary block, `prior_actor` event-log field, `tests/test-bridge-state-summary.ps1`); `### Changed` (US2 alignment of 007/003 tasks.md + gate-evidence record; US3 catalog policy documented in `marketplace/README.md`; AGENTS.md pruned of pre-0.4.2 refs); `### Compatibility` MUST be a dedicated `###` subsection containing (a) `v0.4.2 is the new minimum direct-upgrade baseline`; (b) handoff schema remains byte-stable, v0.4.2/v0.4.3 users upgrade with no migration; (c) v0.4.0/v0.4.1 users should upgrade through v0.4.2 first or re-install fresh. Add `[0.5.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.5.0` footnote link at the bottom and update `[Unreleased]` base ref to v0.5.0.
- [x] T029 [P] [US4] Edit `AGENTS.md`: search for references to `0.4.0`, `0.4.1`, `v0.4.0`, `v0.4.1` outside of CHANGELOG / historical / dev-disclosure contexts. Remove them or rephrase to point at v0.4.2 as the baseline. Add a one-line "Compatibility baseline" note (or update existing one) declaring v0.4.2 as the minimum direct-upgrade source per CHANGELOG `[0.5.0] 搂 Compatibility`. Keep the bridge protocol sections intact.
- [x] T030 [US4] Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/validate-release-readiness.ps1 -Version 0.5.0`. MUST exit 0. If it fails (file-count parity, `.gitattributes`, CHANGELOG header parsing, version-string mismatch), fix BEFORE proceeding. Depends on T027 + T028.
- [x] T031 [US4] Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/test-validate-release-readiness.ps1`. MUST exit 0 (self-test of the validator).
- [x] T032 [US4] Run all 3 in-repo smoke tests one final time on the current dev box. All MUST exit 0. This is the last gate before tagging —if any test fails, return to the relevant US phase and fix.

**Checkpoint**: Release-ready. T030 + T031 + T032 all green.

---

## Phase 7: User Story 5 —Tag, release, sandbox verification (Priority: P3 in spec, but blocks completion)

**Goal**: Tag v0.5.0, watch the GH Actions workflow ship the release, capture the SHA256, drive sandbox installs on Windows PS + WSL Linux bash (macOS PENDING), exercise the US1 drift-hardening output during the sandbox runs (FR-019 deliberate-mismatch test), and record the verification.md rows. File the v0.5.0 upstream catalog issue and close the v0.4.3 issue. This phase consumes the deferred tails of US3 (issue filing) and US4 (verification) per [plan.md 搂 Implementation strategy](./plan.md).

**Independent Test**: `gh release view v0.5.0` shows both ZIP assets uploaded with matching digests. `specs/008-bridge-hardening-0-5-0/verification.md` has `## v0.5.0` with 3 rows (Windows PS PASS + WSL Linux PASS + macOS PENDING). The v0.4.3 catalog-update issue against `github/spec-kit` is closed; a v0.5.0 issue is open with the FR-011 body.

### Tag + workflow + assets

- [x] T033 [US5] Commit Phase 1-6 work in logical groups. Suggested chain: (1) `feat(bridge): drift hardening helper + state summary + prior_actor` (T007-T017); (2) `docs(specs): align 007 + 003 tasks.md with shipped state, add gate evidence` (T018-T021); (3) `docs(marketplace): document catalog-update policy + bump materials to v0.5.0` (T022-T026); (4) `release(bridge): bump to 0.5.0 —drift hardening + compat baseline reset to v0.4.2` (T027-T029). All commits include `Signed-off-by` if your local config emits it; no `--no-verify` regardless of cause.
- [x] T034 [US5] Push to `origin/008-bridge-hardening-0-5-0`.
- [x] T035 [US5] Create annotated tag: `git tag -a v0.5.0 -m "v0.5.0 —bridge drift hardening + cleanup release (Q3 root-fix; G1/G2/G3 alignment; D2 catalog policy; Q1 compat baseline to v0.4.2)"`. Push the tag: `git push origin v0.5.0`. The workflow at `.github/workflows/release.yml` auto-triggers.
- [x] T036 [US5] Watch the workflow: `gh run watch <id> --exit-status`. MUST complete green in 鈮?60s. Capture the SHA256 from the workflow's "Build extension ZIP" step Summary OR the final job Summary.
- [x] T037 [US5] Verify the release on GitHub: `gh release view v0.5.0 --json assets,tagName --jq '{tag, assets: [.assets[] | {name, size, state}]}'`. MUST show two `state: "uploaded"` assets (`speckit-superpowers-bridge-v0.5.0.zip` AND `speckit-superpowers-bridge.zip`), same size, same `digest` (sha256:... line in the assets array if `--json digest` is fetched separately).

### Sandbox runs (manual / interactive)

- [x] T038 [US5] Windows PowerShell sandbox run per [quickstart.md Playbook 2 Step 2](./quickstart.md). At `..\test_specify_superpower`: clean 鈫?`specify init . --integration claude --script ps --here --force` 鈫?install from the stable-alias URL 鈫?drive one full bridge cycle. Confirm installed version is `0.5.0`, both short and canonical skill aliases are present, PowerShell handoff cycles cleanly. **Observe the `[bridge state]` block** in every bridge-script output and capture a representative one for the verification.md Notes column.
- [x] T039 [US5] FR-019 deliberate-mismatch test on Windows: in the sandbox project, transition the throwaway feature's handoff to `complete` while at least one task in its tasks.md is `- [ ] T### deliberately unchecked for FR-019` outside any deferred section. Confirm: `[bridge] WARNING: handoff is 'complete' but tasks.md has 1 unchecked tasks; review or move under a deferred section.` is written to stderr; exit code is 0. Capture the warning output for verification.md Notes.
- [x] T040 [US5] WSL Linux bash sandbox run per [quickstart.md Playbook 2 Step 4](./quickstart.md). Same sequence as T038 but `--script sh`; bash flavor scripts under `scripts/bash/` MUST be invoked (observable in `bridge-events.jsonl` or by `which awk` / `which bash` checks). Confirm version `0.5.0`, bash handoff cycles, drift output visible.
- [x] T041 [US5] FR-019 deliberate-mismatch test on WSL bash: same procedure as T039 but invoking `update-handoff.sh`. Confirm bash warning text matches PS verbatim (cross-flavor parity per Constitution Principle III).
- [x] T042 [US5] Create `specs/008-bridge-hardening-0-5-0/verification.md` with a single `## v0.5.0` section per the schema in `../003-bridge-cross-platform-scripts/contracts/verification-record.md`. Three rows: `windows-powershell` PASS with sha256 from T036 and operator `claude` (or `codex` if Codex ran it), Notes mentioning the bridge-state block was observed AND the FR-019 warning fired; `wsl-linux-bash` PASS with same sha and analogous notes; `macos-bash` PENDING with text "no host available; deferred per Clarifications Q1 of 008 inheriting v0.4.2 / v0.4.3". This is the FR-018 + FR-019 + FR-020 deliverable.
- [x] T043 [US5] Commit verification.md: `verify(bridge): record v0.5.0 sandbox run (Windows PS + WSL Linux PASS; macOS pending; FR-019 drift warning observed)`. Push.

### Catalog issue rotation (US3 tail per [plan.md 搂 Phase F](./plan.md))

- [x] T044 [P] [US5] Compose the v0.5.0 catalog-update issue body using `marketplace/extension-submission-body.md` (refreshed in T025 + filled with the real SHA256 from T037). Open the issue against `github/spec-kit` via `gh issue create --repo github/spec-kit --title "Extension Submission Update: speckit-superpowers-bridge v0.5.0" --body-file marketplace/extension-submission-body.md`. Body MUST reference the prior v0.4.3 issue with `Supersedes #<N>`.
- [x] T045 [P] [US5] Close the existing v0.4.3 catalog-update issue with `gh issue comment --repo github/spec-kit <issue-num> --body "Superseded by #<v0.5.0-issue-num> (v0.5.0 catalog update). Closing this older entry."` followed by `gh issue close --repo github/spec-kit <issue-num>`. If the operator does not have close permission, leave a closing-request comment and continue.

### Handoff completion

- [x] T046 [US5] Transition the 008 handoff to `complete`: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 -Status complete -Actor claude`. Observe the US1 state-summary block: `Pending tasks` MUST report 0 (or only the count of intentionally-deferred items under `## Deferred` in THIS spec's tasks.md). If non-zero, return to relevant phase and address the unchecked items. NO warning should fire —this is the self-validating proof that US1 + US2 together prevent the G1/G2/G3 class of bug.

**Checkpoint**: v0.5.0 published; sandbox PASS recorded; catalog issue rotated; handoff complete. SC-001..SC-012 (except SC-008) satisfied.

---

## Phase 8: Polish & Cross-Cutting Concerns —Main merge (Priority: tail of US4 per plan Phase G)

**Goal**: PR `008-bridge-hardening-0-5-0` 鈫?`main`. This carries the entire 003-cycle backlog (v0.4.0 through v0.4.3 history) plus the 008 cycle into main in one merge. After this, future cycles branch from a current `main` instead of from a long-running release branch.

**Independent Test**: `git log main..HEAD` from the 008 branch returns nothing once the PR merges. `main` tip is at `extension.yml.version: 0.5.0`.

- [x] T047 [US4] Open PR via `gh pr create --base main --head 008-bridge-hardening-0-5-0 --title "release(bridge): v0.5.0 —drift hardening + cleanup tail + main consolidation" --body "$(cat <<'EOF'\n## Summary\n- US1: Bridge drift hardening (helper + state summary + prior_actor + FR-003 warning)\n- US2: Realigned 007 + 003 tasks.md with shipped state; gate-evidence record\n- US3: Catalog update policy documented; minor/major-only issue filing\n- US4: v0.5.0 baseline; v0.4.2 = new minimum direct-upgrade; AGENTS.md pruned\n- US5: Sandbox PASS on Windows PS + WSL Linux; macOS PENDING; FR-019 warning verified\n- Q1 closure: this PR consolidates the long-running 003 release branch into main\n\n## Test plan\n- [x] tests/test-bridge-state-summary.ps1 green (PS + bash)\n- [x] All 3 existing smoke tests green\n- [x] scripts/release/validate-release-readiness.ps1 -Version 0.5.0 green\n- [x] v0.5.0 sandbox PASS recorded in specs/008-*/verification.md\n- [x] CHANGELOG [0.5.0] complete with Compatibility subsection\nEOF\n)"`. Verify PR is open and CI runs.
- [x] T048 [US4] If CI is green and the PR is mergeable, merge via `gh pr merge --merge` (keep the cycle history) or `--squash` (collapse into a single commit on main; preferred if upstream norm is squash). Confirm via `gh pr view <num>` that the PR is `MERGED`.
- [x] T049 [P] [US4] After merge, `git checkout main && git pull && git branch -d 008-bridge-hardening-0-5-0` locally. Optionally delete the remote branch: `git push origin --delete 008-bridge-hardening-0-5-0` (or use GH's "Delete branch" button on the merged PR page). Confirm `git log v0.5.0..main` is empty (the tag points into the now-merged history).
- [x] T050 [US4] Update `.specify/feature.json` to point at an empty / archived value once main is up to date AND the 008 handoff is `complete` from T046. Per existing protocol the next `/speckit-specify` will auto-archive and create a fresh entry; this task is mostly a sanity confirmation that nothing dangling references 008.

**Checkpoint**: Branch consolidated. `main` is the new release line. SC-008 satisfied. The "branch = release line" anti-pattern is broken; future cycles branch from `main`.

---

## Final verification (cross-cutting)

- [x] T051 Confirm all 13 SCs from spec.md hold: re-read each SC-001 through SC-013, tick them off mentally against the artifacts. Any SC that does NOT hold —return to its owning phase and fix.
- [x] T052 Confirm SC-013 north-star explicitly: `git diff v0.4.3..v0.5.0 --stat -- .specify/extensions/speckit-superpowers-bridge/` MUST show changes confined to scripts/ + SKILL.md peers. No new commands/, no new hooks/, no new sub-dirs. The new `bridge-state.{ps1,sh}` files are the only NEW files under scripts/; the rest are modifications to existing scripts.
- [x] T053 Append a `### Session 2026-05-16 (impl)` subsection or similar implementation-completion note to `specs/008-bridge-hardening-0-5-0/spec.md 搂 Clarifications` recording any decisions that surfaced during implementation that weren't already captured (especially any T047/T048 merge-mechanic deviation from Q2=B default).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No deps; T001 first then T002 + T003 [P].
- **Phase 2 (Foundational)**: Depends on Phase 1. T004-T007 can run partly in parallel (T004/T005/T006 are file-creation tasks on different paths).
- **Phase 3 (US1)**: Depends on Phase 2. Within US1: T008 (test) MUST be RED first; T009 + T010 in parallel; T011-T014 follow (each depends on its corresponding helper); T015 + T016 verify; T017 in parallel anywhere after T011.
- **Phase 4 (US2)**: Depends on Phase 3 because T021 uses the US1 helper to verify alignment.
- **Phase 5 (US3 head)**: Depends on Phase 2 only (research is independent of US1/US2). Can be worked in parallel with US2 if staffed.
- **Phase 6 (US4 head)**: Depends on Phases 3-5 because T028 CHANGELOG mentions US1/US2/US3 deliverables and T032 runs smoke tests that include the new test from T008.
- **Phase 7 (US5 + US3 tail + US4 mid)**: Depends on Phase 6 (must validate-release-readiness GREEN before tagging). T044/T045 catalog-issue work depends on T037 (real SHA256 needed for issue body).
- **Phase 8 (US4 tail / main merge)**: Depends on Phase 7 (cannot merge a release that hasn't shipped).
- **Final verification**: Depends on Phase 8.

### Within-phase TDD ordering (US1)

- T008 (RED) 鈫?T009 + T010 (helper bodies) 鈫?T011-T014 (wire into update-handoff + guard-command) 鈫?T015 (GREEN) + T016 (no regression).

### Parallel opportunities

- T002 + T003 (different concerns, both read-only).
- T004 + T005 + T006 (different fixture files).
- T009 + T010 (two flavors, independent files).
- T017 (SKILL.md refresh) can run any time after T011.
- T024 + T025 + T026 (three different marketplace files).
- T027 + T029 (extension.yml vs AGENTS.md, no overlap).
- T044 + T045 (gh issue create vs gh issue close —independent calls; gh CLI handles them serially regardless).

---

## Parallel Example: User Story 1 (post-test, helper implementation)

```bash
# Once T008 is RED, launch helper implementations in parallel:
Task: "Implement bridge-state.ps1 per contracts/bridge-state-summary.md and research.md R1-R3" -> tasks T009
Task: "Implement bridge-state.sh per contracts/bridge-state-summary.md and research.md R4" -> tasks T010
# Then sequentially wire each helper into its sibling scripts:
Task: "Modify update-handoff.ps1 to source bridge-state.ps1" -> tasks T011 (depends on T009)
Task: "Modify update-handoff.sh to source bridge-state.sh" -> tasks T012 (depends on T010)
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Complete Phase 1 (Setup) + Phase 2 (Foundational).
2. Complete Phase 3 (US1) end-to-end. RED 鈫?GREEN 鈫?existing-smoke-still-green.
3. **STOP and VALIDATE**: Drive [quickstart.md Playbook 1](./quickstart.md) against synthetic fixtures. Confirm `[bridge state]` block visible, warning fires correctly, false-positive prevention works, `prior_actor` shows up in jsonl.
4. This IS the deployable MVP. The drift-hardening capability alone would justify a release (even before US2-US5 land).

### Incremental Delivery (recommended for this cycle)

1. Phase 1 + 2 (Setup + Foundational).
2. Phase 3 (US1) 鈫?demo: synthetic-fixture walkthrough.
3. Phase 4 (US2) 鈫?demo: open 007/003 tasks.md and observe boxes are checked / deferred items are organized.
4. Phase 5 (US3 head) 鈫?demo: open `marketplace/README.md` and read the policy.
5. Phase 6 (US4 head) 鈫?demo: `extension.yml` 0.5.0 + CHANGELOG ready.
6. Phase 7 (tag + sandbox + catalog rotation) 鈫?real release.
7. Phase 8 (main merge) 鈫?trunk-based hygiene restored.

### Parallel Team Strategy

With multiple operators (Claude + Codex co-residing in the workspace):
- Operator A: Phase 3 (US1 implementation —runtime changes).
- Operator B: Phase 5 (US3 research + marketplace edits —pure docs).
- Operator C: Phase 4 (US2 alignment) —must wait for Operator A to finish at least T009-T015 so the US1 helper is available for T021's self-check.

Phase 6, 7, 8 are inherently sequential (release pipeline) and cannot be split across operators.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in the same phase.
- [Story] label maps task to specific user story for traceability; Setup/Foundational/Polish carry no story label.
- Each user story IS independently completable AND testable per the spec's Independent Test criteria.
- TDD: T008 must be RED before T009-T014; this is enforced by the RED-GREEN-REFACTOR cycle.
- Commit cadence: T033 explicitly groups the work into 4 commits. Smaller commits are fine; the test 鈬?implementation pair (T008 鈫?T015) should land in the same logical group so reviewers can see the RED 鈫?GREEN transition.
- Avoid: editing vendor-managed `.agents/skills/speckit-*` or `.claude/skills/speckit-*` EXCEPT for the `speckit-superpowers-bridge/` peer (which is OURS). Constitution Principle V.
- The bridge guard will allow `speckit.tasks` (default-allow rule). The guard will allow `speckit.plan`, `speckit.specify`, `speckit.clarify` if you run them mid-cycle. Stay disciplined: 008 spec is settled; do not re-spec mid-implementation.
