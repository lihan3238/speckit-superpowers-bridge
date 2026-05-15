# Specification Quality Checklist: Bridge Cross-Platform Scripts

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-05-15
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Spec is intentionally explicit about WHAT changes (bash scripts added, validator extended, .gitattributes added) but stays out of HOW (no `jq` query strings, no specific bash patterns, no shebang variations). The Plan phase will commit those.
- "Implementation details" check: the spec names `jq` and `bash >= 4.0` as **user-facing prerequisites**. That's user-value, not implementation detail (the user has to install jq to use the bridge). The choice between `jq` and pure-bash JSON parsing IS in scope for the spec because it dictates the user prereq, not just the script's internal mechanism.
- "Technology-agnostic SC" check: SC values use concrete OS names (Ubuntu, macOS, Windows) and tool versions (`pwsh` 7.x). These are environment specifications, not technology choices — a user reading SC needs to know which OS the criterion targets. Acceptable per "user-focused" framing.
- Spec is "only compat" — no new features added. All FRs are about adding parallel implementations of existing surfaces or extending existing tooling (validator, build script) to cover both flavors. No new bridge commands. No new tests. No new schemas.

## Sanity flags surfaced during drafting (for clarify or plan attention)

All 5 flags resolved in the 2026-05-15 clarify session (see spec `## Clarifications`):

1. ~~**Spec Kit's `script: ps|sh` mechanism**~~ — RESOLVED: Spec Kit's existing `init-options.json.script` field (verified in `.specify/init-options.json`, v0.8.10) handles dispatch. No bridge changes needed. FR-016 unchanged.
2. ~~**`extension.yml.requires.tools` schema for per-platform requirements**~~ — RESOLVED: flat list with `required: true|false` per tool, matching `agent-governance` + `azure-devops` live catalog entries. FR-010 refined with concrete tool list (PowerShell required; bash/jq/git/pwsh optional).
3. ~~**`Compress-Archive` line endings**~~ — RESOLVED: `.gitattributes` enforces `*.sh text eol=lf`. Scripts invoked via `bash <path>` (NOT `./path`), bypassing the Unix-executable-bit problem entirely (ZIP format doesn't carry Unix perms anyway). Same convention as `.specify/extensions/git/scripts/bash/`. FR-020 refined with exact `.gitattributes` content.
4. ~~**`bridge-events.jsonl` append concurrency**~~ — RESOLVED: NO `flock`. PowerShell scripts don't use locking either; adding it to bash would violate "只做兼容，不增新功能". Edge case remains documented in spec Edge Cases section.
5. ~~**Test dispatch for both flavors**~~ — RESOLVED: tests auto-detect available flavors via a small helper that inspects `scripts/powershell/` and `scripts/bash/`, then exercises every flavor present. No `-Flavor` parameter; no env knob. FR-014, FR-015 refined.
