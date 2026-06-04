# Phase 0 Research: v1.0.0 Stable Protocol Release Hardening

## Decision: Ship 1.0.0 as a stable protocol release, not a workflow rewrite

**Rationale**: The bridge's strongest differentiator is that it remains small and delegates native work to Spec Kit, Superpowers, Codex, and Claude Code. Community alternatives show that richer workflows can be useful, but they also carry larger state surfaces and higher namespace/install risk. A 1.0.0 release should communicate stability, compatibility, evidence, and support boundaries.

**Alternatives considered**:

- Compatibility-only release: safest but too little visible improvement for a major version.
- Feature-rich workflow platform: more competitive checklist surface, but duplicates upstream tools and violates the native-first principle.
- Recommended middle path: add release gates, readiness evidence, cross-platform verification, docs, and truthful demos while preserving the existing bridge runtime model.

## Decision: Keep readiness lightweight and prefer extending existing status/release validators

**Rationale**: The repository already has `bridge-status` scripts and release readiness tooling. A small readiness/doctor-style surface can inspect package integrity, namespace alignment, local tools, active bridge state, and next action without owning state. This gives users the Comet-style "where am I and is this healthy?" benefit without adding a new lifecycle manager.

**Alternatives considered**:

- Add a new `speckit.*.doctor` extension command: more discoverable but expands public command surface.
- Add a separate state file for diagnostics: rejected because it creates another source of truth.
- Extend existing read-only status and release-readiness checks: preferred because it is smaller and testable.

## Decision: Make Windows PowerShell and Linux bash independent release gates

**Rationale**: The user explicitly requires Windows and Linux compatibility. Existing WSL bash validation is useful but cannot prove native Windows PowerShell behavior, especially around encoding, line endings, script dispatch, and shell availability. 1.0.0 must record both platform rows.

**Alternatives considered**:

- Treat WSL as both Linux and Windows evidence: rejected because WSL uses Linux shell behavior.
- Test only GitHub Actions Windows: useful but insufficient for end-user sandbox evidence unless paired with package-install checks.
- Require native Windows PowerShell 5.1+ plus Linux bash rows: preferred for a first-class support claim.

## Decision: Add namespace and catalog alignment as release readiness blockers

**Rationale**: Superspec's 1.0.0 install failure was caused by catalog id and command namespace drift. This bridge should fail before release when `extension.id`, catalog id, command names, or hook command references diverge.

**Alternatives considered**:

- Rely on upstream catalog validation: too late in the release process.
- Manually review namespace strings: error-prone.
- Add deterministic release-readiness checks: preferred.

## Decision: Align the release workflow with actual tests and add Windows release smoke coverage

**Rationale**: The current release workflow still references removed `tests/*.ps1` files. A 1.0.0 release cannot trust a workflow that checks a nonexistent test inventory. The workflow should run current bash smoke tests on Linux and Windows-specific release smoke checks on Windows, or document an approved manual Windows gate if CI permissions block workflow edits.

**Alternatives considered**:

- Leave workflow as-is and rely on manual release: rejected for 1.0.0 trust.
- Port the entire bash suite back to PowerShell immediately: possible but larger than necessary.
- Add focused PowerShell smoke coverage for release-critical scripts: preferred.

## Decision: Verify real Codex and Claude in the sibling sandbox with bounded prompts

**Rationale**: Script tests validate file behavior, but the bridge promises agent-neutral use. Bounded real-agent verification catches instruction loading, skill discovery, command syntax, and headless/noninteractive constraints. The sandbox keeps this evidence outside the source repo's working tree.

**Alternatives considered**:

- Skip real agents and rely on smoke tests: insufficient for cross-agent claim.
- Let agents perform open-ended implementation: too costly and unpredictable for release evidence.
- Use bounded verification prompts that exercise status, guard, handoff, and package install surfaces: preferred.

## Decision: Treat demo GIF regeneration as evidence-dependent

**Rationale**: Existing demo tapes are illustrative shell scripts. 1.0.0 should not present fake shell output as real agent behavior. If GIF tooling and real capture are available, demos should be refreshed from a sandbox transcript. If not, transcript evidence is acceptable and more honest than a polished fake GIF.

**Alternatives considered**:

- Keep current fake demos unchanged: misleading for a stable release.
- Block release on GIF tooling: unnecessary because compatibility matters more than marketing assets.
- Prefer real capture, fall back to clearly labelled transcript: preferred.

## Decision: Preserve the existing runtime compatibility floor unless a concrete break appears

**Rationale**: The current bridge runtime floor is broader than the latest verified bootstrap tooling. Raising it would reduce upgrade compatibility and should only happen if a planned check or script actually requires newer Spec Kit behavior.

**Alternatives considered**:

- Raise runtime floor to current Spec Kit 0.9.3: simpler messaging but unnecessarily restrictive.
- Keep current floor and separately publish verified version evidence: preferred.

## Decision: Record release evidence as feature-local documentation plus package metadata

**Rationale**: Release evidence belongs with the feature that ships it. Runtime bridge users should not inherit release-process state. The artifact hash, platform matrix, agent runs, and blockers should live in `verification.md` or `quickstart.md` and in `verified-versions.json` where appropriate.

**Alternatives considered**:

- Add a new `.specify/release-state.json`: rejected as unnecessary state.
- Put all evidence only in CHANGELOG: too little structure for release gates.
- Use feature-local verification plus packaged `verified-versions.json`: preferred.
