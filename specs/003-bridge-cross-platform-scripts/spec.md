# Feature Specification: Bridge Cross-Platform Scripts — Cleanup Tail

**Feature Branch**: `003-cross-platform-cleanup`

**Created**: 2026-05-16

**Status**: Draft (redesign — supersedes the original v0.4.0 draft of feature 003)

**Input**: User direction: "似乎 specs\\003-bridge-cross-platform-scripts 未能完整实现，你结合问题清单，重新设计下 specs\\003-bridge-cross-platform-scripts."

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) AND the project constitution at `.specify/memory/constitution.md` (v1.2.0+, especially the new End-User Verification Sandbox gate).

## What this redesign is and isn't

**Is**: A scope-extension of feature 003 to close the cleanup tail left by the v0.4.0 / v0.4.1 releases. The bash flavor itself **shipped successfully** in v0.4.1 and remains in production — that part of 003 is DONE. This redesign captures what v0.4.1 left unresolved:

- 1 real governance bug (`artifact_owner` not preserved across writes).
- 1 real test infrastructure bug (`Convert-ToBashPath` hard-codes WSL paths, breaks on MSYS git-bash).
- Documentation accuracy gap (tasks.md never marked complete).
- Repo hygiene (install-time registry files tracked + stale).
- The constitution v1.2.0 retroactive expectation: at least one End-User Verification Sandbox run against the live v0.4.1 release, so the new gate is exercised once before being expected to gate v0.4.2+.

**Isn't**: A rewrite of the bash flavor work. The v0.4.1 release contents (4 bash scripts, 4 PS scripts, .gitattributes, validator extension, build-script extension, dual-flavor tests) are byte-frozen by this feature.

**Versioning**: This feature ships **v0.4.2** (PATCH) — bug fixes + hygiene + verification. No new bridge capability.

## Clarifications

### Session 2026-05-16

- Q: Is v0.4.2's sandbox verification (US4) optional per the "PATCH release exemption" reading, or mandatory per the literal constitution v1.2.0 §"End-User Verification Sandbox" reading? → A: **Mandatory; US4 promoted from P2 → P1.** Constitution does not exempt patch releases; v0.4.2 is the first opportunity to actually run the gate, and first-time strictness sets the precedent. Concrete minimum: Windows PowerShell PASS **plus** at least one Linux or macOS PASS. macOS-only verification is acceptable substitute if Linux container is unavailable; conversely Linux-only is acceptable if no macOS hardware is on hand. Sandbox failure on any required platform MUST block the release.
- Q: What happens to the ~17 deferred tasks from the original v0.4.0 tasks.md (T065 Linux container end-to-end, T066 macOS end-to-end, etc.)? Do they stay as a carry-over phase, get absorbed into US4, or get force-closed? → A: **Absorb into US4 (Option B).** The deferred tasks are the same user-side cross-platform verification work that the new sandbox gate formalizes. Duplicating them in the v0.4.2 tasks.md would double-track the same action. The original tasks.md gets a one-line per affected task: `- [ ] (absorbed into US4 verification.md; see specs/003-.../verification.md)`. The new v0.4.2 tasks.md does NOT re-list them.
- Q: Concrete hardware available for the sandbox run? → A: **Windows + WSL Linux available; macOS NOT available.** WSL has Claude Code installed and serves as the Linux test environment. v0.4.2 verification therefore covers Windows PowerShell + WSL Linux (bash). macOS is deferred until hardware is available; verification.md records it as "Pending — no macOS host" and does NOT block v0.4.2.

## Status of feature 003 prior to this redesign

What shipped in v0.4.0 → v0.4.1:

| Surface | Status |
|---|---|
| `scripts/bash/{update-handoff,guard-command,auto-archive-handoff,common-actor-resolution}.sh` | ✅ shipped |
| `.gitattributes` at repo root | ✅ shipped |
| `scripts/release/build-extension-zip.ps1` packs both flavors with `/` separators + root `extension.yml` invariant check | ✅ shipped |
| `scripts/release/validate-release-readiness.ps1` enforces file-count parity + `.gitattributes` rule | ✅ shipped |
| `tests/test-handoff-shape.ps1` + `tests/test-guard-hardcoded-rules.ps1` dual-flavor auto-detect | ✅ shipped (with caveat — see B2) |
| `extension.yml.requires.tools` 4-tool flat list with `required: true\|false` | ✅ shipped |
| Workflow gates prerelease tags (`if: !contains(github.ref_name, '-')`) | ✅ shipped |
| `marketplace/extension-submission-body.md` (renamed from upstream-pr-body) clean submission | ✅ shipped |
| Issue #2581 OPEN at `github/spec-kit` for v0.4.1 catalog inclusion | ⏳ awaiting maintainer |
| README/AGENTS.md/CHANGELOG cross-platform docs | ✅ shipped |

What v0.4.1 left unresolved (this redesign closes them):

| ID | Problem | Severity |
|---|---|---|
| B1 | `.specify/superpowers-handoff.json.artifact_owner` was overwritten to `codex` when Codex ran `update-handoff` without explicit `-ArtifactOwner`. The Claude-designed → Codex-implemented governance split (per [[artifact-owner-vs-executor-roles-are-distinct]]) is broken at the data layer. | governance / real bug |
| B2 | `tests/test-handoff-shape.ps1` + `tests/test-guard-hardcoded-rules.ps1` use a `Convert-ToBashPath` helper that emits WSL-style `/mnt/c/...` paths. On a Windows dev box where `bash` is MSYS git-bash (which uses `/c/...`) the test exits 1 with "No such file or directory". Tests are green on Linux/macOS native bash and on real WSL bash; only the Windows-with-MSYS-bash dev box reports false failure. | test infrastructure / real bug, false-positive class |
| C1 | `specs/003-bridge-cross-platform-scripts/tasks.md` 67 task items still display `- [ ]` (none checked) despite the feature shipping. Reading the spec gives the wrong "nothing started" impression. | doc accuracy |
| C4 | `.specify/workflows/workflow-registry.json`, `.specify/workflows/speckit-superpowers/workflow.yml`, `.specify/extensions/.registry` are tracked in git AND still claim version `0.1.1` / `0.3.0` despite the live install being v0.4.1. They are install-time generated state and should not be tracked. | repo hygiene |
| SC-v1.2 | The constitution v1.2.0 End-User Verification Sandbox gate has not yet been exercised against any release. v0.4.1 is exempt retroactively (the gate ratified after that release), but running the sandbox once now (a) validates the gate procedure itself, (b) records a first verification entry for v0.4.1, (c) closes the long-deferred T065/T066 from the original 003 spec. | gate validation / first-time use |

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Governance integrity: `artifact_owner` preserved across writes (Priority: P1) 🎯 MVP

A maintainer who is designing a feature in Claude Code hands off implementation to Codex via the bridge. They have a justified expectation that the bridge state — specifically `artifact_owner` — reflects who **designed** the feature (Claude in this case), not who happens to have most recently invoked `update-handoff`. The handoff JSON's `artifact_owner` is the load-bearing field for the design-vs-implementation role split codified by the constitution Principle II and the saved memory `feedback_artifact_owner_vs_executor_roles`.

**Why this priority**: This is the *only* surfaced bug that actively breaks a constitutional invariant. After feature 003's v0.4.1 ship cycle, the live `.specify/superpowers-handoff.json` reads `artifact_owner: codex` even though Claude is the designer of record. Anyone reading the handoff to decide "may I edit the spec?" gets the wrong answer. The fix is small (a few-line edit per script flavor) but the value is keeping the constitution actually enforced rather than aspirational.

**Independent Test**: Run `update-handoff.{ps1,sh}` without `-ArtifactOwner` against a handoff where the prior value was `claude`. After the write, `artifact_owner` MUST still be `claude` — not the current `-Actor`. Repeat for an explicit override (`-ArtifactOwner codex`) and confirm the override DOES apply. Repeat for the case where there is no prior value (fresh handoff) and confirm `-Actor` is used as a sensible default.

**Acceptance Scenarios**:

1. **Given** a handoff with `artifact_owner: claude`, **When** `update-handoff.ps1 -Status executing -Actor codex` runs (no `-ArtifactOwner` flag), **Then** the post-write JSON has `artifact_owner: claude` (preserved), not `codex`.
2. **Given** the same prior state, **When** `update-handoff.ps1 -Status executing -Actor codex -ArtifactOwner codex` runs (explicit override), **Then** the post-write JSON has `artifact_owner: codex` (override honored).
3. **Given** a fresh repo with no prior `superpowers-handoff.json`, **When** `update-handoff.ps1 -Status ready -Actor claude` runs, **Then** `artifact_owner` is `claude` (falls back to the current `-Actor` when no prior exists).
4. **Given** the bash flavor under the same three conditions, **Then** identical outcomes. Both flavors implement preservation identically.

---

### User Story 2 — Cross-platform bash dispatch in the test harness (Priority: P2)

A contributor on Windows runs `pwsh tests/test-handoff-shape.ps1`. Their `bash` on PATH is git-bash (MSYS), not WSL. The test must either invoke the bash flavor successfully (translating Windows paths to MSYS form, e.g. `/c/...`) OR skip the bash branch with a clear "bash flavor not exercised: unsupported bash environment" message — never report a false failure.

**Why this priority**: Without the fix, the green tests on this developer's primary machine are a lie. The first commit after this fix that breaks a real bash assertion will be masked by the existing pre-existing path-translation failure. Sticking with P2 (not P1) because Linux/macOS native and real WSL paths both work today and the contributor can still validate by reading the failure — but the masking risk is real.

**Independent Test**: On a Windows dev box where `which bash` returns `/usr/bin/bash` (MSYS git-bash), run `pwsh tests/test-handoff-shape.ps1` and `pwsh tests/test-guard-hardcoded-rules.ps1`. Both must exit 0 with `(ps, bash)` summary lines, OR exit 0 with `(ps)` and a one-line note explaining bash was skipped (with an unambiguous reason).

**Acceptance Scenarios**:

1. **Given** a Windows host with MSYS git-bash on PATH, **When** the test harness invokes the bash script, **Then** path translation routes through the bash environment's own conversion utility if available (e.g., `cygpath -u`); falls back to forward-slashed Windows path if that succeeds in bash; only finally degrades to "skip with reason" if no translation works. False "No such file or directory" exits are eliminated.
2. **Given** a Linux host with native bash, **When** the test invokes the bash flavor, **Then** the path is used as-is (no translation), test exits 0 with `(ps, bash)`.
3. **Given** a Windows host where bash is not on PATH at all, **When** the test runs, **Then** the bash branch is skipped with the existing "bash flavor not exercised: bash not on PATH" message; ps branch still runs.
4. **Given** any host, **When** the test successfully invokes both flavors, **Then** the summary line is `<test-name>-ok (ps, bash)`. **Otherwise**, the summary line names exactly which flavor(s) were exercised so a reader can tell at a glance.

---

### User Story 3 — Repo hygiene: install-time registries are not tracked (Priority: P2)

A new contributor clones the repo and runs `specify extension list`. Their local install-time registries — `.specify/workflows/workflow-registry.json`, `.specify/workflows/speckit-superpowers/workflow.yml`, `.specify/extensions/.registry` — get rewritten by Spec Kit to reflect their actual install. Currently those files are tracked in git AND still claim the project is at v0.1.1 / v0.3.0 (last manual sync). Their `git status` instantly shows uncommitted changes after a clean checkout — a confusing experience.

**Why this priority**: The bug is cosmetic but persistent — every developer hits it on first `specify extension list`. The fix is small and self-evident: add the three files to `.gitignore`, remove them from the index with `git rm -r --cached`. Keeping the files on disk locally is fine; only the tracking goes.

**Independent Test**: After the fix, `git ls-files` against the three paths returns empty. After a fresh `specify extension list` run, `git status --porcelain` reports zero changes. Documentation in `marketplace/README.md` or AGENTS.md notes that these files are install-time state.

**Acceptance Scenarios**:

1. **Given** a clean clone of the repo, **When** the user runs `specify extension list`, **Then** `git status --porcelain` reports zero changes to the three registry paths.
2. **Given** an existing developer who upgrades, **When** they pull the fix commit, **Then** their local copy of the three files stays on disk (no data loss) but is no longer tracked.
3. **Given** the `.gitignore` after the fix, **When** any future install or upgrade rewrites the registry files, **Then** git silently ignores those changes.

---

### User Story 4 — First End-User Verification Sandbox run (Priority: P1)

The constitution at v1.2.0 added the End-User Verification Sandbox gate (`..\test_specify_superpower`). v0.4.1 shipped before the gate was ratified and is grandfathered. v0.4.2 (this feature's release) is the **first release after gate ratification** and therefore the first one bound by it. Per Clarifications session 2026-05-16, v0.4.2 does NOT receive a PATCH-release exemption — running the gate strictly from the first opportunity sets the precedent for every future release.

**Why this priority**: P1 because the constitution gate is non-negotiable for any release post-v1.2.0 of the constitution. The "PATCH-release exemption" framing was rejected in clarify Q1: an exemption applied at first use is an exemption permanently. Running the gate strictly from v0.4.2 is also the cleanest validation of the gate procedure itself — if any step is awkward, friction surfaces while stakes are lowest.

**Independent Test**: Sandbox at `..\test_specify_superpower` initialized fresh. Bridge installed from the live `https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/...zip` URL. One full bridge cycle driven end-to-end on **Windows PowerShell (mandatory)** AND **WSL Linux (mandatory; the maintainer has Claude Code installed inside WSL as the dedicated Linux test environment per Clarifications Q3)**. macOS verification deferred — no hardware available; recorded in `verification.md` as "Pending — no macOS host" and does NOT block v0.4.2. Outcome recorded in `specs/003-bridge-cross-platform-scripts/verification.md` with platform, exercised SHA256, and pass/fail per acceptance scenario. Sandbox failure on Windows OR WSL Linux MUST block the v0.4.2 release.

**Acceptance Scenarios**:

1. **Given** v0.4.2 published to `origin` with the release asset uploaded, **When** the maintainer at `..\test_specify_superpower` runs `specify extension add ... --from <v0.4.2 URL>`, **Then** the install succeeds and `specify extension list` shows v0.4.2 with 3 commands and 5 hooks.
2. **Given** the installed v0.4.2 in the sandbox, **When** the maintainer runs `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` against a throwaway feature description, **Then** the after_tasks hook produces a well-formed v1 handoff JSON and the bridge command orchestrates Superpowers skills without error.
3. **Given** Windows PowerShell platform (mandatory), **When** the sandbox run completes, **Then** outcomes are recorded in `verification.md` with platform, bridge SHA256, pass/fail per acceptance scenario, and any observed gap.
4. **Given** WSL Linux bash with Claude Code installed (mandatory), **When** the sandbox run is repeated there with `--script sh` at `specify init`, **Then** the same record gains a Linux row.
5. **Given** macOS hardware is NOT available, **When** verification.md is written, **Then** it carries an explicit "macOS: Pending — no host" row. This is acceptable for v0.4.2; future releases re-evaluate when macOS hardware appears.
6. **Given** any required platform's run fails (Windows OR WSL Linux), **When** the maintainer reviews the record, **Then** the v0.4.2 handoff transitions to `blocked` and the spec is revised before a new tag is pushed.

---

### Edge Cases

- A pre-existing `.specify/superpowers-handoff.json` already has `artifact_owner: codex` (state from v0.4.1 cycle). The B1 fix preserves WHATEVER value is there — it does not retroactively flip wrong values to right ones. The maintainer must do an explicit one-shot `update-handoff --artifact-owner claude` after the B1 fix lands to correct the current state. This is intentional — automated correction would hide real ownership transitions.
- Linux/macOS contributors don't hit B2 (their bash is native). The fix MUST NOT introduce a path-translation step on Linux/macOS hosts — degrade gracefully when no translation is needed.
- A future contributor without `cygpath` (extremely unusual MSYS install) hits B2's final fallback. The test skips bash with a reason. Acceptable.
- The three install-time registries (C4) are committed in current history; the fix is a single commit that adds gitignore + `git rm --cached`. Their LAST tracked version is the v0.3.0 frozen state — not the current truth. After the fix, the question "what version is registered?" is answered by `extension.yml` and the live install, not by any tracked file.
- Sandbox run (US4) may discover a NEW bug. If so, that bug is captured in the verification.md record and triggers either (a) a v0.4.3 patch or (b) downgrade to declared known-issue in CHANGELOG. The spec does not pre-commit to either path.
- `marketplace/extension-submission-body.md` (renamed from `upstream-pr-body.md` during v0.4.1) references the SHA256 of v0.4.1. v0.4.2 will get a different SHA. The submission-body file MUST be updated as part of the v0.4.2 release commit, NOT separately — same pattern as v0.3.1 → v0.4.1 transitions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** (governance bug B1): `update-handoff.ps1` and `update-handoff.sh` MUST preserve the prior `artifact_owner` value from `.specify/superpowers-handoff.json` when the caller does not pass `-ArtifactOwner` / `--artifact-owner` AND a prior value exists. The precedence chain MUST be: explicit flag → prior file value → `-Actor` resolution → `"unknown"`. Both flavors implement identical precedence.
- **FR-002**: After the B1 fix lands, the maintainer MUST run a one-shot `update-handoff --status complete --artifact-owner claude --actor claude` to correct the currently-wrong `artifact_owner` value in the live handoff JSON. This is a manual step, NOT an automated migration. Record it in CHANGELOG `[0.4.2]` for transparency.
- **FR-003** (test bug B2): `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` MUST translate paths to the bash flavor in use. The translation strategy MUST be detection-based, in this priority order:
  1. If `bash -c "command -v cygpath"` succeeds, use `bash -c "cygpath -u '<windows-path>'"` (MSYS, Cygwin).
  2. Else if the path matches `^/mnt/[a-z]/` (already WSL-form input), use as-is.
  3. Else if the host is Windows AND the path matches `^[A-Za-z]:`, fall back to `/<drive>/<rest>` form (works on most MSYS, sometimes on WSL).
  4. Else use the path verbatim (Linux/macOS native).
  5. If all of the above fail to produce an existing file accessible from bash, skip the bash branch with a clear `(bash flavor not exercised: path-translation failed for <bash environment>)` summary and exit the test branch successfully.
- **FR-004**: After the B2 fix, both extended smoke tests MUST exit 0 on at least the following matrix when run as `pwsh tests/test-*.ps1`:
  - Windows + Windows PowerShell 5.1 + no bash → `(ps)` summary, exit 0
  - Windows + pwsh 7.x + MSYS git-bash → `(ps, bash)` summary, exit 0
  - Windows + pwsh 7.x + WSL bash → `(ps, bash)` summary, exit 0
  - Linux + pwsh 7.x + native bash → `(ps, bash)` summary, exit 0
- **FR-005** (doc accuracy C1): `specs/003-bridge-cross-platform-scripts/tasks.md` MUST be updated to reflect the true completion state of v0.4.1. Tasks corresponding to shipped work get `- [x]`. Tasks deferred to user-side cross-platform verification (the ~17 items including T065 Linux end-to-end, T066 macOS end-to-end, and similar) MUST be marked `- [ ] (absorbed into US4 verification.md; see specs/003-.../verification.md)` per Clarifications Q2 — they are not re-listed in the new v0.4.2 tasks.md. The summary at the end of the old tasks.md gets a one-paragraph note: "Tasks closed by v0.4.1 release; remaining items absorbed into US4 of the v0.4.2 cleanup spec."
- **FR-006** (repo hygiene C4): `.gitignore` MUST gain three new entries:
  - `.specify/workflows/workflow-registry.json`
  - `.specify/workflows/*/workflow.yml`
  - `.specify/extensions/.registry`
  The same commit MUST run `git rm -r --cached` on those three paths so the index stops tracking them. The files MUST remain on the maintainer's local disk after the commit.
- **FR-007**: `marketplace/README.md` AND `AGENTS.md` MUST gain a brief note (≤ 3 sentences) that the three install-time registry files are local install state and are intentionally not tracked. This pre-empts the question "should I commit my registry?" for future contributors.
- **FR-008** (constitution gate US4): The first End-User Verification Sandbox run MUST be performed against the v0.4.2 release in `..\test_specify_superpower` per the constitution v1.2.0 procedure. **Required platforms** (per Clarifications Q1+Q3): Windows PowerShell + WSL Linux bash. macOS is "Pending — no host" and does NOT block v0.4.2. Sandbox failure on Windows OR WSL Linux blocks v0.4.2; handoff transitions to `blocked` and spec is revised before a new tag is pushed.
- **FR-009**: A new file `specs/003-bridge-cross-platform-scripts/verification.md` MUST be created (or appended-to) containing the sandbox run record. It MUST list: platform, bridge SHA256 exercised, pass/fail per US4 acceptance scenario, any observed gap, the date of the run, and the operator (`claude` or `codex`).
- **FR-010**: `extension.yml.extension.version` MUST be bumped to `0.4.2`. `marketplace/catalog-entry.json` `version` and `download_url` MUST be bumped in lockstep. The release-readiness validator already enforces this (no validator change required for this feature).
- **FR-011**: `CHANGELOG.md` MUST gain a new `[0.4.2] - <YYYY-MM-DD>` section explicitly listing:
  - The B1 fix (artifact_owner preservation), including the one-shot manual correction step from FR-002.
  - The B2 fix (test path translation), including the matrix from FR-004.
  - The C1 tasks.md sweep summary.
  - The C4 gitignore addition + `git rm --cached`.
  - The US4 verification.md record (or pointer to its location).
  - A note that v0.4.2 is a patch / cleanup release with no new bridge capability.
- **FR-012**: The Sync Impact Report at the top of the constitution does NOT change as a result of this feature (no constitution amendment). The version line stays `1.2.0`.
- **FR-013** (CRITICAL — exclusion to prevent scope creep): The bash flavor scripts (`scripts/bash/*.sh`), the PS flavor scripts (`scripts/powershell/*.ps1`), the build script, the validator, the workflow YAML, and the dual-flavor test framework structure are all **byte-frozen** by this feature except for the surgical changes required by FR-001 and FR-003. Any new bash bug, PowerShell improvement, or release-tooling enhancement is OUT OF SCOPE.
- **FR-014**: The `marketplace/extension-submission-body.md` file MUST be updated with the v0.4.2 SHA256 + release URL as part of the same release commit, so the catalog submission comment on issue 2581 can be updated in one paste.
- **FR-015**: The original `specs/003-bridge-cross-platform-scripts/spec.md` content (the v0.4.0 draft, ~290 lines) is REPLACED by this redesign. The original content is preserved in git history; commit messages MUST cite the predecessor commit for traceability.

### Key Entities

- **Handoff Owner Precedence Chain**: The 4-step rule from FR-001 (explicit flag → prior file → actor → unknown). This is a runtime decision tree implemented inside `update-handoff` (both flavors).
- **Bash Path Translator**: The 5-strategy detection logic from FR-003. Lives inside the two extended test files. Not a shared helper (per the inline-helper precedent from feature 003 v0.4.0).
- **Verification Record (NEW FILE)**: `specs/003-bridge-cross-platform-scripts/verification.md`. Schema: a markdown file with one ## section per release verified, containing a small table (platform | SHA256 | result | notes | date | operator). v0.4.2 is the first entry; future releases append rows.
- **Install-Time Registry Set**: The three files newly gitignored by FR-006. They are entities only in the sense that their *non*-tracking is a deliberate hygiene decision.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The live `.specify/superpowers-handoff.json` `artifact_owner` field shows `claude` after the FR-002 one-shot correction, and STAYS at `claude` across at least three subsequent `update-handoff` invocations that do not pass `-ArtifactOwner` (verified by running the bridge through a throwaway feature cycle).
- **SC-002**: On the Windows dev box where the test currently fails, running `pwsh tests/test-handoff-shape.ps1` and `pwsh tests/test-guard-hardcoded-rules.ps1` BOTH exit 0 with either `(ps, bash)` or `(ps)` summary lines — never with a `[bash] <assertion>` throw / non-zero exit caused by path translation.
- **SC-003**: After the C4 fix, a clean `git status --porcelain` after running `specify extension list` returns zero lines.
- **SC-004**: The tasks.md file for 003 displays at least 50 of its 67 tasks as `- [x]` (the ~17 user-side verification tasks may stay `- [ ]` with deferred notes). A reader unfamiliar with the project can tell which work shipped vs which is deferred at a glance.
- **SC-005**: `specs/003-bridge-cross-platform-scripts/verification.md` exists and contains rows for v0.4.2 covering **Windows PowerShell + WSL Linux bash** (both mandatory). A third row for macOS MUST appear with status "Pending — no host". The `bridge_sha256` per platform row matches the value reported by the v0.4.2 release workflow.
- **SC-006**: `extension.yml.version` is `0.4.2`; `marketplace/catalog-entry.json.version` is `0.4.2`; `catalog-entry.json.download_url` resolves to `HTTP 200` (verified via proxy if local network requires it).
- **SC-007**: The CHANGELOG `[0.4.2]` section explicitly names B1, B2, C1, C4, and US4 as the five things v0.4.2 closes. Any reader can tell what changed.
- **SC-008**: The v0.4.2 release is published via the existing `.github/workflows/release.yml` on tag push, with no workflow YAML edits. The workflow completes green in ≤ 60 seconds.
- **SC-009**: `specs/001-…` through `specs/006-…` directories (excluding `specs/003-bridge-cross-platform-scripts` which is this feature's own dir) are byte-identical between the start and end of this feature.
- **SC-010**: The bash flavor scripts (`scripts/bash/*.sh`) are byte-identical between v0.4.1 and v0.4.2 EXCEPT for the FR-001 artifact_owner preservation change in `update-handoff.sh`. Confirmed by `git diff v0.4.1..HEAD -- .specify/extensions/.../scripts/bash/`.
- **SC-011**: The PowerShell flavor scripts (`scripts/powershell/*.ps1`) are byte-identical between v0.4.1 and v0.4.2 EXCEPT for the FR-001 change in `update-handoff.ps1`. Confirmed analogously.
- **SC-012**: Issue 2581 at github/spec-kit is updated with the v0.4.2 metadata (new SHA256, new URL) via a `gh api -X PATCH ... /issues/comments/<id>` edit of the prior comment — same flow used for v0.3.1 → v0.4.1 transitions. The submission body file at `marketplace/extension-submission-body.md` is updated in the same release commit to match.

## Assumptions

- The bash flavor scripts shipped in v0.4.1 are correct for their primary purpose (running on Linux/macOS with native bash); only the test harness's path translation needs fixing. Confirmed by Codex's v0.4.0 → v0.4.1 RC cycle which exercised real Linux installs at least once.
- The maintainer can run a Linux container (Docker) and Windows tests on the dev box. macOS is best-effort.
- Issue 2581 is still OPEN at github/spec-kit (verified at audit time); no other inflight catalog issue exists. If the issue closes BEFORE v0.4.2 ships, the catalog update path becomes "open a fresh issue per the constitution sandbox notes".
- v0.4.2 is a patch release; the release pipeline is unchanged from v0.4.1. The validator already passes (verified 2026-05-16 at audit time).
- The 3 RC tag releases (`v0.4.0-rc.1/2/3`) on GitHub are kept as historical artifacts. Cleanup is not in scope. (User can choose to delete them later; doing so does not affect the catalog or any tag-resolution semantics.)
- The maintainer's hardware for v0.4.2 sandbox verification (per Clarifications Q3): **Windows host** with PowerShell 5.1+; **WSL** with Claude Code installed inside as the dedicated Linux test environment. **NO macOS hardware available**. v0.4.2 ships with Windows + WSL Linux verified; macOS row in verification.md is "Pending — no host". Future releases re-evaluate when macOS hardware becomes available.
- The constitution gate (US4) per Clarifications Q1+Q3 requires Windows PASS + WSL Linux PASS, AND records a "Pending — no host" macOS row. Single-platform Windows-only is no longer acceptable. macOS absence is acknowledged, not a block.
- The pattern of "redesigning a closed-feature spec to absorb its cleanup tail" is a ONE-OFF for feature 003. Future cleanups SHOULD live in new spec numbers (e.g., a future `004-…` or `007-…`), not by redesigning prior specs.
- B1's fix is a few-line behavioral change inside `update-handoff` (both flavors). It does NOT change the v1 handoff JSON schema. Backward-read tolerance from feature 006 still applies.
- B2's fix is contained to `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` — the bash flavor scripts themselves do NOT receive a path-translation step (they already handle their native platform's paths correctly).
- `tests/test-claude-codex-skill-parity.ps1` is unchanged by this feature. It's already cross-platform via pwsh-on-Linux and doesn't invoke bash.

## Out of scope

- Adding new bridge commands, new bash scripts, new tests beyond what FR-014 implies.
- Refactoring or "improving" the PowerShell scripts beyond the FR-001 surgical edit.
- Changing the v1 handoff JSON schema.
- Multi-platform CI matrix (running tests on `windows-latest` + `ubuntu-latest` + `macos-latest` simultaneously). Not blocking for v0.4.2.
- Deleting the 3 RC GitHub releases (`v0.4.0-rc.{1,2,3}`). Optional cosmetic cleanup the user can do later.
- Closing or modifying the existing issue 2581 beyond updating its comment for v0.4.2 metadata.
- Adding sandbox verification automation. The constitution gate is a manual procedure on purpose; automation is a future-feature topic.
- macOS sandbox verification if no macOS host is available within v0.4.2's release window. Defer to a follow-up note in verification.md.
- Touching `.specify/extensions/git/` (the git extension, a different artifact owned by Spec Kit core).
