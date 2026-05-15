---
description: "Tasks for v0.4.2 cleanup-tail of feature 003-bridge-cross-platform-scripts: B1 artifact_owner preservation, B2 cross-platform bash path translation, C1+C4 hygiene, US4 first sandbox verification"
---

# Tasks: Bridge Cross-Platform Scripts — Cleanup Tail (v0.4.2)

**Input**: Design documents from `specs/003-bridge-cross-platform-scripts/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/bash-cli-contract.md](./contracts/bash-cli-contract.md), [contracts/verification-record.md](./contracts/verification-record.md), [quickstart.md](./quickstart.md)

**Tests**: TDD discipline is mandatory per spec FR-013 and memory `feedback_cross_reference_drift_needs_tests`. Every new fix gets its test extension FIRST, observed RED, then the fix, then GREEN.

**Organization**: Tasks group by user story. The 6-commit plan from research.md §R5 maps roughly: commit 1 = US1, commit 2 = US2, commit 3+4 = US3, commit 5 = release prep, commit 6 = verification (US4 post-publish).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

## Path Conventions

Same as v0.4.1:

- Bridge runtime: `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/`
- Tests: `tests/` at repo root (3 files cap holds)
- Release tooling: `scripts/release/` at repo root
- Marketplace: `marketplace/` at repo root
- Protocol + config: `AGENTS.md`, `CHANGELOG.md`, `.gitignore`, `.gitattributes` at root
- Feature docs: `specs/003-bridge-cross-platform-scripts/`
- Sandbox: `..\test_specify_superpower` (sibling directory, NOT in this repo)

---

## Phase 1: Setup (Pre-flight)

**Purpose**: Confirm a clean baseline before touching scripts.

- [ ] T001 Verify working tree clean (`git status` empty) and on branch `003-cross-platform-cleanup`. If dirty, stash or commit. Record baseline `git rev-parse HEAD` for SC-009 reference.
- [ ] T002 Compute baseline spec-history content hash: `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin` (no `--name-only` — full content per the SC-006 lesson from feature 006). Record the SHA in a working note for T044.
- [ ] T003 Confirm v0.4.1 release exists: `gh release view v0.4.1 --json tagName,assets --jq '{tag, asset_count: (.assets | length)}'`. Expected: `tag = "v0.4.1"`, `asset_count = 1`.
- [ ] T004 Confirm catalog issue still open: `gh issue view 2581 --repo github/spec-kit --json state --jq '.state'`. Expected: `OPEN`. (If CLOSED, the post-release update path becomes "open a fresh issue".)
- [ ] T005 Run all 3 bridge smoke tests on the current pre-fix state. Record which pass and which fail on the dev box. This establishes the pre-feature baseline so post-fix failures are attributable to this feature.

**Checkpoint**: baseline captured.

---

## Phase 2: Foundational

**Purpose**: One blocking prerequisite — restore the bridge handoff to a state where dev-mode `update-handoff` invocations during this feature don't conflict with prior `executing` state.

- [ ] T006 Inspect `.specify/superpowers-handoff.json`. If `status == "executing"` for an older feature, transition to `complete` via `pwsh update-handoff.ps1 -Status complete -ArtifactOwner <whoever-was-owner> -Actor claude`. This is the **one-shot correction** spec FR-002 requires for the live `artifact_owner: codex` poisoned state — explicit `-ArtifactOwner claude` per the live record. (NOTE: this task fires BEFORE the B1 fix lands, so it must pass `-ArtifactOwner` explicitly; the implicit-preservation behavior arrives later in US1.)

**Checkpoint**: handoff in `ready` or `complete` with correct artifact_owner; feature work can proceed.

---

## Phase 3: User Story 1 — Governance integrity (Priority: P1) 🎯 MVP

**Goal**: `update-handoff.{ps1,sh}` preserves prior `artifact_owner` when not overridden by explicit flag, per the 4-step chain in research.md R1.

**Independent Test**: Quickstart Step 1's round-trip test on both flavors.

### Commit 1 — B1 fix

- [ ] T007 [US1] Extend `tests/test-handoff-shape.ps1` with a new test case: "preserves prior artifact_owner". Sequence: write a synthetic handoff JSON with `artifact_owner: claude` to a temp file, invoke `update-handoff.ps1 -Status executing -Actor codex` (no `-ArtifactOwner`), assert post-write `artifact_owner` is still `claude`. Apply via the existing `Get-AvailableFlavors` loop so it covers both flavors. This is the **RED** test for B1.
- [ ] T008 [US1] Run `pwsh tests/test-handoff-shape.ps1` — confirm the new "preserves prior artifact_owner" assertion FAILS for at least one flavor (probably both, since live data shows the bug). Record the exact failure output for diff against the GREEN run.
- [ ] T009 [US1] Read `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` carefully (current ~189 lines) and locate the `artifact_owner` resolution logic. Identify whether the bug is in the resolution chain itself OR in some upstream codepath that bypasses it (e.g., `auto-archive-handoff.ps1` invoking with implicit-actor defaulting). Document findings in a working note.
- [ ] T010 [US1] Apply the B1 fix to `update-handoff.ps1` per research.md R1's 4-step chain: explicit `-ArtifactOwner` → prior file value → `-Actor` → `"unknown"`. The fix is **silent** (no warning on implicit preservation per R1).
- [ ] T011 [US1] Apply the analogous B1 fix to `update-handoff.sh`. Use jq to read the prior `artifact_owner` from the existing handoff JSON; mirror the precedence chain. **Both flavors must implement identical semantics** — that's the constitutional Principle III invariant.
- [ ] T012 [US1] Re-run `pwsh tests/test-handoff-shape.ps1`. Confirm the new B1 assertion PASSES for both flavors. Confirm all pre-existing assertions also still pass (no regression). This is the **GREEN** verification.
- [ ] T013 [US1] Run the existing `tests/test-guard-hardcoded-rules.ps1` AND `tests/test-claude-codex-skill-parity.ps1` to confirm neither was inadvertently broken. All 3 smoke tests green.
- [ ] T014 [US1] Commit message `fix(bridge): preserve prior artifact_owner on update-handoff writes (ps + sh)`. Body must cite the 4-step chain from research.md R1 and reference spec FR-001.

---

## Phase 4: User Story 2 — Cross-platform bash dispatch (Priority: P2)

**Goal**: `Convert-ToBashPath` in the two extended tests detects MSYS / WSL / native and translates correctly, OR skips with reason.

**Independent Test**: Quickstart Step 2's test run on the Windows + MSYS git-bash dev box.

### Commit 2 — B2 fix

- [ ] T015 [US2] Extend `tests/test-handoff-shape.ps1` with a unit test of `Convert-ToBashPath` itself: pass several path forms (Windows `C:\path`, WSL `/mnt/c/path`, native `/home/user/path`, with-spaces `C:\Users\Alice Smith\file.sh`) and assert each returns a bash-reachable string OR triggers the documented skip-with-reason branch. This is the **RED** test for B2's strategy chain (the current `Convert-ToBashPath` will fail at least the MSYS case).
- [ ] T016 [US2] Run `pwsh tests/test-handoff-shape.ps1` — verify the new strategy-chain assertions FAIL on the dev box (MSYS git-bash present). Capture failure mode for diff.
- [ ] T017 [US2] Apply the B2 fix to `tests/test-handoff-shape.ps1`: replace the existing 8-line `Convert-ToBashPath` with the 5-strategy implementation from research.md R2. Add the post-translation existence check (`bash -c "[ -f ... ] && echo OK"`) so failures degrade to skip-with-reason instead of opaque throws.
- [ ] T018 [US2] Apply the identical `Convert-ToBashPath` replacement to `tests/test-guard-hardcoded-rules.ps1`. Per R2 (inline-helper convention from feature 003 v0.4.0), the function IS duplicated — but the duplication must be byte-identical between the two files.
- [ ] T019 [US2] Re-run both tests. Confirm:
  - The new strategy-chain assertions PASS.
  - Existing bash-invocation assertions PASS (where bash is available and translates correctly).
  - Summary line shows `(ps, bash)` if bash + cygpath both available, OR `(ps)` + skip-reason if not.
- [ ] T020 [US2] Verify the third test (`tests/test-claude-codex-skill-parity.ps1`) is still untouched and still passes — it doesn't invoke bash at all.
- [ ] T021 [US2] Commit message `fix(tests): cross-platform bash path translation (MSYS / WSL / native)`. Body must cite the 5-strategy chain and reference spec FR-003 + FR-004.

---

## Phase 5: User Story 3 — Repo hygiene + doc accuracy (Priority: P2)

**Goal**: Stop tracking install-time registry files; sweep old tasks.md to reflect actual ship state; stub verification.md.

**Independent Test**: Quickstart Steps 3 + 4.

### Commit 3 — C4 gitignore + git rm --cached

- [ ] T022 [US3] Edit `.gitignore`: add the 3 patterns from research.md R3 under a new "Spec Kit install-time generated state" comment block (`.specify/workflows/workflow-registry.json`, `.specify/workflows/*/workflow.yml`, `.specify/extensions/.registry`).
- [ ] T023 [US3] Run `git rm -r --cached .specify/workflows/workflow-registry.json .specify/workflows/speckit/workflow.yml .specify/workflows/speckit-superpowers/workflow.yml .specify/extensions/.registry`. Verify with `git ls-files <each-path>` — must return empty.
- [ ] T024 [US3] Confirm files still exist on disk locally (they're install-time state — losing them locally is fine, but the `git rm --cached` should NOT delete from working tree). Re-run `specify extension list` if needed to regenerate them.
- [ ] T025 [US3] Edit `AGENTS.md` (or `marketplace/README.md` — pick the more discoverable spot) to add a short subsection explaining the three registry files are local install state and are intentionally untracked. ≤ 3 sentences (FR-007).
- [ ] T026 [US3] Commit message `chore(repo): gitignore install-time registry files`. Body cites FR-006 + research.md R3.

### Commit 4 — C1 tasks.md sweep + verification.md stub

- [ ] T027 [US3] Open `specs/003-bridge-cross-platform-scripts/tasks.md` (the old v0.4.0 file, currently STALE-bannered). Remove the STALE banner. Walk the 67 task items with `git log --oneline v0.3.1..v0.4.1` open: for each task that shipped, change `- [ ]` to `- [x]`. Expected ~50 [x].
- [ ] T028 [US3] For the ~15-17 user-side cross-platform verification tasks (T065 Linux end-to-end, T066 macOS end-to-end, similar rows), change them to `- [ ] (absorbed into US4 verification.md; see specs/003-.../verification.md)`. Per Clarifications Q2.
- [ ] T029 [US3] Append a closing paragraph at the end of the old `tasks.md`: `> Tasks closed by v0.4.1 release; user-side cross-platform verification absorbed into US4 of the v0.4.2 cleanup-tail spec. See the new tasks.md for v0.4.2 work.` (FR-005).
- [ ] T030 [US3] Create `specs/003-bridge-cross-platform-scripts/verification.md` as a stub matching the schema in `contracts/verification-record.md`. Include the H1, intro paragraph, and an empty `## v0.4.2` section with the table header but no rows yet. Rows get filled during Phase 7 (post-tag).
- [ ] T031 [US3] Commit message `chore(docs): mark v0.4.0 tasks.md complete; stub verification.md`. Body cites FR-005, FR-009, and Clarifications Q2.

---

## Phase 6: User Story 4 — First sandbox verification (Priority: P1)

**Goal**: After the v0.4.2 release publishes, run the constitution v1.2.0 §"End-User Verification Sandbox" gate on Windows PowerShell + WSL Linux bash.

**Independent Test**: Quickstart Steps 9 + 10 + 11.

### Commit 5 — Release prep + tag

- [ ] T032 [P] [US4] Bump `.specify/extensions/speckit-superpowers-bridge/extension.yml` `extension.version` to `"0.4.2"`. (FR-010)
- [ ] T033 [P] [US4] Bump `marketplace/catalog-entry.json` — `version` to `"0.4.2"` and `download_url` to `https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip`. (FR-010)
- [ ] T034 [P] [US4] Update `marketplace/extension-submission-body.md`: change version/SHA placeholders to v0.4.2 form. SHA256 left as `<filled-by-workflow>` placeholder — actual value comes from the workflow Step Summary after T040. (FR-014)
- [ ] T035 [P] [US4] Add `CHANGELOG.md` `[0.4.2] - 2026-05-16` section. Must explicitly name **B1**, **B2**, **C1**, **C4**, **US4** as the five things v0.4.2 closes. Must note "patch / cleanup release with no new bridge capability" and reference the constitution v1.2.0 gate. Add `[0.4.2]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.2` footnote link. Update `[Unreleased]` base ref to v0.4.2. (FR-011)
- [ ] T036 [US4] Run the local pre-tag validator: `pwsh scripts/release/validate-release-readiness.ps1 -Version 0.4.2`. Must exit 0. If it fails (file-count parity, `.gitattributes`, CHANGELOG header, version mismatch), fix BEFORE proceeding.
- [ ] T037 [US4] Run all 3 bridge smoke tests one more time on the current dev box. Must exit 0 with `(ps, bash)` or `(ps)` summary lines per the B2 strategy chain.
- [ ] T038 [US4] Run the release-tooling self-test: `pwsh scripts/release/test-validate-release-readiness.ps1`. Must exit 0.
- [ ] T039 [US4] Commit message `release(bridge): bump to 0.4.2 — cleanup tail (B1 + B2 + C1 + C4 + US4 sandbox)`. Body lists every file touched. Push to `origin/003-cross-platform-cleanup`.

### Tag + workflow + verify

- [ ] T040 [US4] Create annotated tag: `git tag -a v0.4.2 -m "v0.4.2 — cleanup tail (artifact_owner fix + path translation fix + hygiene + first sandbox verification)"`. Push: `git push origin v0.4.2`. The workflow at `.github/workflows/release.yml` will auto-trigger.
- [ ] T041 [US4] Watch the workflow: `gh run watch <id> --exit-status`. Must complete green in ≤ 60s. Capture the SHA256 from the workflow's Build extension ZIP step OR the workflow's final Summary step.
- [ ] T042 [US4] Verify the release on GitHub: `gh release view v0.4.2 --json assets,tagName --jq '{tag, asset_size: .assets[0].size, asset_state: .assets[0].state}'`. Must show `state: "uploaded"`. Capture the asset's URL. Re-compute SHA256 by downloading via proxy if local network requires it.

### Sandbox runs (manual / interactive)

- [ ] T043 [US4] **Windows PowerShell sandbox run.** At `..\test_specify_superpower` (create if missing): `specify init . --integration claude --script ps --here --force`; `specify extension add speckit-superpowers-bridge --from <v0.4.2 release URL>`; `specify extension list` (confirm 3 commands + 5 hooks at v0.4.2); drive a trivial throwaway feature through `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge` → handoff complete. Record PASS or FAIL outcome.
- [ ] T044 [US4] Append a Windows row to `specs/003-bridge-cross-platform-scripts/verification.md` `## v0.4.2` section per `contracts/verification-record.md` schema: platform `windows-powershell`, bridge_sha256 from T041/T042, today's date UTC, operator `claude` or `human`, result `PASS`/`FAIL`, brief notes.
- [ ] T045 [US4] **WSL Linux bash sandbox run.** Open WSL (where Claude Code is installed per Clarifications Q3). At `~/test_specify_superpower` (create if missing): same sequence as T043 but with `--script sh`. Drive the trivial feature. Confirm `bash` scripts under `scripts/bash/` are invoked rather than the PS ones (observable in `bridge-events.jsonl`).
- [ ] T046 [US4] Append a WSL Linux row to the same `## v0.4.2` section: platform `wsl-linux-bash`, same bridge_sha256 as T044 (it's the same release), date UTC, operator, result, notes.
- [ ] T047 [US4] Append a third row for `macos-bash`: result `PENDING`, notes `no host available; deferred per Clarifications Q3`. Per FR-008 + SC-005, this row is REQUIRED even though it's not a PASS.
- [ ] T048 [US4] Verify SC-005 holds: open `verification.md`; confirm `## v0.4.2` has 3 rows (Windows + WSL + macOS-pending); confirm all `bridge_sha256` values in the section match each other; confirm `Result` values are 2× PASS + 1× PENDING.

### Decision branch

- [ ] T049 [US4] **If T043 + T045 BOTH PASS:** commit verification.md with message `verify(bridge): record v0.4.2 sandbox run (Windows + WSL Linux PASS; macOS pending)`. Push. Then `pwsh update-handoff.ps1 -Status complete -Actor claude` (artifact_owner preservation already in effect after the B1 fix — implicit `claude` from the prior state).
- [ ] T050 [US4] **If EITHER fails:** commit verification.md with the failure detail. Run `pwsh update-handoff.ps1 -Status blocked -Reason "<failure summary>" -Actor claude`. STOP this task list and open a new feature (likely numbered specs/008-… or a continuation spec) to address the regression as v0.4.3. **The v0.4.2 release stays published as "preliminary" — note this in the verification.md row's Notes column.**

### Update issue 2581 (only if T049 fires — PASS path)

- [ ] T051 [US4] Compose `/tmp/issue-2581-v0.4.2.md` modeled on the v0.4.1 comment: brief summary of what changed in v0.4.2 (B1+B2+C1+C4 cleanup), updated catalog-entry JSON with v0.4.2 metadata and the actual SHA256 from T042, AI-disclosure paragraph preserved verbatim.
- [ ] T052 [US4] Edit the existing issue 2581 via `gh api -X PATCH repos/github/spec-kit/issues/comments/<id> -F body=@/tmp/issue-2581-v0.4.2.md`. (Or post a new comment if editing the existing one is too disruptive — judgment call by the operator.)

---

## Phase 7: Final verification

- [ ] T053 Run quickstart.md Steps 1–8 (the in-repo verification gates) one more time on the current dev box. All must pass.
- [ ] T054 Spec history checksum sanity: re-run T002's command and confirm the SHA matches the baseline. specs/001/002/004/005/006 (excluding 003 itself) must be byte-identical.
- [ ] T055 Confirm SC-010 + SC-011: `git diff v0.4.1..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` MUST show only the surgical B1 changes in `update-handoff.ps1` and `update-handoff.sh`. No other bridge-script edits.
- [ ] T056 Final state check: branch `003-cross-platform-cleanup` ahead of `main` by exactly 5 commits (+ optional T049 verify commit = 6). Tag `v0.4.2` on `origin`. Handoff status: `complete` (if T049 fired) or `blocked` (if T050 fired). Issue 2581 updated (if PASS).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: T001–T005 must run first.
- **Phase 2 (Foundational)**: T006 unblocks any subsequent `update-handoff` invocation. Depends on Phase 1.
- **Phase 3 (US1)**: depends on Phase 2 (B1 fix touches `update-handoff` which T006 just ran). Commit 1.
- **Phase 4 (US2)**: depends on Phase 3 (B2 tests invoke the bash flavor of update-handoff which got the B1 fix; ordering ensures the GREEN assertion holds). Commit 2.
- **Phase 5 (US3)**: depends on Phase 4 (the tasks.md sweep references the v0.4.1 commit log, which is unaffected; the .gitignore commit is independent but kept here for commit-ordering clarity). Commits 3 + 4.
- **Phase 6 (US4)**: depends on ALL prior phases. T039 (commit 5) requires Phases 3+4+5 already committed. T040 (tag) requires T039. T041–T048 follow T040. T049 OR T050 follow the verification.
- **Phase 7 (Final)**: depends on Phase 6. Read-only verification.

### Within-phase TDD ordering

Per FR-013 + memory `feedback_cross_reference_drift_needs_tests`:

- US1: T007 RED → T008 confirm fail → T009 investigate → T010+T011 GREEN write → T012 confirm pass → T013 regression check → T014 commit
- US2: T015 RED → T016 confirm fail → T017+T018 GREEN write → T019+T020 confirm pass + no regression → T021 commit

### Parallel Opportunities

- T032/T033/T034/T035 are all editing different files (extension.yml, catalog-entry.json, extension-submission-body.md, CHANGELOG.md); [P] markers allow simultaneous editing then a single commit.
- T010 and T011 (PS vs bash B1 fix) touch different files; could be edited in parallel by an agent capable of multi-file editing, then committed together.
- T017 and T018 (B2 fix in two test files) are byte-identical edits to different files; same parallel opportunity.

---

## Implementation Strategy

### MVP First (US1 Only)

US1 IS the MVP — the B1 governance fix is the only one that affects constitutional compliance. After commit 1 lands, the live handoff JSON behaves correctly for the rest of the feature's commits (Codex running `update-handoff` no longer drifts `artifact_owner`).

If shipping a `v0.4.2-only-B1` were necessary for any reason (it isn't — but if), commit 1 alone could be tagged. Practical: ship all 5 commits + verification together as v0.4.2.

### Test-First Discipline (mandatory)

Per spec FR-013 + memory `feedback_cross_reference_drift_needs_tests`. Concretely:

- T007 MUST happen before T010 and T011. Run T008 between to OBSERVE the RED.
- T015 MUST happen before T017 and T018. Run T016 between to OBSERVE the RED.
- Skipping the RED-observation step (T008 or T016) is the exact pattern that let 5 cross-reference drift bugs slip past on v0.3.0. **Don't skip.**

### Sandbox Runs Need Human Time

T043 (Windows) and T045 (WSL Linux) are interactive 5–10 minute sandbox runs per platform. They cannot be parallelized within a single human-driver session. Budget ~30 minutes for both runs + recording.

### Failure Path Is Real

T050's "if either fails" branch is not theoretical. The sandbox gate's whole point is catching real install-time issues. If it fires, the work to revise spec + cut v0.4.3 is its own mini-cycle, NOT covered by this tasks.md.

---

## Notes

- The 4 surgical edits (T010, T011, T017, T018) are intentionally small. Spec FR-013 byte-freeze constraint forbids "while you're in there, also clean up X". Resist.
- The B1 fix should be ≤ 10 lines of net change per script (mostly an `elif $prior` insertion between `$ArtifactOwner` and `$Actor` branches).
- The B2 fix replaces an 8-line helper with a 25-line one — the only sizable edit in this feature.
- Commit messages MUST follow the project convention (`fix(bridge):`, `chore(repo):`, `release(bridge):`, `verify(bridge):`) for parallel reads of `git log`.
- T049 / T050 are the load-bearing decision point. Recording the outcome HONESTLY in verification.md is the constitution gate's whole value.
- **Stop conditions / "don't skip" reminders**:
  - Don't skip T008 / T016 (RED observation).
  - Don't skip T042's SHA256 capture (used by T044 + T046 + T051).
  - Don't run T049 without BOTH Windows AND WSL Linux PASS recorded — that violates SC-005.
  - Don't transition handoff to `complete` until T048 SC-005 check passes.
