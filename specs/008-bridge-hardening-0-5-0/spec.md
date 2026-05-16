# Feature Specification: Bridge Hardening & 0.5.0 Cleanup Release

**Feature Branch**: `008-bridge-hardening-0-5-0`

**Created**: 2026-05-16

**Status**: Draft

**Input**: User description: "我们来解决前期遗留问题，准备发布 0.5.0：D1: mac 暂时无法验证；D2: 调研官方推荐方案，严格按照官方方案执行，然后尽可能不用每次发布更新都得 issue；G1/G2/G3: 对齐；Q1: 合并 main，然后我们以后更新不用考虑兼容 0.4.1 及之前的了；Q2: 已经发布了一个 0.4.3 的 issue，待会儿搞完 spec，发个 0.5.0 的，关掉 0.4.3；Q3: 本次顺便看看导致 G1-3 出现的原因，我感觉 speckit-superpowers-bridge 在中断继续、更换窗口或 agent 时还是会漂移，不严格按照 spec 计划与流程执行，你再固化一下。"

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). 0.5.0 must continue honoring the article's separation: Spec Kit owns WHAT, Superpowers owns HOW, the bridge only orchestrates. The drift-hardening work in US1 belongs at the **bridge boundary** (handoff/guard/event-log) — it does not move planning or execution discipline into the bridge.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Bridge Drift Hardening on Session / Agent Resume (Priority: P1) 🎯 MVP

A user mid-feature switches windows, kills the session, or hands the work to a different agent (Claude → Codex or vice versa). When they (or the next agent) resume, the bridge surfaces the **authoritative state** loudly enough that nobody silently keeps working on stale assumptions. Specifically: the next interaction with `update-handoff` / `guard-command` / the bridge skill MUST display the current `feature_directory`, `status`, `artifact_owner`, and the count of unchecked `[ ]` tasks remaining in tasks.md. If tasks.md is structurally inconsistent with the handoff (e.g., status is `complete` but `[ ]` tasks remain that were not declared "deferred"), the bridge MUST emit a visible warning, not silently allow the next step.

**Why this priority**: This is the root cause behind G1/G2/G3 (007 tasks.md left T022-T028 unchecked even after handoff completed; 003 tasks.md still shows ~20 unchecked from v0.4.2; SC-005/SC-006 byte-freeze checks were run but never persisted as evidence). Without this story, every future release will accumulate the same documentation-drift backlog. With this story, the bridge becomes self-policing — the same property the constitution v1.2.0 sandbox gate gave for verification.

**Independent Test**: Simulate a mid-feature resume on `..\test_specify_superpower`: open a fake `tasks.md` with `[ ]` items, transition handoff to `complete`, then run any bridge command. The output MUST flag the mismatch within the first 20 lines. Also: simulate an agent switch by calling `update-handoff -Actor codex` after Claude had ownership; the actor-switch SHOULD be logged with the prior actor in the event log so a later auditor can reconstruct who-did-what.

**Acceptance Scenarios**:

1. **Given** a feature with handoff `status: executing` and tasks.md containing 5 `[ ]` items not marked as deferred, **When** a fresh session runs the bridge skill or `update-handoff`, **Then** the output displays a "Pending tasks: 5" line in the first screen of output, sourced from `feature_directory/tasks.md`.
2. **Given** a feature with handoff `status: complete` and tasks.md containing `[ ]` items that are NOT inside a section explicitly marked `Deferred` / `Optional` / `Out of Scope`, **When** the next bridge invocation happens, **Then** a visible WARNING line is printed (e.g., `[bridge] WARNING: handoff is complete but feature_directory has 6 unchecked tasks; review tasks.md`).
3. **Given** any actor transition (e.g., prior actor was `claude`, current `-Actor codex`), **When** `update-handoff` runs, **Then** the event-log entry includes both `actor` (new) and `prior_actor` (old), and the human-readable output line shows "Actor: claude → codex".
4. **Given** the byte-freeze / spec-history checksum gates (current SC-005 + SC-006 in 007), **When** the release lifecycle hits `complete`, **Then** the bridge writes the evidence (computed hash, diff-line count, timestamp) into a per-feature `verification.md` or appended log line, NOT just into the local shell history.

**North-star check**: This story adds bridge-boundary checks (handoff state vs tasks.md surface). It does NOT add planning, brainstorming, or implementation discipline to the bridge. Spec Kit still owns the WHAT (tasks.md content); Superpowers still owns the HOW (executing tasks). The bridge just refuses to let the two diverge silently.

---

### User Story 2 — Reality Alignment of 007 and 003 Artifacts (Priority: P2)

A maintainer auditing `specs/` two months from now should see tasks.md state that matches reality. Right now `specs/007-*/tasks.md` shows T022-T028 as `[ ]` even though handoff is `complete`, commit `29235e2` landed, branch matches origin, and the byte-freeze (SC-005) + spec-history checksum (SC-006) were both verified. Similarly `specs/003-*/tasks.md` carries leftover `[ ]` checkboxes for v0.4.2 work that shipped.

**Why this priority**: This is the visible evidence that G1+G2 exist. Fixing them is mechanical (check the boxes, add evidence rows); the value is that the audit trail becomes usable again. P2 because it's a one-time data-correction, not an ongoing capability.

**Independent Test**: `grep -c '^- \[ \]' specs/007-*/tasks.md` should drop from 7 (current) to whatever items genuinely remain (likely ≤ 1: the optional T029 catalog-bump issue). `grep -c '^- \[ \]' specs/003-*/tasks.md` should drop to a number matching only genuinely-deferred user-side verification tasks. A new evidence line for SC-005 / SC-006 must exist in `specs/007-*/verification.md` (or a sibling evidence file) recording the byte-freeze diff was empty and the spec-history checksum matched.

**Acceptance Scenarios**:

1. **Given** `specs/007-*/tasks.md` after this story, **When** read, **Then** T022, T023, T024, T025, T026, T027, T028 are all `[x]` with brief evidence pointers; T029 either becomes `[x]` (US3 closes it) or stays `[ ]` with an explicit "Optional, deferred to v0.5.0+" tag.
2. **Given** `specs/003-*/tasks.md` after this story, **When** read, **Then** every task that v0.4.2 actually shipped is `[x]`; the residual `[ ]` items match the 003 spec's SC-004 deferred-count allowance, and they each carry a one-line "deferred because…" tag.
3. **Given** SC-005 (byte-freeze) and SC-006 (spec-history) verifications from the 007 cycle, **When** an auditor reads `specs/007-*/verification.md`, **Then** they find a "## Gate evidence" subsection with the computed hash for SC-006 and a "0 lines diff" line for SC-005, dated 2026-05-16.

---

### User Story 3 — Official Catalog Update Path (Priority: P2)

A future contributor preparing v0.5.1, v0.6.0, etc. should NOT need to file a fresh "Extension Submission" issue against `github/spec-kit` for every patch. Investigate upstream's actually-current recommended flow for already-accepted entries (search current `CONTRIBUTING.md`, the merged PR #2586 thread, and any newer Spec Kit docs); whatever the official answer is, document it in `marketplace/README.md` and adjust our process so that **routine patch releases do not require a new upstream issue**.

**Why this priority**: P2 because the v0.4.3 stable-alias URL already lets users get the latest regardless of catalog staleness, so the immediate user-facing pain is gone. But the catalog row in upstream still shows v0.4.1, and we filed a v0.4.3 issue that's still open. The decision is binary: either future bumps keep filing issues (current path), OR upstream supports an automated discovery path (e.g., release-feed polling) we can opt into. We need to know which it is before v0.5.0 ships.

**Independent Test**: Open `marketplace/README.md` after this story; within the first 60 lines find the up-to-date official process, citing the upstream doc URL or PR thread that establishes it. The v0.4.3 catalog-update issue is closed (with a comment pointing to v0.5.0). A v0.5.0 catalog-update issue exists, filed with the body in `marketplace/extension-submission-body.md` (refreshed for v0.5.0).

**Acceptance Scenarios**:

1. **Given** upstream's current published guidance, **When** the research is recorded, **Then** `marketplace/README.md` cites the specific upstream URL or PR/issue thread that establishes the per-release update path (issue vs PR vs automated polling vs other), with the citation dated 2026-05-16.
2. **Given** the v0.4.3 catalog issue is currently open against `github/spec-kit`, **When** v0.5.0 ships, **Then** the v0.4.3 issue is closed with a comment linking to the new v0.5.0 issue (or to the automated path if upstream now supports one).
3. **Given** `marketplace/extension-submission-body.md` after this story, **When** read, **Then** version is `0.5.0`, both URLs are the v0.5.0 versioned + stable-alias forms, SHA256 placeholder is filled by the workflow.
4. **Given** the official method permits an automated/lighter path, **When** that path exists, **Then** `marketplace/README.md` documents the lighter path as the default and demotes "open a fresh issue" to a fallback for cases when the lighter path fails.

---

### User Story 4 — Branch Consolidation & 0.5.0 Baseline (Priority: P2)

`main` is currently ~27 commits behind `003-cross-platform-cleanup`; every release v0.4.0 through v0.4.3 was tagged on the feature branch, never merged. v0.5.0 must end with `main` containing all shipped code (including 008's work) AND v0.5.0 being the new minimum-compatibility baseline going forward. After this story, no future spec needs to call out backward compatibility with v0.4.0 or v0.4.1; v0.4.2 / v0.4.3 still upgrade directly because the handoff schema is byte-frozen, but the documentation no longer lists pre-0.4.2 as a supported direct-upgrade source.

**Why this priority**: P2 because trunk-based hygiene is a chronic risk rather than an acute one. But shipping 0.5.0 from yet-another-long-running branch would repeat the same mistake. Doing the merge as part of 008 closes the loop.

**Independent Test**: After this story, `git log main..HEAD` from the 008 branch returns only the 008-cycle commits (not the prior 003 backlog); `main` tip contains `extension.yml` showing version `0.5.0`; `CHANGELOG.md` `[0.5.0]` section explicitly states "v0.4.2 is now the minimum supported direct-upgrade baseline".

**Acceptance Scenarios**:

1. **Given** the pre-merge state (main ~27 commits behind 003-cross-platform-cleanup), **When** US4 work completes, **Then** main contains every commit from `003-cross-platform-cleanup` up through and including the 007 retrospective.
2. **Given** main is up-to-date, **When** v0.5.0 is tagged, **Then** it's tagged on a branch (or directly on main, per Clarifications Q2) that includes the 008 cycle's commits.
3. **Given** the v0.5.0 `CHANGELOG.md` entry, **When** read, **Then** it explicitly declares the minimum direct-upgrade baseline as v0.4.2 and the previous "branch = release line" pattern as discontinued.
4. **Given** any future spec template or AGENTS.md instructions, **When** read after this story, **Then** they reference v0.4.2 as the lowest version that future cycles assume; v0.4.0/v0.4.1 are referenced only in CHANGELOG historical entries.

---

### User Story 5 — v0.5.0 Verification Inheritance (Priority: P3)

Constitution v1.2.0 §"End-User Verification Sandbox" requires every release to record sandbox-install verification in the spec's `verification.md`. v0.5.0 must inherit the same shape as v0.4.2 and v0.4.3: Windows PowerShell PASS + at least one Linux/macOS bash PASS, with the macOS row marked PENDING (no host) per Clarifications Q1 of this spec.

**Why this priority**: P3 because the sandbox procedure is already defined and exercised twice (v0.4.2, v0.4.3); v0.5.0 just inherits it. This story exists to make the inheritance explicit in tasks.md and prevent another "verification record landed in the wrong file" repeat of the v0.4.2→v0.4.3 verification-relocation bug.

**Independent Test**: `grep -c '^## v' specs/008-*/verification.md` returns 1 (only `## v0.5.0`). The section has Windows PS + WSL Linux PASS rows with the v0.5.0 release SHA256 and macOS PENDING row with the noted "no host" reason.

**Acceptance Scenarios**:

1. **Given** v0.5.0 release artifacts are published, **When** the sandbox runs on Windows PS + WSL Linux bash, **Then** both rows are PASS with matching bridge_sha256.
2. **Given** the verification record exists, **When** the 008 handoff transitions to `complete`, **Then** US1's drift-hardening check passes (no `[ ]` tasks left undeferred, evidence persisted).

---

### Edge Cases

- **Resume after an unfinished feature was abandoned**: If a feature was started but never completed (handoff stuck at `executing` for days), the US1 drift check should warn but not block; an explicit `update-handoff -Status abandoned` path may be needed (out of scope for v0.5.0; document as a v0.5.1 candidate).
- **Tasks.md uses non-standard checkbox forms**: If a task uses `[~]` or `[-]` or any non-`[ ]`/`[x]` marker, US1's "unchecked count" logic must treat them as ambiguous → count separately and warn that the format is non-standard.
- **Multiple "Deferred"/"Optional"/"Out of Scope" section names**: US1 must recognize at least the case-insensitive set `{deferred, optional, out of scope, won't do, future}` as exemption sections. Per Clarifications Q6, **only section headers** participate in exemption — inline tokens inside a task line do not.
- **Upstream catalog flow turns out to require manual issues regardless**: US3 must record the negative finding clearly ("no lighter path exists upstream as of 2026-05-16") rather than inventing one. Per Clarifications Q5, the fallback policy is: file the catalog-update issue only on MINOR/MAJOR bumps; patch releases rely on the stable-alias URL and skip the upstream issue.
- **Main merge surfaces conflicts**: US4 must produce a clean linear or merge-commit-based result; if conflicts exist (unlikely — main has had no new commits), document the resolution.
- **macOS host becomes available mid-cycle**: US5 should opportunistically capture a macOS PASS row if a host appears; otherwise PENDING stays. This does not block 0.5.0.

## Requirements *(mandatory)*

### Functional Requirements

#### Bridge runtime (US1)

- **FR-001**: `update-handoff.ps1` and `update-handoff.sh` MUST, on every successful state mutation, print a state summary including: `feature_directory`, `status`, `artifact_owner`, `actor` (new), `prior_actor` (if differs from new), and a line `Pending tasks: <N>` where `N` is the count of lines in `<feature_directory>/tasks.md` matching the canonical task-ID checkbox regex `^- \[ \] T\d+` that are NOT inside a deferred-exemption section. If `<feature_directory>/tasks.md` does not exist, print `Pending tasks: (no tasks.md)`. The canonical regex deliberately excludes generic Markdown checkboxes (`^- \[ \]` without a `T###` prefix) to avoid over-counting acceptance-scenario placeholders and other ad-hoc unchecked bullets per Clarifications Q1.
- **FR-002**: `guard-command.ps1` and `guard-command.sh` MUST emit the same state-summary block (same fields as FR-001) on every allow/deny decision, prefixed with `[bridge state]`.
- **FR-003**: When status transitions to `complete` AND `Pending tasks` > 0 (per FR-001 counting rules), the script MUST emit `[bridge] WARNING: complete but <N> unchecked tasks remain in tasks.md; review or mark deferred.` to stderr. This is a warning, not an error — the transition still succeeds. Rationale: the bridge does not own task-content correctness; it surfaces the inconsistency for the human/agent to resolve.
- **FR-004**: The event log entry written to `bridge-events.jsonl` for any handoff transition MUST include both `actor` and `prior_actor` fields. When they differ, the `decision`/`reason` field MUST also note the actor change (e.g., `"reason": "actor change claude → codex"`).
- **FR-005**: Deferred-exemption sections are recognized case-insensitively by header text matching the regex `^#+\s+(.*\b(deferred|optional|out of scope|won.?t do|future|wontfix|backlog)\b.*)$`. Any task-ID checkbox line matching `^- \[ \] T\d+` (the FR-001 canonical regex) under such a header (until the next sibling header) is excluded from the FR-001 pending count. Per Clarifications Q6, **inline tokens** inside a task line (e.g., `- [ ] T029 (deferred to v0.5.0+)`, `- [ ] T032 *[deferred]*`) are NOT recognized as exemption signals — only the section-header form is. Authors who want a task to be exempted MUST move it under a matching section header.

#### Documentation / reality alignment (US2)

- **FR-006**: `specs/007-catalog-distribution-polish/tasks.md` MUST be updated so that T022, T023, T024, T025, T026, T027, T028 all show `[x]` with a one-line evidence pointer (commit hash, snapshot id, or computed value). T029 either becomes `[x]` (closed via US3) or moves under a "## Deferred" / "## Optional" subheader.
- **FR-007**: `specs/003-bridge-cross-platform-scripts/tasks.md` MUST be updated so that every task that v0.4.2 actually shipped reads `[x]`. Genuinely deferred user-side verification tasks (the residual ~17 from the original 003 list) MUST move under a clearly-labeled "## Deferred (user-side verification, awaiting future cycles)" subsection.
- **FR-008**: `specs/007-catalog-distribution-polish/verification.md` MUST gain a `## Gate evidence` subsection (or sibling file) recording: SC-005 byte-freeze diff line count (must be 0) at the 007 cycle's complete point; SC-006 spec-history checksum value at v0.4.1 tag; dated 2026-05-16; operator name.

#### Catalog & marketplace (US3)

- **FR-009**: `marketplace/README.md` MUST cite the upstream-authoritative source (URL, doc path, or PR/issue thread) that establishes how already-accepted catalog entries get version-bumped, with citation date 2026-05-16. If multiple paths exist, the lightest path (least operator overhead per release) is documented as the default. Per Clarifications Q5, if upstream documents only an issue-per-release method, our policy is **minor/major releases file the issue; patch releases skip it and rely on the stable-alias URL**. This policy MUST be documented in `marketplace/README.md` alongside the upstream citation.
- **FR-010**: The currently-open v0.4.3 catalog-update issue against `github/spec-kit` MUST be closed (or commented + closed) with a pointer to the v0.5.0 update issue. Because v0.5.0 IS a minor bump under the Q5 policy, the v0.5.0 issue is filed and v0.4.3 is superseded. If FR-009 research uncovers an automated path, point to that instead.
- **FR-011**: `marketplace/extension-submission-body.md` and `marketplace/catalog-entry.json` MUST be updated to v0.5.0: version, download_url (versioned), stable-alias URL, SHA256 (filled by release workflow).
- **FR-012**: `marketplace/extensions-readme-row.md` columns MUST remain aligned with upstream's `docs/community/extensions.md` table shape as of the FR-009 research date.

#### Branch & compat (US4)

- **FR-013**: After the merge step, `git log main..HEAD` on `008-bridge-hardening-0-5-0` MUST return only commits authored during the 008 cycle (i.e., the 003 backlog is now on `main`, not still ahead of `main`).
- **FR-014**: `CHANGELOG.md` `[0.5.0]` section MUST contain a "Compatibility" subsection that declares: (a) v0.4.2 is the new minimum direct-upgrade baseline; (b) handoff schema remains byte-stable, so v0.4.2/v0.4.3 users upgrade with no migration; (c) v0.4.0/v0.4.1 users should upgrade through v0.4.2 first (or simply re-install fresh).
- **FR-015**: `AGENTS.md` (and any peer doc that references compat) MUST be updated to reflect the new baseline; references to pre-0.4.2 versions outside CHANGELOG / historical context MUST be removed.

#### Release (cuts across US1–US5)

- **FR-016**: `extension.yml` `extension.version` MUST be `"0.5.0"`. `marketplace/catalog-entry.json` `version` MUST be `"0.5.0"` and `download_url` MUST point at the v0.5.0 versioned ZIP. `tests/test-claude-codex-skill-parity.ps1` and the other smoke tests MUST still pass.
- **FR-017**: The GitHub Actions release workflow continues to upload both `speckit-superpowers-bridge-v0.5.0.zip` and the stable-alias `speckit-superpowers-bridge.zip` (FR-001 from 007 spec, inherited unchanged).

#### Verification (US5)

- **FR-018**: `specs/008-bridge-hardening-0-5-0/verification.md` MUST be created with a single `## v0.5.0` section, schema per `../003-bridge-cross-platform-scripts/contracts/verification-record.md`, containing rows for `windows-powershell`, `wsl-linux-bash` (both PASS with the v0.5.0 SHA256), and `macos-bash` (PENDING with the documented "no host" reason).
- **FR-019**: The sandbox runs for FR-018 MUST exercise the US1 drift-hardening output: the operator confirms in the Notes column that `Pending tasks: N` was visible in handoff output AND that a deliberate-mismatch test (e.g., transition to complete with an unchecked task) triggered the WARNING line.

#### Constraints inherited unchanged

- **FR-020**: macOS sandbox remains PENDING (no host). Inherited from v0.4.2 / v0.4.3. Not blocking.

### Key Entities *(include if feature involves data)*

- **Pending-tasks count**: Computed by the bridge from `<feature_directory>/tasks.md`. Integer ≥ 0. Source-of-truth = the file content at the moment of bridge invocation. Stored implicitly in the script's output line, NOT cached.
- **Prior actor**: The `actor` value present in `superpowers-handoff.json` immediately before the current `update-handoff` call. Persisted as `prior_actor` on the event-log line for the transition.
- **Gate evidence record**: Per-release subsection inside `verification.md` capturing computed SC-005 / SC-006 values, dated, operator-attributed. Same schema philosophy as the existing PASS/PENDING rows.
- **Compatibility baseline declaration**: A single line in CHANGELOG `[0.5.0]` § Compatibility naming v0.4.2 as the new minimum direct-upgrade source.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (US1, MVP): A scripted regression test invoking `update-handoff` on a synthetic feature_directory with 3 unchecked tasks displays `Pending tasks: 3` in stdout within the first 20 lines of output. The same invocation with a fully-checked tasks.md displays `Pending tasks: 0`.
- **SC-002** (US1): A scripted regression test transitioning a synthetic handoff to `complete` while tasks.md has 1+ unchecked non-deferred task emits the WARNING line to stderr. With a deferred-exemption-only set of unchecked tasks, NO warning is emitted (false-positive prevention).
- **SC-003** (US1): The `bridge-events.jsonl` line for an actor-switch transition (`claude → codex`) contains both fields `"actor":"codex"` and `"prior_actor":"claude"`, machine-parseable via `jq`.
- **SC-004** (US2): `grep -c '^- \[ \] T' specs/007-*/tasks.md` (looking specifically at task ID checkboxes, not generic checkboxes) returns ≤ 1 after this story. The same grep on `specs/003-*/tasks.md` returns a number matching only the explicitly-deferred user-side verification tasks (documented in the spec body).
- **SC-005** (US2): `specs/007-*/verification.md` contains a "Gate evidence" record with SC-005 (byte-freeze) and SC-006 (spec-history) computed values, dated 2026-05-16.
- **SC-006** (US3): `marketplace/README.md` cites a specific upstream URL or PR thread for the per-release catalog-update path, with the citation dated 2026-05-16, and demotes "open a fresh issue per release" to a fallback if upstream supports a lighter path.
- **SC-007** (US3): The v0.4.3 catalog-update issue against `github/spec-kit` is closed by the time v0.5.0 ships.
- **SC-008** (US4): `git log main..HEAD` from the 008 branch (or 008 merged into main, depending on Clarifications Q2 resolution) shows only 008-cycle commits.
- **SC-009** (US4): `CHANGELOG.md` `[0.5.0]` § Compatibility explicitly names v0.4.2 as the minimum direct-upgrade baseline.
- **SC-010** (US5 / constitution v1.2.0 gate): `specs/008-*/verification.md` `## v0.5.0` contains 3 rows: Windows PS PASS, WSL Linux PASS, macOS PENDING with reason. All PASS rows carry the v0.5.0 release SHA256.
- **SC-011** (release): GitHub Actions release run for tag `v0.5.0` is green; both versioned + stable-alias ZIP assets uploaded with matching digests.
- **SC-012** (handoff): The 008 handoff lifecycle ends with `status: complete`, `feature_directory: specs/008-bridge-hardening-0-5-0`, and US1's drift-hardening check returns clean (zero non-deferred unchecked tasks).
- **SC-013** (north-star alignment): The Q3 bridge-hardening work touches `bridge-events.jsonl` schema and the `update-handoff` / `guard-command` script output ONLY; it does NOT add new Spec Kit commands, does NOT add new Superpowers skills, does NOT introduce a planning or execution discipline inside the bridge. Verified by `git diff v0.4.3..HEAD --stat -- .specify/extensions/speckit-superpowers-bridge/` showing changes confined to scripts + SKILL.md.

## Assumptions

- The user-facing upgrade path remains `specify extension add ... --from <stable-alias-URL>`; the alias was introduced in v0.4.3 and stays.
- `..\test_specify_superpower` remains the canonical sibling sandbox dir per constitution v1.2.0.
- Spec Kit version pinned to `>= 0.8.10` (current install-options); 0.5.0 does NOT bump that floor.
- `jq` is available in the bash flavor's sandbox; if absent, US1's bash-side pending-count fallback uses `grep -c` directly (no JSON parsing needed for this counter).
- The new pending-task counting and warning logic adds ≤ ~80 lines combined to `update-handoff.{ps1,sh}` and `guard-command.{ps1,sh}`; runtime overhead per invocation stays under 50 ms on a typical dev box.
- Constitution v1.2.0 sandbox gate stays unchanged (Windows + at least one Linux/macOS PASS, with explicit reason for any PENDING).
- Branch-merge to `main` for Q1 follows Clarifications Q2 = Option B: all 008-cycle work lands on the `008-bridge-hardening-0-5-0` branch (already created off `003-cross-platform-cleanup`); v0.5.0 is tagged on 008; a single PR from 008 → main lands the 003 backlog + the entire 008 cycle in one merge at the end. No mid-cycle branch reshuffling.
- The Q3 hardening shape follows Clarifications Q3 = Option C: minimum-viable. The bridge prints state summary + `Pending tasks: N` on every script invocation, warns on `complete`-with-unchecked, logs `prior_actor`. NO opt-in `--strict` flag, NO new `bridge-state` subcommand, NO SKILL.md banner. Lightest touch that satisfies FR-001..FR-005 and SC-013 (north-star).
- Catalog-update issue research (FR-009) uses the upstream `github/spec-kit` repo's `CONTRIBUTING.md` + `docs/community/` directory as of 2026-05-16; if the doc changes mid-cycle, the spec's date stamp anchors which version was sourced.

## Out of Scope

- **No bridge schema break**: `superpowers-handoff.json` field shape is preserved (new `prior_actor` lives in event log, not in handoff JSON). v0.4.2/v0.4.3 handoff files continue to parse cleanly under v0.5.0 scripts.
- **No new Spec Kit commands or Superpowers skills**: per SC-013 / north-star check.
- **No `abandoned` handoff state**: US1 surfaces stale `executing` states but does not introduce a new lifecycle terminal. (Candidate for v0.5.1.)
- **No retroactive recompute of historical SC-005/SC-006 values**: gate evidence is added prospectively at the 007/008 cycle marks; pre-007 releases keep their existing audit trail unchanged.
- **No upstream PR against `extensions/catalog.community.json`**: still issue-based unless FR-009 research uncovers a different official path.
- **No macOS sandbox run for v0.5.0**: deferred per Clarifications inheriting v0.4.2 Q3 and v0.4.3 Q3.
- **No multi-feature concurrency**: only one active `feature_directory` at a time, as today.

## Dependencies and Assumptions

- Assumes the GH release workflow for `v0.4.3` is repeatable for `v0.5.0` with no infrastructure changes.
- Assumes upstream Spec Kit's catalog shape and community-doc location are stable as of 2026-05-16 (PR #2586 reference shape).
- Assumes WSL Linux bash 5.2.21 + jq 1.7 environment remains representative of Linux/macOS bash for the sandbox gate.
- Assumes a clean working tree on the `008-bridge-hardening-0-5-0` branch as it stands now (verified).

## Clarifications

### Session 2026-05-16

- Q1 (inherited): Does v0.5.0 inherit the macOS-deferral from v0.4.2 / v0.4.3? → A: Yes. No host available; constitution v1.2.0 Windows + Linux requirement is satisfied by WSL Linux. macOS row stays PENDING.
- Q2: Branch merge timing & mechanic for Q1 main consolidation. → A: **Option B**. Continue work on `008-bridge-hardening-0-5-0` as currently created (branched off `003-cross-platform-cleanup`). Tag v0.5.0 on 008. After v0.5.0 ships and verification.md PASS rows are recorded, open a single PR `008-bridge-hardening-0-5-0 → main` that merges the entire 003 backlog plus the 008 cycle in one go. No mid-cycle branch reshuffling. Rationale: pragmatic, minimizes branch-management risk during the cleanup release; the next post-0.5.0 feature branches off main fresh.
- Q3: Bridge hardening shape & ceiling. → A: **Option C** (minimum-viable). Implement exactly FR-001..FR-005: state summary + `Pending tasks: N` on every script invocation, WARNING line on `complete`-with-unchecked, `prior_actor` in event log. Do NOT add a `--strict` flag, do NOT add a `bridge-state` subcommand, do NOT add a SKILL.md banner. Rationale: lightest touch satisfies SC-013 north-star (bridge-boundary checks only, no new commands / skills / planning surface).
- Q4: Pending-task counting scope — count any unchecked Markdown bullet (`^- \[ \]`) or only task-ID lines (`^- \[ \] T\d+`)? → A: **Option A** (task-ID prefix only). The canonical regex is `^- \[ \] T\d+`. Generic Markdown checkboxes elsewhere in tasks.md (e.g., acceptance-scenario placeholders, ad-hoc TODOs) are NOT counted. Rationale: Spec Kit's tasks.md template uses `- [ ] T###` consistently across 001-007; the T-prefix gives near-zero noise. Counting generic checkboxes would over-warn and dilute US1's drift signal. SC-004 already encodes this regex; FR-001 and FR-005 are updated to match.
- Q5: D2 catalog-update fallback if upstream has no lighter path documented. → A: **Option C** (minor/major-only). Patch releases (e.g., 0.5.0 → 0.5.1) skip the upstream catalog-update issue and rely on the stable-alias URL added in v0.4.3 to serve users. Only MINOR/MAJOR bumps (e.g., 0.5.x → 0.6.0, 0.x → 1.0.0) file a fresh "Extension Submission" issue against `github/spec-kit`. Rationale: balances "strictly follow official method" (still issue-based when filed) with "minimize per-release overhead"; patches in this project so far have been pure docs/marketplace polish or surgical bridge fixes, which don't change the catalog-visible surface. Affects FR-009 (policy doc), FR-010 (close v0.4.3 issue with pointer to v0.5.0 issue since 0.5.0 IS a minor bump), FR-011 (continue updating v0.5.0 entry), and Edge Cases ("Upstream catalog flow turns out to require manual issues regardless").
- Q6: Deferred-marker granularity — does FR-005's exemption recognize inline tokens (e.g., `- [ ] T029 (deferred)`) or only section-header form? → A: **Option A** (section header only). Inline tokens like `(deferred)`, `[deferred]`, `*[deferred]*` inside a task line are NOT recognized as exemption signals. To defer a task, the author MUST move it under a section header that matches the FR-005 regex (e.g., `## Deferred (user-side verification, awaiting future cycles)`). Rationale: US1's drift signal works only if "deferred" is structurally explicit — inline scatter is exactly the kind of fuzz that caused G1/G2 in the first place. FR-007 already prescribes the section-header form for 003 cleanup; this clarification cements it as the universal exemption shape. Authors who type an inline `(deferred)` note for context are welcome to do so, but it has zero effect on the pending-task count unless the task is also under an exemption section header.
