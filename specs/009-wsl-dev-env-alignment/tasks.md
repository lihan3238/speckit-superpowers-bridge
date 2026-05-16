---

description: "Task list for 009-wsl-dev-env-alignment"
---

# Tasks: WSL Development Environment Alignment

**Input**: Design documents from `specs/009-wsl-dev-env-alignment/`

**Prerequisites**: [plan.md](./plan.md) ✓, [spec.md](./spec.md) ✓, [research.md](./research.md) ✓, [data-model.md](./data-model.md) ✓, [contracts/bootstrap-contract.md](./contracts/bootstrap-contract.md) ✓, [contracts/gitignore-contract.md](./contracts/gitignore-contract.md) ✓, [contracts/tests-bash-port-contract.md](./contracts/tests-bash-port-contract.md) ✓, [quickstart.md](./quickstart.md) ✓

**Tests**: Tests ARE in scope for this feature — FR-007 mandates bash ports of the existing PowerShell smoke tests. The Phase 3 (US1) test-port tasks are NOT "new tests written for new behavior" (no new behavior in scope); they are **behavioral ports** of existing assertions to a new flavor, governed by `contracts/tests-bash-port-contract.md`.

**Organization**: Tasks are grouped by user story (US2 first because US1 depends on US2's bootstrap being complete; both are P1). The story ordering reflects the dependency chain established in [plan.md](./plan.md) "Implementation strategy (phased)" — A → B → C → D.

## Format: `- [ ] TNNN [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to user stories in spec.md (US1, US2, US3). Setup/Foundational/Polish tasks have no story label.
- File paths are absolute repo-relative.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish a rollback-safe baseline before any destructive index or filesystem operation.

- [ ] T001 Create rollback checkpoint: `git tag specs/009-pre-phase-a` on current HEAD so the entire Phase A sequence (T003..T013) can be reverted via `git reset --hard specs/009-pre-phase-a` if [contracts/bootstrap-contract.md](./contracts/bootstrap-contract.md) "Forbidden effects" trigger

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify host prereqs before any user-story phase. Failure here halts the feature.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T002 Verify WSL host prerequisites by running `git --version`, `bash --version | head -1`, `gh --version | head -1`, `jq --version`, `specify --version`; record each version to `specs/009-wsl-dev-env-alignment/verification.md` Host section (file may not exist yet — create it with just the Host block for now). The `specify` CLI MUST be `>= 0.8.10` per [contracts/bootstrap-contract.md](./contracts/bootstrap-contract.md) "Contract version".

**Checkpoint**: Foundation ready — user story implementation can begin.

---

## Phase 3: User Story 2 - Repo working tree is clean after a fresh WSL clone (Priority: P1)

**Goal**: After Phase 3 completes, `git status` reports a clean working tree on both WSL bash and Windows PowerShell with no developer-side configuration. `.specify/scripts/` and the 14 non-bridge vendor-managed skill directories are gitignored and absent from the index. `.specify/init-options.json.script` is `"sh"`. The 81+/81− CRLF/LF working-tree diff is gone.

**Independent Test**: `git status` reports clean immediately after `git clone` into a WSL filesystem path; `file .gitattributes .gitignore` reports plain "ASCII text" (no CRLF); `git ls-files .specify/scripts/` returns empty; `git ls-files .claude/skills/speckit-superpowers-bridge/` returns non-empty.

**Dependencies**: T001, T002 complete.

### Implementation for User Story 2

- [ ] T003 [US2] Commit the LF-normalized `.gitattributes` (currently dirty in working tree per `git diff`) at `.gitattributes` with one-line rationale "normalize CRLF→LF for WSL parity (FR-002)" — single-file commit so the change is independently revertable
- [ ] T004 [US2] Commit the LF-normalized `.gitignore` at `.gitignore` with same rationale — single-file commit, sequential after T003 (both files were dirty together)
- [ ] T005 [US2] Append the install-state ignore block (15 entries: `.specify/scripts/` + 7 `.claude/skills/speckit-*/` + 7 `.agents/skills/speckit-*/`) to `.gitignore` per [contracts/gitignore-contract.md](./contracts/gitignore-contract.md) "Paths added to `.gitignore`"; preserve existing structure; commit with rationale "add install-state ignore block per spec 009 Clarifications Q1+Q2 Policy"
- [ ] T006 [US2] Edit `.specify/init-options.json` to change `"script": "ps"` → `"script": "sh"`; all other fields MUST be byte-identical (verify by `jq -S .` diff); commit with rationale "set default flavor to bash per spec 009 FR-005"
- [ ] T007 [US2] Run `git rm -r --cached .specify/scripts/` to remove the directory from the index without deleting on-disk content; commit per [contracts/gitignore-contract.md](./contracts/gitignore-contract.md) "Index operations"
- [ ] T008 [P] [US2] Run `git rm -r --cached` on the 7 non-bridge `.claude/skills/speckit-*/` directories: `speckit-analyze`, `speckit-checklist`, `speckit-clarify`, `speckit-implement`, `speckit-plan`, `speckit-tasks`, `speckit-taskstoissues` (DO NOT touch `speckit-superpowers-bridge`); commit
- [ ] T009 [P] [US2] Run `git rm -r --cached` on the same 7 non-bridge directory names under `.agents/skills/` (codex-side equivalents; same exclusion of `speckit-superpowers-bridge`); commit
- [ ] T010 [US2] Run `specify init --here --script sh --force` from repo root; capture stdout + stderr + the resulting `git status` + `git diff --stat` to `specs/009-wsl-dev-env-alignment/verification.md` "Phase A bootstrap observation" section (append, do not overwrite the Host section from T002)
- [ ] T011 [US2] Validate T010's outcome against every "MUST be observed" + every "MUST NOT be observed" in [contracts/bootstrap-contract.md](./contracts/bootstrap-contract.md); if any forbidden path was touched: STOP, run `git reset --hard specs/009-pre-phase-a`, return to spec 009 to amend the contract
- [ ] T012 [US2] Validate every post-state invariant in [contracts/gitignore-contract.md](./contracts/gitignore-contract.md) "Post-state invariants" (each `git ls-files` check for the 15 ignored paths returns empty; both `speckit-superpowers-bridge` paths return non-empty); record pass/fail per row in `verification.md`
- [ ] T013 [US2] Final US2 verification: `git status` reports clean (SC-002 + SC-005); `file .gitattributes .gitignore` returns "ASCII text" without CRLF (SC-006); `find .specify/extensions tests -name '*.sh' -exec file {} \;` shows zero CRLF (SC-006)

**Checkpoint**: US2 complete — repo hygiene baseline is clean; US1 can proceed against a known-good state.

---

## Phase 4: User Story 1 - Maintainer can run the full bridge toolchain from WSL bash (Priority: P1)

**Goal**: All four bash test ports exist and pass green on WSL; all four `.ps1` originals are deleted; `tests/run-all.sh` runs the full bash smoke suite under 60s; documentation references to `tests/*.ps1` in `marketplace/*` are updated to `tests/*.sh`; CHANGELOG `## [Unreleased]` records the port.

**Independent Test**: `bash tests/run-all.sh` from a fresh WSL bash shell at repo root prints 4 `*-ok (bash)` lines and exits 0 in under 60s; `ls tests/test-*.ps1` returns no files; `grep -l 'tests/test-.*\.ps1' marketplace/README.md marketplace/extension-submission-body.md` returns no matches.

**Dependencies**: US2 (Phase 3) complete — the bootstrap from T010 must have regenerated `.specify/scripts/bash/` and the vendor-managed slash-command skills with bash paths embedded; otherwise the bridge `update-handoff.sh` / `guard-command.sh` invocations the new bash tests perform may resolve to non-existent paths.

### Bash test ports (parallel — each ports one independent file)

- [ ] T014 [P] [US1] Port `tests/test-handoff-shape.ps1` → `tests/test-handoff-shape.sh` per [contracts/tests-bash-port-contract.md](./contracts/tests-bash-port-contract.md) Port 1 (three assertion sub-blocks: v1 write shape, v3 backward-read, artifact_owner preservation). DROP the PowerShell-side path-translation chain and cross-flavor dispatch — the bash port runs natively. Final stdout line: `handoff-shape-tests-ok (bash)`.
- [ ] T015 [P] [US1] Port `tests/test-guard-hardcoded-rules.ps1` → `tests/test-guard-hardcoded-rules.sh` per Port 2 (5 hardcoded guard rules from CLAUDE.md + default-allow). Use the bridge bash guard at `.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh` directly. Final stdout line: `guard-hardcoded-rules-tests-ok (bash)`.
- [ ] T016 [P] [US1] Port `tests/test-bridge-state-summary.ps1` → `tests/test-bridge-state-summary.sh` per Port 3 (assert `[bridge state]` block shape on every guard + update-handoff invocation). Final stdout line: `bridge-state-summary-tests-ok (bash)`.
- [ ] T017 [P] [US1] Port `tests/test-claude-codex-skill-parity.ps1` → `tests/test-claude-codex-skill-parity.sh` per Port 4 (cross-agent file parity for the project-owned `speckit-superpowers-bridge` skill files). Final stdout line: `claude-codex-skill-parity-tests-ok (bash)`.

### Runner + green-prove + delete originals + docs

- [ ] T018 [US1] Add `tests/run-all.sh` runner per [contracts/tests-bash-port-contract.md](./contracts/tests-bash-port-contract.md) "Runner" section (5-line loop; explicit per-test header and FAIL marker per FR-007); `chmod +x tests/run-all.sh`
- [ ] T019 [US1] Run `bash tests/run-all.sh` from WSL bash; capture full stdout + stderr + `time` output to `specs/009-wsl-dev-env-alignment/verification.md` "Phase B smoke-test transcript" section; confirm all four `*-ok (bash)` final lines present AND runtime < 60s (Performance Goals + SC-001)
- [ ] T020 [US1] Per port, after the `.sh` proves green in T019: delete the corresponding `.ps1` original via `git rm tests/test-<name>.ps1`. Result: `ls tests/test-*.ps1 2>/dev/null | wc -l` returns `0`. Commit as one logical change (4 files removed in one commit is acceptable since they were all proven green together).
- [ ] T021 [P] [US1] Update `marketplace/README.md` line 41: replace `tests/test-*.ps1` with `tests/test-*.sh`; verify "all 3 bridge smoke tests" → adjust count to "4 bridge smoke tests" if accurate; commit
- [ ] T022 [P] [US1] Update `marketplace/extension-submission-body.md` lines 113-116: replace each of the four `.ps1` filenames with the corresponding `.sh` filename; commit
- [ ] T023 [US1] Add `## [Unreleased]` section to `CHANGELOG.md` (or prepend to existing one) with one entry: `- 009: ported tests/*.ps1 → tests/*.sh; deleted PowerShell smoke tests after bash equivalents verified green on WSL bash; added tests/run-all.sh runner; .specify/scripts/ and vendor-managed .claude/.agents skill dirs now gitignored as install-time state; init-options.json default flavor switched to sh`; commit

**Checkpoint**: US1 complete — the toolchain demonstrably works on WSL bash; no `.ps1` test files remain; forward-looking docs are accurate.

---

## Phase 5: User Story 3 - Onboarding note for the next WSL developer (Priority: P2)

**Goal**: `AGENTS.md` contains a `## Supported Host Environments` section that a new contributor can locate in under 30 seconds and that names both Windows PowerShell 5.1+ and WSL2 bash 5.2+ environments, their prereq tools, default flavor, and the one-line bootstrap command. The section is consistent with `.specify/init-options.json.script`.

**Independent Test**: Open `AGENTS.md`; the new section appears within the first ~80 lines of the file; reading just that section answers "what do I need installed in WSL to run the test suite?" and "which script flavor does this project use on which host?"; `grep '"script"' .specify/init-options.json` returns `"script": "sh"` matching the documented WSL default in `AGENTS.md`.

**Dependencies**: US2 (Phase 3) complete (init-options.json finalized at "sh"). US1 (Phase 4) helpful but not strictly required (the section can reference `tests/test-*.sh` even before deletion of `.ps1`; but doing US3 after US1 means the section is final on first commit).

### Implementation for User Story 3

- [ ] T024 [US3] Insert new `## Supported Host Environments` section into `AGENTS.md` per [research.md R4](./research.md#r4--where-to-insert-the-supported-host-environments-section-in-agentsmd) — immediately after the existing `## Primary Design Reference` section and BEFORE `## User-Facing Language Routing`. Content includes: 2-row table (Windows PowerShell 5.1+ / WSL2 Ubuntu bash 5.2+) with columns Required tools, Default flavor, Bootstrap command; one paragraph explaining the gitignored-install-state model and pointing to spec 009 Clarifications; explicit note that `.claude/skills/speckit-superpowers-bridge/` and `.agents/skills/speckit-superpowers-bridge/` stay committed; smoke-test runner one-liner for each flavor.
- [ ] T025 [US3] Verify FR-011 consistency: `grep '"script"' .specify/init-options.json` MUST equal `"script": "sh"`; the WSL row in `AGENTS.md` "Default flavor" column MUST equal `sh`; the Windows row MUST equal `ps`; if any mismatch, fix the doc (NOT the JSON — JSON was settled in T006)
- [ ] T026 [US3] SC-004 reachability check: from a fresh read of `AGENTS.md` (no prior context), time how long it takes to find the new section. MUST be < 30 seconds; record the actual seconds in `specs/009-wsl-dev-env-alignment/verification.md` "Phase C docs check" appended section

**Checkpoint**: US3 complete — onboarding note is in place, consistent with the rest of the alignment.

---

## Phase 6: Polish & Cross-Cutting Concerns (FR-013 verification + SC-007 audit)

**Purpose**: Finalize `verification.md` per `data-model.md Entity 6`, run final SC-007 audit, and run the pre-push quality gate.

**Dependencies**: US2 + US1 + US3 (Phases 3-5) all complete.

- [ ] T027 [P] Append FR-013 end-to-end cycle evidence to `specs/009-wsl-dev-env-alignment/verification.md` "Phase D end-to-end cycle" section: list each slash command invoked during this feature (`/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, plus the bridge handoff fired by the after_tasks hook, plus the eventual `update-handoff complete` at feature close) with its `[bridge state]` summary block captured from each step's output. Source: this conversation transcript + `.specify/bridge-events.jsonl`.
- [ ] T028 [P] Append SC-007 audit to `verification.md` "Phase D" section: run `git diff --stat main..HEAD` (or against the merge-base if not main) and confirm no NEW top-level directories, no new `.specify/extensions/*` subdirectories, no new `.claude/skills/speckit-*/` or `.agents/skills/speckit-*/` directories that aren't the project-owned `speckit-superpowers-bridge` peers. Paste the diff stats.
- [ ] T029 Append SC summary table to `verification.md` "Result" section: one row per SC-001..SC-007 with PASS / PASS-with-notes / FAIL based on evidence in the prior sections. Final line: `Result: PASS` (or `PASS-with-notes: <list>` if any SC was partial).
- [ ] T030 Run pre-push quality gate per the project's `pre-push-quality-gate` discipline: `git status` clean (no working-tree changes); `bash tests/run-all.sh` green; `ls tests/*.ps1 2>/dev/null` returns no output; `git ls-files .specify/scripts/ .claude/skills/speckit-analyze/ .agents/skills/speckit-analyze/` returns empty (sample check across the gitignored paths); `git ls-files .claude/skills/speckit-superpowers-bridge/ .agents/skills/speckit-superpowers-bridge/` returns non-empty
- [ ] T031 Final checklist refresh: open `specs/009-wsl-dev-env-alignment/checklists/requirements.md` and confirm all items remain ✅ after implementation; if any item dropped (e.g., a clarification surfaced during implementation that needs new spec language), append a Notes entry and surface in `verification.md` as a known-limitation row in the SC table

---

## Dependencies — Story Completion Order

```text
Setup (T001)
   ↓
Foundational (T002)
   ↓
US2 — Phase 3 (T003..T013)            [P1, FOUNDATIONAL for US1]
   ↓
US1 — Phase 4 (T014..T023)            [P1, depends on US2]
   ↓
US3 — Phase 5 (T024..T026)            [P2, depends on US2; US1 helpful for accurate test-runner doc]
   ↓
Polish — Phase 6 (T027..T031)         [depends on US2 + US1 + US3]
```

US1 and US3 cannot run in parallel because US3 documents the same bootstrap process that US2 finalizes; both downstream of US2 is the safe order. The plan's A→B→C→D ordering is preserved here.

## Parallel Execution Opportunities

Within phases:

- **Phase 3 (US2)**: T008 || T009 (different directory sets; both are `git rm -r --cached` operations on independent paths)
- **Phase 4 (US1)**: T014 || T015 || T016 || T017 (each ports an independent test file); T021 || T022 (different marketplace files)
- **Phase 6 (Polish)**: T027 || T028 (different append regions of the same `verification.md` — only safe if appender is line-aware; otherwise serialize)

Across phases: parallel execution is NOT recommended because each phase depends on the prior phase's repo state.

## Implementation Strategy (MVP first, incremental delivery)

MVP scope = **US2 alone** (Phase 3, tasks T003..T013). After US2 lands, the maintainer's `git status` is clean and the bootstrap path is in place — every other Spec Kit operation in WSL bash will then function (because `specify init` will have regenerated `.specify/scripts/bash/` and the bash-flavored slash-command skill files). US1 and US3 are quality-of-life completeness; US2 is the bare-minimum unblocker.

Incremental ship sequence:

1. **MVP** = T001..T013 (US2 complete). Demoable: "clone the repo into WSL, run `git status`, get clean output." Plus: "run `specify init --here --script sh --force`, run `bash .specify/scripts/bash/setup-plan.sh --json`, get JSON paths."
2. **Increment 2** = T014..T023 (US1 complete). Demoable: "run `bash tests/run-all.sh` from WSL, see 4 ports go green in under 60s; no `.ps1` test files exist."
3. **Increment 3** = T024..T026 (US3 complete). Demoable: "new contributor reads AGENTS.md, finds environment + bootstrap in under 30s."
4. **Finalize** = T027..T031 (verification + quality gate). Demoable: `verification.md` records the end-to-end cycle and SC table reports PASS.

After T031, the bridge handoff (fired by the original `after_tasks` hook on tasks.md generation) transitions to `complete` and this feature is ready for the v0.5.x release cycle's next minor bump (separate feature).
