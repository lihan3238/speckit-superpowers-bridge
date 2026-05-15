---
description: "Tasks for feature 003-bridge-cross-platform-scripts — add bash flavor of the 4 retained bridge scripts so the bridge runs on Linux + macOS + Windows from one ZIP"
---

# Tasks: Bridge Cross-Platform Scripts

**Input**: Design documents from `specs/003-bridge-cross-platform-scripts/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/bash-cli-contract.md](./contracts/bash-cli-contract.md), [quickstart.md](./quickstart.md)

**Tests**: Tests ARE included because (a) the spec extends the 3 retained tests to dual-flavor coverage (FR-014, FR-015), and (b) the lesson sunk in `feedback_cross_reference_drift_needs_tests.md` makes TDD non-optional for new scripts. Tasks are ordered RED → GREEN per script per `superpowers:test-driven-development` discipline.

**Organization**: Tasks group by user story (US1 P1 MVP, US2 P1, US3 P2, US4 P2). Implementation follows the 6-commit plan from `research.md` §R13.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Include exact file paths in descriptions

## Path Conventions

Same Spec Kit extension layout as v0.3.1:

- Bridge runtime: `.specify/extensions/speckit-superpowers-bridge/`
- NEW bash dir: `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`
- Tests: `tests/` at repo root (3 files cap holds)
- Release tooling: `scripts/release/` at repo root
- Marketplace: `marketplace/` at repo root
- Protocol: `AGENTS.md`, `CLAUDE.md`, `README*.md`, `CHANGELOG.md`, `.gitignore`, NEW `.gitattributes` at root

---

## Phase 1: Setup (Pre-flight)

**Purpose**: Confirm the v0.3.1 baseline is healthy and capture the SHA needed for SC-006.

- [ ] T001 Verify working tree clean (`git status` zero changes) and on branch `003-bridge-cross-platform-scripts`. If dirty, stash or commit. Record baseline `git rev-parse HEAD` (expected: a commit on the v0.3.1 tag line after the spec/plan commits).
- [ ] T002 Compute baseline spec-history checksum: `git ls-tree -r HEAD specs/001-* specs/002-* specs/003-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin`. This is the **content-hash** form (no `--name-only`) per the SC-006-strengthening lesson from feature 006. Record the SHA in a working note for T044.
- [ ] T003 Confirm v0.3.1 tag exists locally (`git tag --list v0.3.1`) and points to `0c919aa` or successor. This is the regression baseline for US2.
- [ ] T004 Run the existing 3 smoke tests on the current state; record they pass. (Establishes the pre-feature green baseline so any post-feature failure is attributable to this feature's changes.)
- [ ] T005 Verify Spec Kit's `init-options.json.script` field is present (`Get-Content .specify/init-options.json | ConvertFrom-Json | Select-Object -ExpandProperty script` returns `"ps"`). Confirms the dispatch mechanism research.md §R0/Clarifications-Q2 relies on actually exists.

**Checkpoint**: baseline captured, dispatch mechanism confirmed.

---

## Phase 2: Foundational

**Purpose**: One blocking prerequisite for everything below — ensure the bridge handoff is `ready` or `complete`, NOT `executing`, so dev-mode invocations during this feature don't conflict with a stale state.

- [ ] T006 Inspect `.specify/superpowers-handoff.json`; if status is `executing`, set it to `complete` for the prior feature (feature 006) via `pwsh .specify/extensions/.../scripts/powershell/update-handoff.ps1 -Status complete -Actor claude`. This unblocks the bridge guard from interfering with our own commits.

**Checkpoint**: handoff in `ready` or `complete`; feature 003 work can proceed.

---

## Phase 3: User Story 1 — Linux / macOS End-to-End Working (Priority: P1) 🎯 MVP

**Goal**: 4 bash scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/` that pass the same contract assertions the PowerShell scripts pass.

**Independent Test**: From a clean Ubuntu 24.04 container with `bash`, `jq`, `git`, and Spec Kit (no `pwsh`), run quickstart.md Step 6 → bridge handoff completes a full cycle.

### Commit 1 — `common-actor-resolution.sh` (foundation; sourced by the other 3)

- [ ] T007 [US1] Extend `tests/test-handoff-shape.ps1` with an inline 6-line `Get-AvailableFlavors` helper (per research.md §R10). The function returns `@("ps")` when only `scripts/powershell/` exists, `@("ps","bash")` when both exist. Wrap the existing test body in a `foreach ($flavor in (Get-AvailableFlavors -BridgeRoot $bridgeRoot)) { ... }` loop with `$flavor` parameterizing which script gets invoked. Add a final summary line `Write-Output "handoff-shape-tests-ok ($($flavors -join ', '))"`. **Do not yet add any bash invocation logic** — bash branch will throw "not implemented" placeholder. This is the RED test.
- [ ] T008 [US1] Run `pwsh tests/test-handoff-shape.ps1` — must still PASS for ps flavor (no regression). The bash flavor branch is unreachable until T011/T015 lands. Confirm output ends with `handoff-shape-tests-ok (ps)`.
- [ ] T009 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/bash/common-actor-resolution.sh`: define `get_repo_root` (3 lines: `git rev-parse --show-toplevel` with fallback to `pwd`) and `resolve_bridge_actor` (3-step chain: explicit arg → `SPECKIT_BRIDGE_ACTOR` env → `"unknown"`). Use `#!/usr/bin/env bash` + `set -euo pipefail`. Target ≤ 30 lines. Mirror `common-actor-resolution.ps1`'s contract exactly per research.md §R5.
- [ ] T010 [US1] Smoke-test the helper standalone: `bash -c '. .specify/.../scripts/bash/common-actor-resolution.sh && echo $(resolve_bridge_actor codex)'` → outputs `codex`. Also test fallback: `bash -c '. ... && SPECKIT_BRIDGE_ACTOR=claude && echo $(resolve_bridge_actor "")'` → outputs `claude`.
- [ ] T011 [US1] Commit message `feat(bridge): add common-actor-resolution.sh + dot-source contract` → ~commit hash 1. Append `cut-inventory.md`-style entry to `specs/003-bridge-cross-platform-scripts/` (NEW file `release-inventory.md` if needed) describing what was added.

### Commit 2 — `update-handoff.sh`

- [ ] T012 [US1] Extend `tests/test-handoff-shape.ps1`: add a `Invoke-Flavor` helper that takes `$flavor` + `$args` and invokes either `pwsh -File <ps script>` or `bash <sh script>`. The existing v1-shape + v3-backward-read assertions now run per-flavor. **Do not yet write the bash script** — running the test should fail when `$flavor -eq "bash"`. This is RED for commit 2.
- [ ] T013 [US1] Run `pwsh tests/test-handoff-shape.ps1` on Windows where bash is NOT on PATH → must auto-skip the bash branch with `Write-Output "  (bash flavor not exercised: bash not on PATH)"` and still exit 0 with `handoff-shape-tests-ok (ps)`. (Verifies the auto-detect gating works pre-bash-script.)
- [ ] T014 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh`: argument parsing via `case` loop (per research.md §R4) for the 8 flags from `contracts/bash-cli-contract.md`. Use `jq` for JSON read/write (per §R1). Snapshot prior feature artifacts before write (Principle IV, the fix from `10fd70d` ported). Read tolerantly (ignore unknown v2/v3 fields). Write v1 shape exactly per `handoff.v1.schema.json`. Target ≤ 110 lines. End with `exit 0` on success path.
- [ ] T015 [US1] Set bash executable bit in git: `git update-index --chmod=+x .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh`. (Doesn't matter for `bash <path>` invocation but signals intent in git's tree.)
- [ ] T016 [US1] Run `bash .specify/extensions/.../scripts/bash/update-handoff.sh --status ready --actor claude` standalone (in a temp working dir to avoid clobbering current state). Verify it writes `.specify/superpowers-handoff.json` with `schema_version: 1`, `status: "ready"`, `artifact_owner: "claude"` and no v3 fields.
- [ ] T017 [US1] On a Linux container OR via WSL: run `pwsh tests/test-handoff-shape.ps1`. Should now exercise BOTH flavors and output `handoff-shape-tests-ok (ps, bash)`. Verify both flavor branches PASS all assertions. (If running on Windows where bash isn't on PATH, this verification defers to T044.) GREEN for commit 2.
- [ ] T018 [US1] Commit `feat(bridge): add update-handoff.sh (v1 schema writer + tolerant reader)` → commit hash 2.

### Commit 3 — `guard-command.sh`

- [ ] T019 [US1] Extend `tests/test-guard-hardcoded-rules.ps1` with the same `Get-AvailableFlavors` inline helper + `Invoke-Flavor` invocation pattern as T012. All 5-rule assertions now run per-flavor. Bash branch will fail until T021. RED for commit 3.
- [ ] T020 [US1] Run `pwsh tests/test-guard-hardcoded-rules.ps1` — must exit 0 with `(ps)` output (bash skipped pre-script). Verify the auto-skip gate works.
- [ ] T021 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh`: 5 hardcoded `if`/`elif` branches per research.md §R3 (carry-forward from feature 006). Same deny reasons as PS. Source `common-actor-resolution.sh`. Log every decision to `.specify/bridge-events.jsonl` with `action: "guard"`. Target ≤ 75 lines.
- [ ] T022 [US1] Smoke-test the 5 rules manually:
   - `bash guard-command.sh --action speckit.implement --actor claude` (with handoff in `executing`) → exit 1
   - `bash guard-command.sh --action speckit.plan --actor claude` → exit 0
   - `bash guard-command.sh --action "superpowers:writing-plans" --actor claude` (with active feature having spec.md + plan.md) → exit 1
   - `bash guard-command.sh --action speckit.constitution --actor claude` (executing handoff) → exit 1
   - `bash guard-command.sh --action "some.unknown.cmd" --actor claude` → exit 0
- [ ] T023 [US1] On Linux/WSL: run `pwsh tests/test-guard-hardcoded-rules.ps1` → `guard-hardcoded-rules-tests-ok (ps, bash)`. GREEN for commit 3.
- [ ] T024 [US1] Commit `feat(bridge): add guard-command.sh (5 hardcoded rules)` → commit hash 3.

### Commit 4 — `auto-archive-handoff.sh`

- [ ] T025 [US1] No new test extension — `auto-archive-handoff` is not directly tested (mirrors feature 006 which manually verified it via quickstart). The two existing tests already cover the load-bearing pieces it delegates to.
- [ ] T026 [US1] Create `.specify/extensions/speckit-superpowers-bridge/scripts/bash/auto-archive-handoff.sh`: idempotent (no-op when status ≠ complete); when firing, capture prior feature dir from handoff JSON via jq BEFORE invoking `update-handoff.sh --clear-feature-directory`, then call `update-handoff.sh` with the proper args. Append `archive` event to `bridge-events.jsonl`. Target ≤ 60 lines.
- [ ] T027 [US1] Smoke-test: write a synthetic `complete` handoff to a temp dir; run `bash auto-archive-handoff.sh --actor claude`; verify post-state is `ready` with `feature_directory: null` and a new snapshot directory exists under `bridge-snapshots/` containing the prior feature's artifacts.
- [ ] T028 [US1] Smoke-test idempotence: with handoff status NOT `complete` (e.g., `executing`), running the script must exit 0 with `"No complete handoff to archive (current status: 'executing')."` and NO filesystem changes.
- [ ] T029 [US1] Commit `feat(bridge): add auto-archive-handoff.sh` → commit hash 4.

**Checkpoint US1**: 4 bash scripts exist, all functionally equivalent to their PS siblings. Both flavors pass smoke tests where bash is available.

---

## Phase 4: User Story 2 — Existing Windows Users Not Broken (Priority: P1)

**Goal**: Verify v0.3.1 PowerShell behavior is byte-frozen.

**Independent Test**: On Windows with v0.3.1's PS scripts unchanged, run all 3 smoke tests and a full bridge round-trip — outputs identical to v0.3.1.

- [ ] T030 [US2] Diff PS scripts: `git diff v0.3.1..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/powershell/` MUST be empty. (FR-002 byte-frozen invariant.)
- [ ] T031 [US2] Run the 3 smoke tests on Windows (current dev machine). All must exit 0. Per-flavor output: `(ps)` only on Windows-without-bash; `(ps, bash)` on Windows-with-WSL.
- [ ] T032 [US2] Manually drive a full bridge round-trip on Windows: write a synthetic handoff via `pwsh update-handoff.ps1 -Status executing -FeatureDirectory specs/003-bridge-cross-platform-scripts ...`, snapshot the resulting JSON, run `auto-archive-handoff.ps1 -Actor claude` AFTER transitioning to complete. Compare to v0.3.1 baseline behavior (output strings, file content modulo timestamps).

**Checkpoint US2**: Windows regression-free.

---

## Phase 5: User Story 3 — Single ZIP Serving All Platforms (Priority: P2)

**Goal**: ZIP built by `build-extension-zip.ps1` contains both `scripts/powershell/` and `scripts/bash/`. Validator enforces parity. `.gitattributes` keeps `.sh` LF-clean through Windows clones.

**Independent Test**: Run `pwsh scripts/release/build-extension-zip.ps1 -Version 0.4.0`; unpack the ZIP; verify it contains 4 .ps1 + 4 .sh files at the correct depth.

### Commit 5 — `.gitattributes` + validator extension + build-script extension + test extension

- [ ] T033 [US3] Extend `scripts/release/test-validate-release-readiness.ps1` with 2 new TDD cases: (case 6) bash dir present but only 3 .sh files vs 4 .ps1 → validator must FAIL naming "file-count parity"; (case 7) `.gitattributes` missing the `*.sh eol=lf` line → validator must FAIL naming ".gitattributes". RED — validator doesn't have those checks yet.
- [ ] T034 [US3] Run `pwsh scripts/release/test-validate-release-readiness.ps1` — verify cases 6 + 7 FAIL (the validator returns 0 because it doesn't check those yet). Confirms RED.
- [ ] T035 [US3] Create `.gitattributes` at repo root with content from research.md §R8: 4 rules (`*.sh eol=lf`, `*.ps1 eol=crlf`, `*.md text`, plus JSON/YAML text declarations).
- [ ] T036 [US3] Extend `scripts/release/validate-release-readiness.ps1` with the 2 new checks: (a) when `scripts/bash/` exists, count `.sh` files; assert equal to `.ps1` file count in `scripts/powershell/`; assert filename stems match. (b) `.gitattributes` exists at repo root AND contains a line matching `^\*\.sh\s+text\s+eol=lf\b`. Each new check on failure prints a clear "FAIL: ..." line and contributes to the non-zero exit.
- [ ] T037 [US3] Run `pwsh scripts/release/test-validate-release-readiness.ps1` — all 7 cases now GREEN. Confirms validator extension correct.
- [ ] T038 [US3] Extend `scripts/release/build-extension-zip.ps1`: add one `Copy-Item -Recurse -LiteralPath (Join-Path $bridgeDir "scripts/bash") -Destination (Join-Path $stageDir "scripts/bash") -ErrorAction SilentlyContinue` line immediately after the existing PowerShell copy line. (Verify the existing line for reference; mimic its form.)
- [ ] T039 [US3] Smoke-test: `pwsh scripts/release/build-extension-zip.ps1 -Version 0.4.0`. Unpack the resulting `dist/speckit-superpowers-bridge-v0.4.0.zip` to a temp dir. Verify `extension.yml` is directly at ZIP root and it contains BOTH `scripts/powershell/` (4 .ps1) AND `scripts/bash/` (4 .sh).
- [ ] T040 [US3] Verify the unpacked `.sh` files have LF line endings (not CRLF): `(Get-Content <path> -Raw) -notmatch "`r`n"` should be `True`. This validates FR-020 and the `.gitattributes` actually worked through the Compress-Archive path.
- [ ] T041 [US3] Commit `chore: add .gitattributes; extend validator + build script + tests for cross-platform parity` → commit hash 5.

**Checkpoint US3**: Single ZIP carries both flavors; validator catches drift.

---

## Phase 6: User Story 4 — Any-OS Dev/Test Surface (Priority: P2)

**Goal**: Contributors on any OS can run the test suite locally with `pwsh`.

**Independent Test**: A contributor on macOS (or in a Linux container with `pwsh` installed) clones, runs all 3 tests, and gets `(ps, bash)` summaries.

- [ ] T042 [US4] On Linux container or WSL: `apt install -y powershell` (or equivalent); clone the repo; run all 3 tests. Verify per-flavor summaries `(ps, bash)`.
- [ ] T043 [US4] (Optional / deferred) macOS smoke: same as T042 on macOS 13+ with `brew install powershell`. Defer if no Mac hardware available — note as future verification.

**Checkpoint US4**: Multi-OS dev verified at least on Linux.

---

## Phase 7: Polish & Release

**Purpose**: Bump version to 0.4.0; refresh marketplace + docs; tag + push; let workflow build/release; update issue 2575.

### Commit 6 — Release v0.4.0

- [ ] T044 [P] Update `.specify/extensions/speckit-superpowers-bridge/extension.yml`: bump `extension.version` to `"0.4.0"`; rewrite `requires.tools` per research.md §R12 (4 tools with explicit `required: true|false`).
- [ ] T045 [P] Update `marketplace/catalog-entry.json`: bump `version` to `"0.4.0"`; update `download_url` to v0.4.0 URL; description stays the same (91 chars from v0.3.1).
- [ ] T046 [P] Update `marketplace/upstream-pr-body.md`: change "since v0.3.0" → "since v0.3.1"; update Validation section to reference v0.4.0; add Linux/macOS test row (`ubuntu:24.04` container PASS, macOS deferred if applicable).
- [ ] T047 Add `CHANGELOG.md` `[0.4.0] - <today>` section explicitly listing: (a) the 4 added `scripts/bash/*.sh` files, (b) `requires.tools` schema refinement, (c) `.gitattributes` added, (d) validator + build-script + tests extended, (e) README cross-platform install section. Include the standard Compatibility note: v0.3.x installs upgrade seamlessly; no manual migration needed.
- [ ] T048 Add the `[0.4.0]: …releases/tag/v0.4.0` footnote link at the bottom of `CHANGELOG.md`; bump `[Unreleased]` compare base to v0.4.0.
- [ ] T049 [P] Update `README.md` with a new "Prerequisites" subsection naming `bash >= 4.0` and `jq >= 1.6` for non-Windows install paths; one-line install commands for apt/brew/dnf. Add a note that contributors need `pwsh` 7.x for tests. Preserve bilingual H2 anchor parity (FR-017 + SC-010).
- [ ] T050 [P] Update `README.zh-CN.md` with the same prerequisites subsection translated to 简体中文. H2 anchors stay English for cross-link stability.
- [ ] T051 Update `AGENTS.md`: add a brief line that bash flavor exists as of v0.4.0; same boundary rules and same handoff schema. Do NOT add new sections; keep additive footnote-style.
- [ ] T052 Run `pwsh scripts/release/validate-release-readiness.ps1 -Version 0.4.0` locally; verify exit 0. This catches the new checks (file-count parity, .gitattributes) before the workflow does.
- [ ] T053 Run all 3 smoke tests one more time on the current dev OS; verify green.
- [ ] T054 Run `pwsh scripts/release/test-validate-release-readiness.ps1`; verify 7/7 cases pass.
- [ ] T055 Stage all changes; verify `git diff --stat v0.3.1..HEAD` matches the expected files-touched list from plan.md "Scale/Scope". Commit `release(bridge): bump to 0.4.0 — cross-platform (Linux + macOS via bash + jq)` → commit hash 6.
- [ ] T056 Push to `origin/main`.

### Tag + workflow + verify

- [ ] T057 Create annotated tag: `git tag -a v0.4.0 -m "v0.4.0 — cross-platform bash flavor; same protocol on Linux + macOS + Windows"`. Push tag: `git push origin v0.4.0`.
- [ ] T058 Watch the workflow run: `gh run watch <id>`. Expected: all 11 steps green in ≤ 60s, ZIP uploaded as release asset.
- [ ] T059 Verify the release: `gh release view v0.4.0 --json assets,tagName`; download the asset; compute SHA256; verify it matches the workflow's reported SHA. (Use proxy `http://127.0.0.1:10808` for curl if needed.)
- [ ] T060 Unpack the published ZIP; verify it contains BOTH `scripts/bash/` (4 files, LF endings) AND `scripts/powershell/` (4 files, unchanged from v0.3.1).

### Update issue 2575

- [ ] T061 Compose comment body at `/tmp/issue-2575-v0.4.0.md` modeled on the v0.3.1 comment: summary "v0.4.0 supersedes the v0.3.1 details — now cross-platform via bash + jq", updated catalog-entry JSON, new SHA256, AI-disclosure paragraph preserved verbatim.
- [ ] T062 `gh api -X PATCH repos/github/spec-kit/issues/comments/4459669209 -F body=@/tmp/issue-2575-v0.4.0.md`. Verify the comment URL.

---

## Phase 8: Final verification

- [ ] T063 Execute quickstart.md Steps 1, 2, 3, 4, 5, 9, 10, 11, 12 (the dev-machine-runnable ones) one more time end-to-end. Record pass/fail for each.
- [ ] T064 Spec history checksum sanity: run the T002 baseline command again; compare with the SHA recorded then. Specs/001..006 (excluding 003 which IS this feature's working dir) MUST be byte-identical.
- [ ] T065 (Deferred) Step 6 (Linux container end-to-end) — recommended for user-side verification after the release ships. Same as feature 006's T043 deferred to user.
- [ ] T066 (Deferred) Step 7 (macOS end-to-end) — recommended if macOS hardware available.
- [ ] T067 Final handoff state: `pwsh update-handoff.ps1 -Status complete -FeatureDirectory specs/003-bridge-cross-platform-scripts -Actor claude`. Closes feature 003.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: T001–T005 must run first.
- **Phase 2 (Foundational)**: T006 depends on Phase 1.
- **Phase 3 (US1)**: Commit groups 1–4 in order (each depends on the previous because all later scripts source `common-actor-resolution.sh` from commit 1).
  - Within a commit group: RED test extension → run-and-see-fail/skip → write script → run-and-see-pass → commit.
- **Phase 4 (US2)**: T030–T032 can run any time after the Phase 3 commits land (verifies PS files weren't touched).
- **Phase 5 (US3)**: Commit 5 depends on Phase 3 being COMPLETE (file-count parity check fires when bash dir exists).
- **Phase 6 (US4)**: Verification only; can run after Phase 5.
- **Phase 7 (Polish + Release)**: Depends on all prior phases. T057 (tag) is the trigger for automation; T058–T062 are tag-time and post-tag actions.

### Parallel Opportunities

- T044, T045, T046, T049, T050 are all editing different files (`extension.yml`, `catalog-entry.json`, `upstream-pr-body.md`, `README.md`, `README.zh-CN.md`); they parallelize freely. Group them in one commit batch.
- Within each commit group of Phase 3, RED test must precede script write (TDD discipline), but script files themselves are independent.

---

## Implementation Strategy

### MVP First (US1 Only)

The MVP is the four bash scripts working with both flavors green on the existing test suite (Phase 3 complete). At that point:

- Linux/macOS users can run the bridge if you ship a manual ZIP build.
- Windows users are unaffected.
- Full polish + automation can land in a subsequent commit.

But because v0.4.0 is a small feature, **shipping all 7 phases together is the recommended path**. The 4 commits in Phase 3 + 1 commit in Phase 5 + 1 release commit in Phase 7 = 6 commits total per research.md §R13.

### Incremental Validation Pattern

Per `feedback_cross_reference_drift_needs_tests.md`:

- Every new script gets its test extension FIRST (RED).
- See test fail / skip the new flavor as expected.
- THEN write the script.
- Re-run test, see GREEN.
- Commit.

This discipline is mandatory; the v0.3.0 trim's "test-after-the-fact" failures (5 cross-reference drifts caught only by code review) are the source of this lesson.

### TDD vs Smoke Test Boundary

- TDD applies to: `update-handoff.sh`, `guard-command.sh` (both have dedicated test files extending dual-flavor).
- Smoke-tested-only: `auto-archive-handoff.sh` (exercised indirectly through `update-handoff` it delegates to; matches feature 006's manual verification approach for the PS version), `common-actor-resolution.sh` (sourced by every script; exercised transitively).
- The validator's two new checks (file-count parity + `.gitattributes`) get their own TDD cases in `test-validate-release-readiness.ps1`.

---

## Notes

- All `.sh` files: shebang `#!/usr/bin/env bash`, `set -euo pipefail` at top, explicit `exit 0` on success.
- All `.sh` files invoked via `bash <path>` (NOT `./<path>`) so the Unix executable bit doesn't matter in the published ZIP. Same convention as Spec Kit's git extension.
- Commit messages follow the `feat(bridge): ...` / `chore: ...` / `release(bridge): ...` pattern established by features 005, 006.
- The 6 commits between v0.3.1 and v0.4.0 align with research.md §R13's commit-granularity plan.
- After the release lands, file size: ~30 KB → ~38 KB (4 small bash scripts added). Still negligible for catalog purposes.
- T043 + T065 + T066 (real Linux container + real macOS) are user-side smokes; the bridge can ship v0.4.0 without them but they're the final SC validation. Same pattern as feature 006's T043.
