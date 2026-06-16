# Feature Specification: Superpowers 6.0.0 Compatibility Alignment & Evidence Refresh

**Feature Branch**: `016-superpowers-6-0-0-alignment`

**Created**: 2026-06-17

**Status**: Draft

**Input**: User description: "Superpowers updated to 6.0.0 (a major release). Verify the current environment is also on the latest, carefully analyze the major changes, and ship a real update to our plugin — while preserving the current fable-5-optimized thin-bridge framework. Do not turn it into a lazy incremental badge bump."

## Context

Upstream Superpowers shipped a **major** release, v5.1.0 → v6.0.0 (2026-06-16),
now installed and live in this environment
(`~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.0`, plugin
manifest `version: 6.0.0`, git sha `f2cbfbef`). The bridge's verified baseline
(`verified-versions.json`, README badges, marketplace material) still names
Superpowers **5.1.0**.

A direct source-tree diff of the cached 5.1.0 and 6.0.0 plugins (see
`research.md`) shows the major bump's breaking and headline changes are **all
internal to upstream skills**, and the thin bridge is transparent to every one
of them:

- **`subagent-driven-development` rewrite** — the two per-task reviewer prompts
  (`spec-reviewer-prompt.md` + `code-quality-reviewer-prompt.md`) were
  consolidated into one `task-reviewer-prompt.md`, with new `task-brief` /
  `review-package` helper scripts and a single whole-branch final review. These
  are files *internal* to the skill, dispatched via relative paths by the skill
  itself. The bridge invokes the **skill by name** and never references the
  prompt filenames → transparent (grep across all bridge files returns zero
  hits).
- **Legacy global worktree directory removed** — `using-git-worktrees` and
  `finishing-a-development-branch` no longer use
  `~/.config/superpowers/worktrees/`; worktrees now land in the project
  (`.worktrees/`). Internal to those skills; the bridge dispatches them by name
  → transparent. The new worktree *location* is user-observable but requires no
  bridge change.
- **Vendor-neutral prose pass** — skills rewrote Claude-specific tool
  vocabulary ("use the Task tool" → "dispatch a subagent"; "CLAUDE.md" → "your
  instructions file") and added per-harness tool references. The bridge already
  ships dual `.claude` / `.agents` variants; the `.agents` prose is already
  harness-neutral.
- **`writing-plans` gains Global Constraints + per-task Interfaces blocks** —
  these are *produced* by `writing-plans` (which the bridge **disables** for an
  active Spec Kit feature). The *consumers* (`executing-plans`,
  `subagent-driven-development`) still load a plan-as-task-list and merely
  "note … global constraints" if present, so Spec Kit `tasks.md` still
  satisfies the consumption contract unchanged.
- **Three new harnesses** (Kimi Code, Pi, Antigravity) and an `evals/` testing
  reorg — purely additive upstream; no bridge impact.

Every Superpowers skill *name* the bridge invokes (`executing-plans`,
`test-driven-development`, `systematic-debugging`,
`verification-before-completion`, `requesting-code-review`,
`finishing-a-development-branch`, plus the guarded `writing-plans` /
`brainstorming` and the optionally-routed `subagent-driven-development`) is
**unchanged** in 6.0.0. The full bash smoke suite (6/6) passes unchanged with
Superpowers 6.0.0 installed.

This is therefore a **compatibility-alignment and evidence-refresh** release,
not a behavior change. Constitution Principle VI (Native-First Compatibility)
makes this explicit: the bridge MUST trust upstream growth and MUST NOT add
logic to "track" an upstream major. Changing bridge behavior here would violate
the very framework this feature is meant to preserve. The substantive work is
(a) the upstream-impact analysis that *proves* transparency rather than
assuming it, and (b) refreshing every version-pinned claim so users coming from
Superpowers 5.x know the bridge is verified against the 6.x line.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Superpowers-6.x user trusts the bridge's verified baseline (Priority: P1)

A user who has upgraded to Superpowers 6.0.0 checks the bridge's README badge,
`verified-versions.json`, and marketplace entry to confirm the bridge is
verified against the Superpowers major they are running, before adopting it in
a real Spec Kit project.

**Why this priority**: A stale "verified 5.1.0" claim against a live 6.x major
upstream is exactly the trust gap that makes a user hesitate to install. The
verified baseline is the bridge's public compatibility contract.

**Independent Test**: On the release commit, read the README badge,
`verified-versions.json`, and `marketplace/catalog-entry.json`; confirm each
names Superpowers 6.0.0 and bridge v1.1.0, and that the recorded evidence
matches what was actually run (smoke suite + analysis under 6.0.0).

**Acceptance Scenarios**:

1. **Given** the release commit, **When** a user reads the README (EN + zh-CN) "verified" claims, **Then** the Superpowers badge reads `verified_6.0.0` and the maintenance section names Superpowers 6.0.0.
2. **Given** `verified-versions.json`, **When** a user reads the baseline, **Then** `superpowers_version` is `6.0.0`, `bridge_version` is `1.1.0`, and the Linux bash evidence row records the 6.0.0 re-verification (smoke suite green + surface-audit) with a current date.
3. **Given** the marketplace material, **When** a catalog consumer reads it, **Then** version, `updated_at`, support summary, and submission baseline all name v1.1.0 / Superpowers 6.0.0, while `download_url` stays the stable latest-release alias.

---

### User Story 2 - Migrating user understands what changed upstream and why the bridge is unaffected (Priority: P2)

A user (or a future maintainer) reading the CHANGELOG wants to know, concretely,
what the Superpowers 6.0.0 major changed and why none of it required a bridge
behavior change — including the user-observable worktree-location change they
will see when the bridge drives `using-git-worktrees`.

**Why this priority**: "Verified 6.0.0, no changes needed" is only trustworthy
if the analysis behind it is visible. This is what distinguishes a real
alignment from a blind badge bump, and it is the audit trail Principle VI's
"trust upstream growth" decision rests on.

**Independent Test**: Read the CHANGELOG `[1.1.0]` entry and `research.md`;
confirm each 6.0.0 breaking/headline change is named with its bridge-impact
verdict (transparent / user-observable / additive), backed by a reproducible
grep over the bridge surface.

**Acceptance Scenarios**:

1. **Given** the CHANGELOG `[1.1.0]` section, **When** a migrating user reads it, **Then** it lists the 6.0.0 reviewer-prompt consolidation, worktree relocation, vendor-neutral prose, and new-harness additions, each with an explicit "bridge surface unaffected / transparent" verdict.
2. **Given** `research.md`, **When** a reviewer audits the transparency claim, **Then** the grep commands that confirm zero bridge references to the changed Superpowers internals are recorded and reproducible.

---

### Edge Cases

- A user still on Superpowers 5.x installs v1.1.0: the bridge invokes skills by
  name only and those names are identical across 5.1.0 and 6.0.0, so v1.1.0
  works on both the 5.x and 6.x lines (the verified baseline names 6.0.0 as the
  tested version, not a floor).
- A user relies on the old global worktree directory: that is an upstream
  removal inside `using-git-worktrees`, surfaced in the CHANGELOG as an
  informational note; the bridge neither created nor managed that directory.
- An automated consumer dispatches the *old* Superpowers reviewer prompt files
  directly: out of scope for the bridge (the bridge never dispatched the prompt
  files); the CHANGELOG note points such consumers at the upstream rename.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `verified-versions.json` MUST set `superpowers_version` to `6.0.0` and `bridge_version` to `1.1.0`, refresh `verified_at` to the release date, and record a Linux-bash evidence row whose note describes the actual 6.0.0 re-verification performed (full grep audit of the bridge surface + 6/6 smoke suite green under Superpowers 6.0.0). Evidence rows not re-run (Windows PowerShell, agent rows) MUST be retained with their original dates and a note that the corresponding bytes are unchanged.
- **FR-002**: The bridge version MUST be bumped `1.0.3` → `1.1.0` in `.specify/extensions/speckit-superpowers-bridge/extension.yml` (`extension.version`) and `marketplace/catalog-entry.json` (`version` + refreshed `updated_at`), with `download_url` unchanged (stable latest-release alias policy from v0.6.0).
- **FR-003**: `CHANGELOG.md` MUST add a `## [1.1.0]` section that (a) records the Superpowers verified baseline moving 5.1.0 → 6.0.0, and (b) documents the 6.0.0 upstream changes relevant to bridge users (reviewer-prompt consolidation, worktree relocation, vendor-neutral prose, new harnesses) each with an explicit "bridge surface unaffected" verdict.
- **FR-004**: README.md and README.zh-CN.md MUST update the Superpowers verified badge `verified_5.1.0` → `verified_6.0.0`, the maintenance/verified section `Superpowers 5.1.0` → `6.0.0`, and the version-pinned install example `1.0.3` → `1.1.0`.
- **FR-005**: `marketplace/extensions-readme-row.md` and `marketplace/extension-submission-body.md` MUST be refreshed to v1.1.0 (version string, support summary, `### Version`, baseline naming Superpowers 6.0.0, support matrix, and the Proposed Catalog Entry including `version` + `updated_at`), so the tag-triggered release gate (`validate-release-readiness.ps1`) passes.
- **FR-006**: `research.md` MUST record the reproducible upstream-impact analysis: the 5.1.0→6.0.0 source diff summary and the grep commands proving the bridge surface references none of the changed Superpowers internals (reviewer prompt filenames, global worktree path).
- **FR-007**: The full bash smoke suite (`bash tests/run-all.sh`, 6/6) MUST stay green on every commit of this feature, including after the version bump (the release-package test consumes the freshly built v1.1.0 ZIP).

### Out of Scope

- **Any bridge behavior change**: no new or modified command, hook, script, skill flow, state file, guard rule, handoff schema, or convention. Principle VI forbids adding logic to compensate for an upstream major; the SKILL/command/script bytes are frozen for this release.
- **Adopting Superpowers 6.0.0's new plan-format blocks** (Global Constraints / per-task Interfaces) into Spec Kit `tasks.md`: the bridge disables `writing-plans`; `tasks.md` is owned by Spec Kit and already satisfies the consumer contract.
- **Adding new-harness (Kimi/Pi/Antigravity) bridge variants**: the bridge ships `.claude` + `.agents`; additional harness variants are a separate future feature if ever needed, not part of a compatibility-alignment release.
- **Raising the bridge runtime floor** (`requires.speckit_version: ">=0.8.10"`) or changing the Spec Kit verified version (`0.10.2`, unchanged this feature).
- **Cutting the GitHub release**: tag push, release-gate publication, and the upstream catalog-update submission are deferred to a separate release step the maintainer triggers; this feature lands the in-repo alignment and commits it.

### Assumptions

- The cached 5.1.0 and 6.0.0 plugin trees in `~/.claude/plugins/cache/...` are faithful copies of the upstream releases; the source diff and grep audit over them are authoritative for the impact analysis.
- Windows PowerShell evidence and agent (Codex/Claude Code) evidence from v1.0.0/v1.0.3 remain valid because the bridge `ps`/`sh` script flavors, SKILL files, and command files are byte-identical in v1.1.0 (only version-metadata and docs change).
- Spec Kit remains at the already-verified CLI 0.10.2; this feature changes nothing about the Spec Kit side.

## Success Criteria *(mandatory)*

- **SC-001**: On the release commit, README (EN + zh-CN) Superpowers badge reads `verified_6.0.0`, the maintenance section names Superpowers 6.0.0, and the version-pinned install example names v1.1.0.
- **SC-002**: `verified-versions.json` names `superpowers_version: 6.0.0` and `bridge_version: 1.1.0`, and every advertised evidence row is backed by an action actually performed (no unverified claim).
- **SC-003**: `extension.yml` and `marketplace/catalog-entry.json` name version `1.1.0`; `download_url` is unchanged; `updated_at` is the release date.
- **SC-004**: The CHANGELOG `[1.1.0]` entry and `research.md` together name each 6.0.0 breaking/headline change with a bridge-impact verdict, with the transparency claim backed by reproducible greps.
- **SC-005**: `bash tests/run-all.sh` is 6/6 green on the release commit (including the v1.1.0 release-package check).
- **SC-006**: No occurrence of a *current-version* "5.1.0" Superpowers claim or a "1.0.3" bridge-version claim remains in README.md, README.zh-CN.md, `verified-versions.json`, `extension.yml`, or the `marketplace/` files (historical CHANGELOG entries and prior `specs/**` are exempt).
- **SC-007**: All seven release-checklist files enumerated in AGENTS.md ("Release version-bump checklist") carry v1.1.0, so a future tag run of `validate-release-readiness.ps1` would pass on version grounds.
