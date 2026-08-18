# Feature Specification: v1.2.0 Release Hardening and Upstream Alignment

**Feature Branch**: `018-release-0-16-4-hardening`

**Created**: 2026-08-18

**Status**: Draft

**Input**: User description: "Review and merge the pending PR if sound, inspect open issues and solve compatible ones, update all Spec Kit-related project state to the latest release, audit details that need adjustment, and publish a new bridge version."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - macOS users can create bridge handoffs (Priority: P1)

A macOS user installs the bridge and runs the normal Spec Kit task-to-implementation flow. The mandatory handoff hook completes with the platform's standard tools, so the bridge creates its state file instead of silently becoming inert.

**Why this priority**: Issue #13 makes the core bridge non-functional on a supported platform. No later release work is meaningful until handoff creation works there.

**Independent Test**: Run the bash handoff script in an environment whose `realpath` rejects GNU-only options, using both existing and not-yet-created feature paths. Confirm the handoff file, snapshots, project-relative artifact paths, and bridge-state output are correct.

**Acceptance Scenarios**:

1. **Given** a macOS-style `realpath` implementation without `-m`, **When** the handoff script creates or updates a handoff, **Then** it succeeds without requiring GNU coreutils or another new runtime dependency.
2. **Given** a feature path containing `.` or `..` segments and paths that do not yet exist, **When** the handoff is written, **Then** stored project-relative paths are normalized consistently and required-artifact detection remains correct.
3. **Given** an absolute feature path outside the repository, **When** the handoff is written, **Then** the path remains absolute rather than being misreported as repository-relative.

---

### User Story 2 - Implement hooks match current Spec Kit behavior (Priority: P1)

A project that uses the bridge instead of `speckit.implement` keeps its enabled `before_implement` and `after_implement` extension hooks. Mandatory hooks are visibly dispatched and actually executed according to current Spec Kit semantics, optional hooks remain user-controlled, and the bridge never invokes its own blocking guard as an implement hook.

**Why this priority**: PR #14 fixes a real plug-and-play gap, but the release must reflect current Spec Kit behavior rather than the older baseline used when the contribution was authored.

**Independent Test**: Install the release candidate in a clean project with synthetic mandatory, optional, disabled, conditional, and bridge-owned implement hooks. Drive a bridge cycle and verify dispatch, ordering, failure behavior, and handoff state.

**Acceptance Scenarios**:

1. **Given** an enabled mandatory implement hook, **When** the bridge reaches that lifecycle point, **Then** it emits the current automatic-hook directive, invokes the hook in the active agent, waits for completion, and does not merely print instructions.
2. **Given** an optional implement hook, **When** the lifecycle point is reached, **Then** the user sees its prompt and the hook runs only after confirmation.
3. **Given** a disabled hook, a hook with a non-empty condition, or a bridge-owned hook, **When** dispatch is evaluated, **Then** the hook is skipped for the documented reason.
4. **Given** a mandatory post-implementation hook failure, **When** execution ends, **Then** the bridge does not leave a misleading successful completion state.

---

### User Story 3 - Maintainers can publish against current upstreams (Priority: P2)

A maintainer can reproduce a v1.2.0 release whose tracked Spec Kit templates, generated-state policy, compatibility claims, package metadata, and verification evidence agree with the latest audited Spec Kit and Superpowers releases.

**Why this priority**: The repository currently advertises older upstream baselines and contains local initialization drift. Publishing without reconciling those details would create stale or contradictory guidance.

**Independent Test**: Starting from a clean checkout, follow the updated contributor bootstrap and release guide, run the complete test suite and release validators, install the published artifact in the canonical sandbox on supported local platforms, and confirm the advertised versions and behavior.

**Acceptance Scenarios**:

1. **Given** Spec Kit `0.16.4`, **When** the repository is initialized and its bundled extensions are refreshed, **Then** tracked upstream-owned templates and ignore rules match the latest supported structure while project-owned gates and bridge skills remain intact.
2. **Given** Superpowers `6.3.0`, **When** the bridge's invoked skill names and task-consumption contract are audited, **Then** only evidence-backed compatibility claims are published.
3. **Given** all release files and tests are ready, **When** v1.2.0 is tagged and published, **Then** the release asset installs from its public URL, has deterministic package contents, and the relevant PR and issue are traceably resolved.

### Edge Cases

- The repository already contains uncommitted Spec Kit-generated changes when the feature branch is created; those changes must be classified and preserved or deliberately superseded.
- `specify init --force` may overwrite the project-owned short bridge skill because its alias collides with a generated extension skill; the release must restore and verify both project-owned peers.
- Spec Kit bundled extensions may retain an old installed copy when only `init` is rerun; they require an explicit safe refresh without installing the bridge source from its own destination directory.
- A mandatory pre-hook fails before the handoff transitions to `executing`; implementation must not start.
- A release tag workflow fails after the tag exists; the documented tag repair procedure must remain usable.
- Native macOS hardware may not be locally available; a macOS-hosted CI run and a BSD-compatible regression harness must provide evidence without claiming a local sandbox run that did not occur.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bash handoff implementation MUST normalize existing and missing paths without invoking GNU-only `realpath` options and without adding a new bridge runtime dependency.
- **FR-002**: Path normalization MUST preserve the existing project-relative versus absolute-path contract, required-artifact checks, snapshot source selection, and artifact-hash behavior.
- **FR-003**: Automated regression coverage MUST fail if GNU-only path handling is reintroduced and MUST exercise macOS-compatible handoff creation with missing path components.
- **FR-004**: The bridge execute command and both project-owned agent skill peers MUST dispatch implement hooks using the semantics documented by Spec Kit `0.16.4`, including enabled/condition filtering, optional prompts, mandatory automatic-hook directives, actual invocation, and wait-for-result behavior.
- **FR-005**: Implement-hook dispatch MUST skip bridge-owned hooks so the bridge cannot invoke its own `before_implement` guard and block itself.
- **FR-006**: The lifecycle ordering MUST prevent a failed mandatory pre-hook from starting implementation and a failed mandatory post-hook from being represented as a successful bridge completion.
- **FR-007**: The repository's Spec Kit CLI, generated install state, tracked templates, ignore rules, bundled git and agent-context sources, and contributor guidance MUST be audited and aligned with Spec Kit `0.16.4`, while project-owned template gates and bridge skills remain authoritative.
- **FR-008**: The Spec Kit `0.11.1` through `0.16.4` change range MUST be reviewed for bridge-relevant changes, and the resulting documentation MUST distinguish adopted changes, transparent upstream fixes, deprecations, and intentionally unchanged bridge contracts.
- **FR-009**: Superpowers `6.3.0` MUST be audited for every skill name and execution contract the bridge invokes before the verified baseline is advanced from `6.0.0`.
- **FR-010**: Release metadata and documentation MUST consistently identify bridge version `1.2.0`, Spec Kit `0.16.4`, and only verified agent/platform versions; the stable-alias download URL and `>=0.8.10` runtime floor MUST remain unchanged unless evidence requires otherwise.
- **FR-011**: The full smoke suite, release validators, package checks, shell lint where available, Windows PowerShell coverage, Linux bash coverage, and macOS-hosted regression coverage MUST pass before publication.
- **FR-012**: The published v1.2.0 artifact MUST be installed from the public release URL in the canonical sibling sandbox and complete a bridge cycle on locally available supported platforms before the handoff is marked complete.
- **FR-013**: Release notes and verification evidence MUST record the macOS limitation fix, implement-hook semantics, upstream version audits, exact asset digest, platform results, and any honestly deferred platform evidence.
- **FR-014**: After publication, PR #14 MUST remain linked as the accepted contribution and Issue #13 MUST be closed with the released fix and verification reference.

### Key Entities

- **Normalized path**: The canonical absolute or repository-relative representation used for feature directories, Spec Kit artifacts, and snapshot sources, including paths whose final components do not yet exist.
- **Implement hook dispatch**: The ordered evaluation and invocation of `before_implement` or `after_implement` entries, including ownership, enabled state, condition presence, optionality, prompt, directive, and result.
- **Compatibility evidence**: A dated record tying bridge version, upstream version, platform or agent, test method, result, and evidence location to a published support claim.
- **Release artifact**: The deterministic v1.2.0 extension archive distributed through the public GitHub release URL and stable latest-release alias.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The handoff regression suite passes with a `realpath` substitute that rejects `-m`, and the bash implementation contains zero invocations of `realpath -m`.
- **SC-002**: All implement-hook contract and behavior tests pass for mandatory, optional, disabled, conditional, bridge-owned, successful, and failing hooks.
- **SC-003**: Every tracked release checklist file reports `1.2.0`, the verified Spec Kit baseline reports `0.16.4`, and the verified Superpowers baseline reports `6.3.0` only if its audit passes.
- **SC-004**: The complete repository smoke suite and release-readiness validation finish with zero failures on the release commit.
- **SC-005**: Linux bash and native Windows PowerShell release-sandbox rows pass against the published v1.2.0 asset; macOS receives a passing hosted regression row or is explicitly marked deferred without being advertised as locally sandbox-verified.
- **SC-006**: The public v1.2.0 release contains one installable extension archive whose recorded SHA256 matches the downloaded asset.
- **SC-007**: Issue #13 is closed with a link to v1.2.0 and its verification evidence, and no open issue remains that is both release-blocking and within this feature's stated scope.

## Assumptions

- PR #14's user-visible hook-dispatch behavior is part of v1.2.0 and will be hardened rather than reverted.
- Spec Kit `0.16.4` and Superpowers `6.3.0` are the latest stable upstream releases as of 2026-08-18.
- The bridge runtime floor remains `>=0.8.10` because the new release composes optional hook behavior and portability fixes without requiring a newer Spec Kit runtime; this claim will be rechecked during planning.
- The local workstation provides WSL2 Linux and native Windows PowerShell, but not native macOS hardware.
- The existing GitHub release workflow and community-catalog submission process remain the publication mechanisms.

## Out of Scope

- Adding new bridge commands, hooks, state fields, guard rules, or a custom hook runner.
- Replacing Spec Kit's instruction-driven hook mechanism with a bridge-owned workflow engine.
- Raising the minimum Spec Kit runtime solely to match the development verification baseline.
- Solving unrelated upstream Spec Kit, Superpowers, Codex, or Claude Code defects.
- Claiming native macOS end-user sandbox evidence without a real macOS execution environment.
