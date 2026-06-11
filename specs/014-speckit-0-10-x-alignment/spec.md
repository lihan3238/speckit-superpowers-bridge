# Feature Specification: Spec Kit 0.10.x Compatibility Alignment & Evidence Refresh

**Feature Branch**: `014-speckit-0-10-x-alignment`

**Created**: 2026-06-12

**Status**: Draft

**Input**: User description: "Spec Kit 0.10.x compatibility alignment and evidence refresh. The development environment was upgraded from Spec Kit CLI 0.9.3 to 0.10.2 and the repo re-bootstrapped; all 6 bridge smoke tests pass unchanged, so this is drift alignment, not breakage repair."

## Context

Upstream Spec Kit shipped 0.9.4 → 0.10.2 between 2026-06-04 and 2026-06-11. The
bridge's verified baseline (`verified-versions.json`, README badge) still says
Spec Kit 0.9.3. The local dev environment has been upgraded to CLI 0.10.2 and
the repo re-bootstrapped (`specify init --here --integration claude --script sh
--force`); the full bash smoke suite (6/6) passes unchanged, confirming the
bridge runtime is compatible. What remains is documentation drift, metadata
drift, and stale verification evidence:

- **0.10.0 breaking changes (init-time only, not runtime)**: the git extension
  is now opt-in (`--no-git` removed; `specify init` no longer auto-installs it)
  and legacy `--ai` / `--ai-skills` / `--ai-commands-dir` flags were removed in
  favor of `--integration`. `init-options.json` renamed `branch_numbering` →
  `feature_numbering` (the git extension's branch script reads its own
  `git-config.yml` first, so branch numbering is unaffected).
- **0.10.2 schema addition (backward-compatible)**: `category` and `effect` are
  now first-class optional fields in the extension schema. Upstream's
  `catalog.community.json` already carries `category: process` /
  `effect: read-write` for the bridge entry, but the bridge's own
  `extension.yml` and `marketplace/catalog-entry.json` do not declare them.
  Older validators (>=0.8.10 runtime floor) ignore unknown manifest fields, so
  declaring them is safe.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh-clone contributor bootstraps with Spec Kit 0.10.x (Priority: P1)

A new contributor clones the source repo with Spec Kit CLI 0.10.x installed,
follows AGENTS.md's supported-environments table, and reaches a working dev
environment — including the git extension that 0.10.0 stopped auto-installing —
without hitting removed flags or stale version floors.

**Why this priority**: AGENTS.md is the canonical contributor contract; a
bootstrap command that silently skips the git extension breaks every
`/speckit-specify` run (its `before_specify` hook depends on the git
extension).

**Independent Test**: In a scratch clone with CLI 0.10.2, run the documented
bootstrap sequence verbatim; confirm `specify extension list` shows git,
agent-context, and the bridge, and that a feature branch can be created.

**Acceptance Scenarios**:

1. **Given** a fresh clone and Spec Kit CLI 0.10.2, **When** the contributor follows the AGENTS.md bootstrap table, **Then** every documented command exists in 0.10.x (no removed flags) and the git extension ends up installed.
2. **Given** the updated AGENTS.md, **When** a reader checks the CLI version floor, **Then** it names 0.10.x for repo bootstrap while the bridge runtime floor remains `>=0.8.10`.

---

### User Story 2 - Marketplace consumer sees accurate, current metadata (Priority: P2)

A Spec Kit user browsing `specify extension info speckit-superpowers-bridge`
or the community catalog sees the bridge's `category`/`effect` declared by the
bridge itself (not just patched in by upstream catalog maintainers), and a
verified-versions baseline that names the Spec Kit version the bridge was
actually verified against.

**Why this priority**: Stale "verified 0.9.3" claims erode trust as upstream
moves to 0.10.x; the catalog `category`/`effect` values should originate from
the bridge manifest so future catalog syncs don't regress them.

**Independent Test**: Validate the updated `extension.yml` with Spec Kit
0.10.2 (`specify extension add` from a local copy in a scratch project) and
confirm `category: process` / `effect: read-write` round-trip; confirm the
README badge and `verified-versions.json` name 0.10.2.

**Acceptance Scenarios**:

1. **Given** the updated manifest, **When** it is validated by Spec Kit 0.10.2, **Then** validation passes and `extension info` shows Category: process, Effect: read-write.
2. **Given** the updated manifest, **When** it is installed under the oldest supported runtime floor semantics (unknown-field-tolerant validators >=0.8.10), **Then** installation still succeeds.
3. **Given** `verified-versions.json`, **When** a user reads the baseline, **Then** it records Spec Kit 0.10.2 evidence rows for Linux bash, plus the existing platform/agent rows updated or re-confirmed.

---

### User Story 3 - End user installs v1.0.3 from the published release (Priority: P2)

An end user installs the bridge v1.0.3 in a fresh Spec Kit 0.10.x project via
the published release URL and drives one full bridge cycle (guard → handoff →
status → archive) on a supported platform.

**Why this priority**: Constitution §"End-User Verification Sandbox" makes
sandbox verification a release gate; this is what converts "smoke tests pass"
into a publishable compatibility claim.

**Independent Test**: In `../test_specify_superpower`, `specify init` a fresh
0.10.2 project, `specify extension add` the v1.0.3 ZIP from the release URL,
and complete one bridge cycle; record outcomes in the feature's
verification doc.

**Acceptance Scenarios**:

1. **Given** a fresh Spec Kit 0.10.2 sandbox project, **When** the user installs v1.0.3 from the published release URL, **Then** install succeeds and `specify extension list` shows the bridge enabled with 3 commands / 5 hooks.
2. **Given** the installed bridge, **When** the user drives guard/handoff/status/archive, **Then** all commands behave per the v1 protocol with no changes from v1.0.2.

---

### Edge Cases

- A consumer on Spec Kit 0.8.10–0.9.x installs v1.0.3: the new manifest fields must not break older validators (they ignore unknown keys; verified against 0.8.10 validator source).
- A consumer's existing `.specify/init-options.json` still says `branch_numbering`: Spec Kit 0.10.x treats it as deprecated-but-honored; bridge scripts never read this field, so no bridge behavior changes.
- Upstream catalog re-sync overwrites the bridge entry: with `category`/`effect` now in the manifest, a future catalog regeneration sources them from the bridge rather than hand-edits.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: AGENTS.md supported-environments table MUST name Spec Kit CLI 0.10.x as the repo-bootstrap floor and document the post-0.10.0 bootstrap sequence including explicit `specify extension add git` for fresh clones (the bridge runtime floor stays `>=0.8.10`).
- **FR-002**: AGENTS.md MUST note the 0.10.0 flag removals (`--ai`, `--ai-skills`, `--ai-commands-dir`, `--no-git`) wherever those flags are currently mentioned or implied, and the `branch_numbering` → `feature_numbering` rename in `init-options.json`.
- **FR-003**: The bridge `extension.yml` MUST declare `category: process` and `effect: read-write`, matching upstream's catalog entry, and `marketplace/catalog-entry.json` MUST carry the same two fields.
- **FR-004**: `verified-versions.json` MUST be refreshed with Spec Kit 0.10.2 evidence (CLI version, platforms, agents actually re-verified) without dropping required evidence rows; claims not re-verified MUST NOT be advertised.
- **FR-005**: README (EN + zh-CN) version badges and "verified" claims MUST be updated from 0.9.3 to the re-verified Spec Kit version.
- **FR-006**: The release MUST ship as patch v1.0.3 (version bump in `extension.yml`, `marketplace/catalog-entry.json` version field, CHANGELOG entry) with `download_url` unchanged (stable latest-release alias policy from v0.6.0).
- **FR-007**: Release validators and the full smoke suite MUST pass on the release commit; end-user sandbox verification per constitution MUST be recorded before the handoff transitions to `complete`.

### Out of Scope

- Any new bridge surface: no new commands, hooks, scripts, state files, or conventions (constitution VI Native-First gate: this feature only aligns existing surface).
- Protocol/schema changes: handoff v1 schema, guard rules, actor semantics, and `[bridge state]` output are untouched.
- Adopting 0.10.x per-event hook lists / hook priorities in `extension.yml` (current single-mapping form remains valid; adopting lists adds surface without need).
- Raising the bridge runtime floor above `>=0.8.10`.
- Changing `marketplace/catalog-entry.json.download_url` away from the stable alias.

### Assumptions

- Upstream's assigned `category: process` / `effect: read-write` are correct for the bridge (it orchestrates process and writes state files).
- Windows PowerShell evidence from v1.0.0/v1.0.2 remains valid for the unchanged script flavor; re-running native Windows verification is required only if the release claims new Windows evidence (existing rows are retained with their original verification dates, clearly dated).
- The 006-era stale handoff has already been completed and archived (done 2026-06-12 prior to this spec).

## Success Criteria *(mandatory)*

- **SC-001**: A fresh clone following AGENTS.md with Spec Kit CLI 0.10.2 reaches a working dev environment (all three extensions installed, feature branch creatable) with zero undocumented manual steps.
- **SC-002**: `specify extension info speckit-superpowers-bridge` on 0.10.2 displays Category and Effect sourced from the bridge's own manifest.
- **SC-003**: All 6 bash smoke tests and the release validators pass on the v1.0.3 release commit.
- **SC-004**: End-user sandbox verification of v1.0.3 on Spec Kit 0.10.2 (Linux bash, real install from published release URL) is recorded in the feature's verification doc before handoff `complete`.
- **SC-005**: No occurrence of "0.9.1+", "0.9.3", or removed-flag references remains in AGENTS.md, README.md, or README.zh-CN.md where a current-version claim is intended (historical CHANGELOG entries are exempt).
