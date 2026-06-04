# Feature Specification: v1.0.0 Stable Protocol Release Hardening

**Feature Branch**: `013-v1-0-release-hardening`

**Created**: 2026-06-04

**Status**: Draft

**Input**: User description: "就B吧，我们1.0.0版本的开发目标确定了，重写spec，准备实现。" This accepts the recommended "stable protocol release" direction from the research phase: prepare `speckit-superpowers-bridge` for a 1.0.0 release by aligning with current Spec Kit, Superpowers, Codex, and Claude Code behavior; incorporating useful lessons from Superspec, SuperB, and Comet; keeping the product lightweight and decoupled; and making Windows PowerShell plus Linux bash compatibility a hard release gate.

**Reference context**:

- Current bridge release baseline is 0.7.2. The 1.0.0 release is a stability and verification milestone, not a rewrite.
- The product promise remains: Spec Kit owns WHAT (`constitution.md`, `spec.md`, `plan.md`, `tasks.md`); Superpowers, Codex, and Claude Code own HOW (implementation discipline, agent execution, review, verification).
- The 1.0.0 release must demonstrate that the bridge is installable and usable by real users on both supported platform families: Windows PowerShell 5.1+ and Linux bash. WSL bash is valid Linux-path evidence but does not replace native Windows PowerShell evidence.
- The release must use real agent verification where feasible. The user explicitly permits invoking real `codex` and `claude` in the sibling sandbox `../test_specify_superpower`.
- Community competitors show useful patterns but also scope risks. The bridge should absorb readiness diagnostics, evidence records, namespace validation, bilingual documentation parity, and real demos/transcripts; it should not become a heavy lifecycle manager, state machine, daemon, or alternate Superpowers executor.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Release a stable lightweight 1.0.0 bridge (Priority: P1)

A maintainer prepares the first 1.0.0 release and needs confidence that the published artifact still behaves like the existing thin bridge: only guard, handoff, execute, and status/readiness surfaces enforce the boundary between Spec Kit and Superpowers; no hidden workflow engine or competing implementation lifecycle has been added.

**Why this priority**: This is the core product decision for 1.0.0. A major release should increase user trust without invalidating the bridge's lightweight and native-first principles.

**Independent Test**: A release reviewer can inspect the 1.0.0 diff and release package, then verify that no new daemon, service, database, global plugin mutation, independent lifecycle state machine, or vendor-managed Spec Kit skill edit was introduced. Existing bridge behavior still passes the smoke suite.

**Acceptance Scenarios**:

1. **Given** the 0.7.2 baseline, **When** the 1.0.0 release changes are reviewed, **Then** the public bridge surface remains thin and additive, with no new heavy runtime or independent lifecycle owner.
2. **Given** a feature with generated Spec Kit artifacts, **When** implementation ownership is handed off, **Then** the bridge still treats `tasks.md` as the implementation contract and does not replace `plan.md` or `tasks.md` with a Superpowers-generated plan.
3. **Given** a reviewer checks vendor-managed skill directories, **When** the release diff is inspected, **Then** generated `.agents/skills/speckit-*` and `.claude/skills/speckit-*` files remain unmodified except for the bridge-owned `speckit-superpowers-bridge` deliverables.

---

### User Story 2 - Verify Windows and Linux as first-class release targets (Priority: P1)

A user installs the bridge on either Windows PowerShell 5.1+ or Linux bash and expects the same protocol behavior, including release ZIP installation, script dispatch, line endings, guard decisions, handoff updates, status/readiness output, and archived release evidence.

**Why this priority**: The user explicitly added Windows/Linux compatibility as a requirement. A 1.0.0 release that only passes WSL bash would be misleading.

**Independent Test**: The release candidate is validated through a platform matrix with native Windows PowerShell and Linux bash rows. Each row records install outcome, script flavor, core bridge cycle result, smoke result, and any deviation. Release readiness fails if either first-class platform row is missing or failed.

**Acceptance Scenarios**:

1. **Given** a release candidate ZIP, **When** it is installed into a clean Linux/bash Spec Kit project, **Then** guard, handoff, status/readiness, archive, and release smoke checks pass without using a local development path.
2. **Given** the same release candidate ZIP, **When** it is installed into a clean Windows PowerShell 5.1+ Spec Kit project, **Then** equivalent PowerShell checks pass without requiring WSL or Git Bash as a substitute.
3. **Given** line-ending rules are applied, **When** the release package is inspected and installed on both platforms, **Then** bash scripts retain LF, PowerShell scripts retain Windows-compatible line endings, and ZIP entries use portable path separators.
4. **Given** the current WSL development shell lacks `pwsh`, **When** 1.0.0 verification is planned, **Then** the missing WSL `pwsh` is recorded as an environment constraint and native Windows validation is performed separately rather than skipped.

---

### User Story 3 - Prove real Codex and Claude compatibility in an end-user sandbox (Priority: P2)

A maintainer wants evidence that the bridge works not only through scripted smoke tests, but also when real Codex and Claude Code agents load the repo instructions, discover the bridge skill, and operate on a sandbox project as an end user would.

**Why this priority**: The bridge's value is cross-agent handoff. Script tests can validate file behavior, but they cannot prove that Codex and Claude see the same operational contract.

**Independent Test**: In the sibling sandbox `../test_specify_superpower`, the maintainer installs the release artifact and runs bounded real-agent verification with `codex` and `claude`. Each run produces a record showing the agent version, platform flavor, prompt boundary, commands exercised, pass/fail result, and whether any manual intervention was needed.

**Acceptance Scenarios**:

1. **Given** a clean sandbox and a release candidate artifact, **When** Codex runs a bounded noninteractive verification, **Then** it can identify the bridge context, run or request the correct bridge operations, and leave a clear pass/fail record without modifying the source repository.
2. **Given** the same sandbox and artifact, **When** Claude Code runs a bounded verification, **Then** it can load the relevant skills/instructions and exercise the same bridge contract from the Claude surface.
3. **Given** either real-agent verification cannot authenticate or run in the maintainer environment, **When** release evidence is assembled, **Then** the blocker is recorded explicitly with the exact command attempted and the release cannot claim that agent as verified.

---

### User Story 4 - Give users a trustworthy readiness and documentation surface (Priority: P2)

A user evaluating the bridge compares it with Superspec, SuperB, and Comet, then wants to understand why this bridge is intentionally smaller and how to confirm their own installation is healthy before trusting it for implementation handoff.

**Why this priority**: Research showed users benefit from `status`/`doctor` style feedback and clear comparison docs. The bridge already has `bridge-status`; 1.0.0 should make readiness obvious without adding a heavy command suite.

**Independent Test**: A user can run one documented readiness/status flow and get actionable output about script flavor, installed bridge files, active feature state, command namespace alignment, required tools, supported agents, and recommended next step. The README and Chinese README explain the product boundary and competitor differences consistently.

**Acceptance Scenarios**:

1. **Given** a correctly installed bridge, **When** the user runs the documented readiness/status check, **Then** the output confirms the active script flavor, core files, namespace alignment, and next action in under a few seconds.
2. **Given** a broken install, missing shell dependency, namespace drift, or incomplete package, **When** readiness is run, **Then** the user sees a specific failing item rather than a generic "not ready" message.
3. **Given** a user reads either README language, **When** they compare this bridge with heavier alternatives, **Then** they can tell that this bridge deliberately delegates to native Spec Kit, Superpowers, Codex, and Claude capabilities instead of replacing them.

---

### User Story 5 - Publish with reproducible release evidence and truthful demo material (Priority: P3)

A maintainer wants the 1.0.0 announcement, marketplace submission, and demo assets to reflect the real release behavior rather than illustrative shell-only output.

**Why this priority**: Demo quality matters for adoption, but it is secondary to compatibility and release correctness. The release must not overstate fake or partial verification as real.

**Independent Test**: The release record contains a verification summary, release artifact hash, platform matrix, real-agent evidence, and either a real captured demo or a clearly labelled transcript if GIF tooling is unavailable.

**Acceptance Scenarios**:

1. **Given** demo GIF tooling is available, **When** 1.0.0 demos are refreshed, **Then** the captured flow is derived from a real sandbox run or real transcript, not a purely fake shell script.
2. **Given** demo GIF tooling is unavailable, **When** the release is prepared, **Then** the release includes truthful transcript-based evidence and does not claim a regenerated real GIF.
3. **Given** the marketplace catalog entry is prepared, **When** the upstream submission is reviewed, **Then** version, stable download URL, namespace, capabilities, and verification notes are consistent with the shipped artifact.

### Edge Cases

- What happens if upstream Spec Kit, Superpowers, Codex, or Claude ships another version during 1.0.0 work? The release evidence records the exact verified versions and date. If a newer version materially affects install or invocation behavior before release, the compatibility baseline is refreshed before tagging.
- What happens if Windows PowerShell validation cannot run from WSL? It is not counted as passed. A native Windows run must be recorded separately, or the feature remains incomplete.
- What happens if the release workflow lacks permission to update workflow files or publish artifacts? The issue is recorded as a release blocker; 1.0.0 cannot claim automated release readiness until the workflow gap is resolved or a documented manual release path is approved.
- What happens if a real Codex or Claude invocation is unavailable because authentication is missing? The affected agent row is marked blocked with exact evidence. The release cannot claim that agent as verified.
- What happens if the sibling sandbox is dirty from prior tests? Verification may reset or isolate the sandbox, but the release record must state the reset method and prove the bridge was installed from the release artifact, not from local dev state.
- What happens if `vhs` or other recording tools are unavailable? Demo refresh falls back to a truthful transcript and release notes disclose that GIF regeneration was not performed.
- What happens if a competitor feature appears attractive but would add a new lifecycle owner or state machine? It is excluded from 1.0.0 and may be documented as intentionally out of scope.
- What happens if the upstream catalog still lists an older version or version-pinned URL? The source repo prepares corrected submission material and tracks the upstream PR/issue as a post-tag distribution step.
- What happens if PowerShell and bash behavior diverge? The release is blocked until the behavior is either made equivalent or the difference is explicitly documented as unsupported.
- What happens if Windows Unicode or encoding behavior differs from Linux output? The readiness and smoke evidence must include Windows output parsing for the affected scripts, with user-visible text remaining readable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The release MUST bump the bridge's public version to `1.0.0` consistently across release metadata, package metadata, marketplace metadata, changelog, and verification records.
- **FR-002**: The release MUST define a verified compatibility baseline for current upstream tools, including at minimum Spec Kit, Superpowers, Codex CLI, Claude Code, bridge version, verification date, and platform rows.
- **FR-003**: The release readiness checks MUST fail when `extension.id`, marketplace/catalog id, command namespace, or hook command namespace are inconsistent. All bridge command names and hook references MUST align with the extension namespace `speckit-superpowers-bridge`.
- **FR-004**: The release readiness checks MUST verify the release package contains the expected root manifest, bridge commands, bash scripts, PowerShell scripts, README files, license, changelog, and verified-version evidence.
- **FR-005**: The release process MUST include a Linux/bash validation row that runs the full bash smoke suite and an install-style bridge cycle from a packaged artifact.
- **FR-006**: The release process MUST include a Windows PowerShell 5.1+ validation row that exercises the PowerShell flavor for guard, handoff, status/readiness, archive, package installation, and line-ending sensitive paths.
- **FR-007**: The release workflow MUST be aligned with the repository's actual test inventory and MUST NOT reference removed or nonexistent test files as if they were release gates.
- **FR-008**: The release MUST include a lightweight readiness or doctor-style surface that reports installation health, script flavor, required local tools, bridge namespace consistency, active feature state, supported agent evidence, and recommended next step. This MAY extend the existing status surface rather than adding a new extension command.
- **FR-009**: The readiness surface MUST remain read-mostly and lightweight: it MUST NOT create a new lifecycle state file, run implementation tasks, mutate user source files, or replace existing guard/handoff semantics.
- **FR-010**: The release MUST preserve existing bridge guard, handoff, status, auto-archive, and execute behavior unless a change is explicitly required for compatibility or release validation.
- **FR-011**: The release MUST verify real end-user installation in `../test_specify_superpower` using a release artifact or release-equivalent packaged artifact, not a local development install path.
- **FR-012**: The release MUST include bounded real Codex verification in the sandbox, recording exact version, prompt boundary, platform, commands or surfaces exercised, outcome, and any manual intervention.
- **FR-013**: The release MUST include bounded real Claude Code verification in the sandbox, recording exact version, prompt boundary, platform, commands or surfaces exercised, outcome, and any manual intervention.
- **FR-014**: README.md and README.zh-CN.md MUST be updated in sync to describe 1.0.0 positioning, Windows/Linux support, verified versions, readiness/status usage, sandbox verification, and the lightweight-vs-competitor distinction.
- **FR-015**: The release documentation MUST explain the relationship to Superspec, SuperB, and Comet factually: which ideas were adopted, which were intentionally excluded, and why the bridge remains thinner.
- **FR-016**: Demo material MUST be made truthful for 1.0.0: either refreshed from a real sandbox/agent transcript or clearly labelled as illustrative if regeneration is not completed.
- **FR-017**: The release runbook MUST document the full 1.0.0 gate sequence, including version sync, readiness validation, Linux tests, Windows tests, sandbox install, real Codex/Claude verification, artifact hash capture, release publishing, stable alias verification, and upstream catalog submission.
- **FR-018**: Marketplace submission artifacts MUST be updated for 1.0.0, including version, stable download URL policy, capability counts, support matrix, and AI-assistance disclosure if applicable.
- **FR-019**: The 1.0.0 change set MUST NOT introduce a daemon, service, database, custom DSL, parallel task runner, or independent workflow state machine.
- **FR-020**: The 1.0.0 change set MUST NOT hand-edit vendor-managed generated Spec Kit skills under `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; bridge-owned skill files may be updated only to reflect actual bridge behavior.
- **FR-021**: The release evidence MUST record all known blockers or deferred items explicitly. A missing Windows validation row, missing real-agent row, broken package install, or unresolved release workflow gap blocks completion rather than becoming a silent caveat.
- **FR-022**: The release MUST keep backward compatibility for existing bridge users upgrading from the current direct-upgrade baseline documented by the project. Existing handoff files tolerated by 0.7.2 MUST remain readable unless a migration is documented and verified.

### Key Entities *(include if feature involves data)*

- **Compatibility Baseline**: The verified set of upstream and bridge versions for the release. Includes Spec Kit, Superpowers, Codex CLI, Claude Code, platform flavor, verification date, and notes about unsupported or blocked rows.
- **Platform Verification Matrix**: A release evidence table with at least Windows PowerShell and Linux bash rows. Each row records install method, package hash, smoke result, sandbox result, readiness result, and pass/fail status.
- **Agent Verification Record**: A bounded evidence entry for a real Codex or Claude run. Includes agent name, version, environment, prompt boundary, operations exercised, output location, result, and any limitations.
- **Readiness Report**: The user-facing diagnostic/status output that confirms install health, namespace alignment, script flavor, dependencies, active bridge state, and recommended next step.
- **Release Artifact**: The packaged extension ZIP and stable alias asset intended for end users. It must contain both script flavors and metadata needed for marketplace installation.
- **Catalog Submission Package**: The files and issue/PR body used to update the Spec Kit community catalog after release. It mirrors the shipped version and stable download policy.
- **Demo Evidence**: GIF, recording, or transcript material used in README/release notes. For 1.0.0 it must be either generated from real verification or labelled as illustrative.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of version-bearing release files report `1.0.0` where expected, and release readiness fails if any version-bearing file remains at a previous bridge version.
- **SC-002**: The namespace validator catches all tested mismatches across extension id, command names, hook command names, and catalog id before release packaging.
- **SC-003**: Linux/bash validation completes with the full smoke suite passing and an install-style sandbox bridge cycle recorded.
- **SC-004**: Windows PowerShell 5.1+ validation completes with package install and the core PowerShell bridge operations recorded as passing.
- **SC-005**: Real Codex verification and real Claude verification each produce a pass/fail evidence row. A release announcement may only claim an agent as verified when its row is passed.
- **SC-006**: The packaged ZIP contains both bash and PowerShell script flavors, portable archive paths, and the root manifest; package inspection has zero missing required entries.
- **SC-007**: The release workflow no longer references nonexistent test files and has a documented route for both Linux and Windows gates.
- **SC-008**: The readiness/status surface identifies at least five actionable categories: script flavor, required tools, namespace/package integrity, active bridge state, and next recommended action.
- **SC-009**: README.md and README.zh-CN.md contain equivalent 1.0.0 support and positioning information, with no contradictory platform or install claims.
- **SC-010**: The release runbook allows a maintainer to reproduce the release gate sequence from a clean checkout without relying on undocumented tribal knowledge.
- **SC-011**: Demo/release evidence is truthful: every GIF, transcript, or screenshot is either tied to a real run or explicitly labelled illustrative.
- **SC-012**: The final diff contains zero edits to vendor-managed generated Spec Kit skills and zero new heavy runtime/state-machine components.
- **SC-013**: Existing 0.7.2 behavior remains compatible: current bash smoke tests still pass and existing handoff schema reads remain tolerated.
- **SC-014**: The release evidence includes a SHA256 for the packaged artifact used in sandbox verification and the artifact referenced by the release notes.
- **SC-015**: No completion report marks 1.0.0 ready while any mandatory platform, package, release workflow, or real-agent verification row is failed or missing.

## Assumptions

- The accepted scope is the recommended "方案 B: stable protocol release" from the research phase. It includes lightweight readiness/doctor capability but excludes a feature-rich workflow platform.
- The release may expand existing scripts, validators, tests, docs, and evidence files. It should prefer extending existing `bridge-status`/release-readiness surfaces over adding a new Spec Kit extension command.
- Windows PowerShell 5.1+ and Linux bash are the minimum first-class platform targets. WSL bash is useful Linux evidence but not a Windows substitute.
- macOS bash compatibility is desirable because the bash flavor is portable, but it is not the explicit hard gate for this user request unless later added.
- Current verified local tool versions observed during research are Spec Kit 0.9.3, Superpowers 5.1.0, Codex CLI 0.137.0, and Claude Code 2.1.162. These should be refreshed if they change before tagging.
- The sibling sandbox `../test_specify_superpower` is allowed for destructive reset or generated output during verification, but its transient files are not part of this source repo's committed product.
- If `vhs`, `ttyd`, or other GIF tooling is missing, truthful transcript evidence is acceptable for spec completion; regenerated GIFs require the tooling to be installed and a real capture path to be available.
- The upstream Spec Kit catalog may lag the source release. Preparing correct catalog submission artifacts is in scope; upstream merge timing is outside this repo's direct control.
- The release should preserve the existing bridge runtime floor unless implementation planning identifies a concrete, user-facing reason to raise it.
