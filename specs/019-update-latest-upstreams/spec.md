# Feature Specification: Latest Upstream Alignment and Release

**Feature Branch**: `019-update-latest-upstreams`

**Created**: 2026-09-26

**Status**: Draft

**Input**: User description: "更新 speckit 和 superpowers，针对最新版本，更新我们的桥接插件并发布一个版本。"

## User Scenarios & Testing

### User Story 1 - Use the latest Spec Kit baseline (Priority: P1)

As a bridge maintainer, I want the repository's tracked Spec Kit sources and development CLI baseline to match the latest stable Spec Kit release so that new projects receive current templates, extensions, and command behavior.

**Why this priority**: A stale design-time baseline is the main source of install drift and prevents the bridge from supporting current Spec Kit projects.

**Independent Test**: A clean checkout can bootstrap with the recorded Spec Kit version, reports the expected extension source versions, and keeps all bridge-owned files and protocol gates intact.

**Acceptance Scenarios**:

1. **Given** a clean checkout and the supported WSL environment, **When** the maintainer runs the documented Spec Kit bootstrap, **Then** the CLI reports the target release and the generated integration state is current without modifying bridge-owned source files.
2. **Given** current Spec Kit implement hook guidance, **When** the bridge dispatches hooks from a malformed or missing extension registry, **Then** it follows the current upstream reporting and skip behavior while preserving mandatory hook execution and failure handling.

### User Story 2 - Use the latest Superpowers skill contract (Priority: P1)

As a bridge maintainer, I want the bridge's invoked Superpowers skills and documentation audited against the latest stable Superpowers release so that implementation execution remains valid and predictable.

**Why this priority**: The bridge delegates implementation discipline to Superpowers; a changed execution skill contract can otherwise make the bridge silently behave differently.

**Independent Test**: A recorded audit proves every invoked skill exists in the target release, documents any execution-semantics change, and the bridge's chosen orchestration remains consistent with the Spec Kit tasks contract.

**Acceptance Scenarios**:

1. **Given** the latest Superpowers release, **When** the bridge resolves its execution, verification, review, and finishing skills, **Then** all referenced skill identifiers exist and the selected execution mode is explicitly documented.
2. **Given** a Spec Kit tasks.md with ordered tasks, **When** the bridge invokes the selected Superpowers execution skill, **Then** it consumes tasks.md directly and does not create a competing planning artifact.

### User Story 3 - Publish a verified compatible bridge release (Priority: P1)

As an end user, I want a new bridge release with accurate compatibility metadata and a public ZIP so that I can install it from the stable release URL and run a complete bridge cycle.

**Why this priority**: The upgrade has no value until users can install and verify the resulting artifact.

**Independent Test**: The release readiness validator, bash and PowerShell gates, deterministic package check, and the canonical sibling sandbox all pass for the new version.

**Acceptance Scenarios**:

1. **Given** a versioned release commit, **When** the release gates run, **Then** all required metadata agrees on the version and the package contains only the intended extension surface.
2. **Given** the published versioned and stable-alias ZIPs, **When** a fresh Linux sandbox installs the artifact and drives guard, handoff, status, and completion operations, **Then** the cycle succeeds with no artifact drift and the recorded compatibility versions match the release evidence.

### Edge Cases

- The upstream Spec Kit extension registry is missing or malformed; hook handling must report the condition according to the current upstream contract and must not execute an unresolvable mandatory hook.
- Superpowers changes the behavior of a referenced skill while retaining its identifier; the release must document the selected mode and preserve the tasks.md ownership boundary.
- A bootstrap or package operation would overwrite the project-owned bridge extension or its short skill peers; the refresh must restore and verify those project-owned files.
- A supported platform gate is unavailable locally; the verification record must label that platform as hosted, deferred, or blocked rather than claiming a local pass.
- Existing terminal handoff state from the preceding feature is present; starting this feature must archive it before new handoff state is created.

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST record and use the latest stable Spec Kit release available at implementation time, including its CLI version, tracked bundled extension source versions, and generated command contract.
- **FR-002**: The bridge MUST remain compatible with the latest stable Superpowers release available at implementation time, and the repository MUST record the audited commit and every invoked skill identifier.
- **FR-002a**: Because Superpowers 6.4.2 requires heading-based task plans while Spec Kit uses checkbox task IDs, the bridge MUST derive an ephemeral adapter plan with `Task N` headings from the canonical `tasks.md`, invoke native Superpowers against that adapter, and keep `tasks.md` as the sole requirements source.
- **FR-003**: The bridge's hook documentation and implementation contract MUST match the current Spec Kit behavior for missing or malformed extension registries, mandatory and optional hooks, command rendering, waiting, and failure transitions.
- **FR-004**: The refresh MUST preserve the existing bridge protocol: three bridge commands, five registered bridge hooks, handoff v1 fields and transitions, actor semantics, guard rules, stable-alias download URL, and runtime floor `>=0.8.10`, unless the audit proves a required compatibility change.
- **FR-005**: The repository MUST keep the Codex and Claude bridge skill peers behaviorally identical after the refresh, aside from their documented invocation syntax.
- **FR-006**: Release metadata MUST use one new semantic version consistently across the extension manifest, marketplace entry, changelog, verified-versions evidence, README files, marketplace support documents, and release submission body.
- **FR-007**: The release MUST pass the applicable bash, PowerShell, package, readiness, and end-user sandbox checks before the handoff reaches `complete`.
- **FR-008**: The implementation MUST NOT add a parallel hook runner, new bridge state file, new handoff schema field, or new command solely to accommodate upstream changes.

## Success Criteria

- **SC-001**: A fresh bootstrap reports the target Spec Kit version and produces zero unexpected changes to project-owned bridge protocol files.
- **SC-002**: 100% of bridge-invoked Superpowers skill identifiers resolve in the audited target release, with the execution-mode choice documented in the feature verification record.
- **SC-003**: The full bash smoke suite, native PowerShell release gate, release readiness validator, deterministic package check, and available sandbox cycles pass for the release candidate.
- **SC-004**: The published versioned ZIP and stable-alias ZIP are reachable, byte-identical to the validated artifacts, and install successfully in the canonical sandbox.
- **SC-005**: Review of the final diff finds no change to the handoff schema, guard rule count, command count, hook count, or runtime floor unless explicitly justified by an upstream incompatibility.

## Assumptions

- “Latest” means the latest stable official releases available on 2026-09-26: Spec Kit v1.0.12 and Superpowers v6.4.2.
- The bridge remains a thin integration layer; upstream functionality is preferred over new bridge mechanisms.
- The release version will be selected after the compatibility diff is complete and will be applied consistently to all required release metadata.
- Native Windows and macOS hosts may be unavailable in this session; unavailable evidence will be run by the release workflow or labeled honestly in verification artifacts.
- The existing sibling sandbox `../test_specify_superpower` remains the canonical end-user verification location.
