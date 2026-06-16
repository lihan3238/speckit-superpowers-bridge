# Changelog

All notable changes to **speckit-superpowers-bridge** are documented in this file.

This project adheres to [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

> **AI-assistance disclosure**: This extension is developed with AI coding assistants (Claude Code for design + planning, Codex for implementation passes, Claude Code for the v0.3.0 trim), per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit. As of v0.3.0 the verification surface is three retained smoke tests under `tests/`.

## [Unreleased]

## [1.1.0] - 2026-06-17

Superpowers **6.0.0** compatibility-alignment + evidence refresh. The verified
upstream baseline moves Superpowers **5.1.0 → 6.0.0** (a MAJOR upstream bump)
with **zero bridge runtime change**: no command, hook, script, skill flow,
guard rule, handoff-schema, or convention is touched. The bridge invokes
Superpowers by skill *name* only — every name it uses is unchanged in 6.0.0 —
and exchanges only Spec Kit `tasks.md`, whose consumer contract still holds.
Per constitution Principle VI (Native-First / Trust Upstream Growth), the
correct response to an upstream major is to add nothing; this release proves
that with a source-diff + grep audit rather than assuming it.

### Changed

- Verified-against-Superpowers baseline `5.1.0` → `6.0.0` across
  `verified-versions.json`, the README badges/maintenance sections (EN + zh-CN),
  and the `marketplace/` material. MINOR bridge bump `1.0.3` → `1.1.0` to mark a
  visible "verified against the Superpowers 6.x major line" milestone (same
  shape as v0.6.0's 5.1.0 alignment — a metadata/evidence release, not a
  workflow change).
- `download_url` stays the stable latest-release alias (v0.6.0 policy);
  `category: process` / `effect: read-write`, the `>=0.8.10` runtime floor,
  command count (3), and hook count (5) are unchanged.

### Upstream notes (informational)

Superpowers 6.0.0's breaking and headline changes are all **internal to upstream
skills** and transparent to the thin bridge (full analysis:
`specs/016-superpowers-6-0-0-alignment/research.md`):

- **`subagent-driven-development` review rewrite** — the two per-task reviewer
  prompts (`spec-reviewer-prompt.md` + `code-quality-reviewer-prompt.md`) were
  consolidated into a single `task-reviewer-prompt.md`, with new `task-brief` /
  `review-package` helper scripts and one whole-branch final review. These are
  files internal to the skill; the bridge dispatches the **skill by name** and
  never the prompt files. **Bridge surface unaffected** (grep-verified clean).
  Anyone who dispatched the old prompt files directly should switch to the new
  one per the upstream release notes.
- **Global worktree directory removed** — `using-git-worktrees` and
  `finishing-a-development-branch` no longer use `~/.config/superpowers/worktrees/`;
  worktrees now land in the project (`.worktrees/`). Internal to those skills;
  the bridge dispatches them by name. **Bridge surface unaffected** — the new
  worktree *location* is user-observable but requires no bridge change.
- **Vendor-neutral prose + per-harness tool references** — skills rewrote
  Claude-specific tool vocabulary and added references for Claude Code, Codex,
  Copilot, Gemini, Pi, and Antigravity. The bridge already ships dual
  `.claude` / `.agents` variants; the `.agents` prose is already harness-neutral.
  **Bridge surface unaffected.**
- **`writing-plans` adds Global Constraints + per-task Interfaces blocks** —
  these are *produced* by `writing-plans`, which the bridge **disables** for an
  active Spec Kit feature. The *consumers* (`executing-plans`,
  `subagent-driven-development`) still load a plan-as-task-list and only *note*
  constraints if present, so Spec Kit `tasks.md` still satisfies the contract.
  **Bridge surface unaffected.**
- **Three new harnesses (Kimi Code, Pi, Antigravity)** and an `evals/` testing
  reorg — purely additive upstream. **No bridge impact.**

### Verified

- Full bash smoke suite **6/6 green** with Superpowers 6.0.0 installed
  (`bash tests/run-all.sh`), including the release-package check against the
  rebuilt v1.1.0 ZIP.
- Bridge SKILL/command/script bytes are byte-identical to v1.0.3, which passed
  the published-artifact end-user sandbox cycle on Spec Kit 0.10.2
  (`specs/014-speckit-0-10-x-alignment/verification.md` T013); that evidence
  transfers to v1.1.0. The published-v1.1.0 sandbox cycle and the upstream
  catalog-update submission are deferred to the maintainer's release/tag step.

## [1.0.3] - 2026-06-12

### Added

- Declared the new first-class `category: process` and `effect: read-write`
  fields (introduced in Spec Kit 0.10.2's extension schema) in the bridge's
  `extension.yml` and `marketplace/catalog-entry.json`, matching the values
  upstream already assigned to the bridge entry in `catalog.community.json`.
  Backward compatible: validators at the `>=0.8.10` runtime floor ignore
  unknown manifest fields (verified against the 0.8.10 validator source and a
  0.10.2 round-trip install).

### Changed

- Re-verified the bridge end-to-end on Spec Kit CLI `0.10.2` (Linux bash /
  WSL2): source repo re-bootstrapped, full 6-test smoke suite passed
  unchanged, end-user sandbox cycle from the published release artifact.
  Refreshed `verified-versions.json` and README badges/claims accordingly;
  dated Windows PowerShell and real-agent rows from v1.0.0 are retained
  because the corresponding bytes did not change in this release.
- Updated AGENTS.md bootstrap guidance for Spec Kit 0.10.0's init-time
  breaking changes: the git extension is now opt-in (`specify extension add
  git` after `specify init`; `--no-git` removed), legacy `--ai` /
  `--ai-skills` / `--ai-commands-dir` flags were removed in favor of
  `--integration`, and `init-options.json` renamed `branch_numbering` →
  `feature_numbering` (bridge scripts never read this field).

### Compatibility

- Protocol surface unchanged: 3 commands, 5 hooks, both script flavors,
  handoff v1 schema, guard rules, and the `requires.speckit_version` runtime
  floor of `>=0.8.10` all carry over from v1.0.2 untouched.
- `marketplace/catalog-entry.json.download_url` remains the stable
  latest-release alias (policy unchanged since v0.6.0).

## [1.0.2] - 2026-06-04

### Added

- Added imagegen-generated launch cards under `assets/social/` for README,
  GitHub social preview, OpenGraph/community shares, Product Hunt-style gallery
  posts, and square community thumbnails.
- Added a README hero image so the repository presents a clearer first-screen
  identity on GitHub and in community links.

### Changed

- Tightened release/marketplace wording for the v1.0.x patch line while keeping
  the v1.0.0 stable protocol surface unchanged.
- Corrected the WSL proxy example in README files to match the current
  project-local proxy guidance.

## [1.0.1] - 2026-06-04

### Changed

- Clarified source-repo local extension usage: this development checkout already
  registers `.specify/extensions/speckit-superpowers-bridge/` as the installed
  local source, so contributors should not install the published ZIP back into
  the same checkout unless intentionally testing replacement behavior. Updated
  the version-pinned install example to v1.0.1.
- Documented the safe Spec Kit 0.9.x dev-registration path for this source repo:
  register from a temporary copy outside the in-repo target extension directory
  to avoid source=destination replacement.
- Ignored Spec Kit 0.9.x generated `.specify-dev` command material and canonical
  `speckit-speckit-superpowers-bridge-*` skill directories as local install
  state, while keeping the hand-authored short bridge peers tracked.

## [1.0.0] - 2026-06-04

Stable protocol release candidate for the Spec Kit + Superpowers bridge. This release keeps the bridge deliberately thin: Spec Kit remains the source of truth for design artifacts, Superpowers remains the implementation discipline, and the bridge continues to orchestrate only guard, handoff, execute, status, and archive behavior.

### Added

- Release-readiness validation now catches namespace and catalog drift before packaging: `extension.id`, marketplace catalog id, command names, and hook command references must all align to `speckit-superpowers-bridge`.
- Release package inspection now supports an explicit `-PackageZip` gate and verifies the ZIP root manifest, command files, both bash and PowerShell script flavors, README files, license, changelog, `.gitattributes`, `verified-versions.json`, and portable `/` archive entries.
- Focused release smoke coverage now includes `tests/test-release-package.sh`, `tests/test-release-powershell.ps1`, and expanded validator self-tests for namespace drift, missing script flavor, missing line-ending policy, and stale workflow test references.
- `verified-versions.json` now records the 1.0.0 bridge baseline with local upstream tool versions: Spec Kit `0.9.3`, Superpowers `5.1.0`, Codex CLI `0.137.0`, and Claude Code `2.1.162`, plus explicit platform and agent verification rows.

### Changed

- Bumped bridge release metadata to `1.0.0` in `extension.yml`, `marketplace/catalog-entry.json`, and `verified-versions.json`; the marketplace `download_url` remains the stable latest-release alias introduced in v0.6.0.
- Preserved the existing public bridge surface: 3 commands, 5 hooks, both script flavors, v1 handoff compatibility, and the `requires.speckit_version` runtime floor of `>=0.8.10`.
- Documented the 1.0.0 evidence model around mandatory Linux bash, native Windows PowerShell 5.1+, real Codex, and real Claude Code verification rows. Missing rows stay blockers rather than being advertised as support claims.
- The release workflow now builds the extension ZIP, extracts release notes, and writes the release summary through bash on Ubuntu. Windows PowerShell remains a focused compatibility gate and fallback script flavor, not the primary package-build path.

### Compatibility

- Direct upgrade from the current 0.7.2 baseline is supported. Existing readable handoff files, guard rules, command namespace, hook namespace, and status/archive behavior remain compatible.
- Windows PowerShell and Linux bash are first-class release targets for 1.0.0. WSL bash may satisfy the Linux row, but does not replace native Windows PowerShell evidence.

### Validation

- Release readiness validator self-tests cover version, catalog, namespace, workflow inventory, `.gitattributes`, and package-flavor drift.
- Package smoke checks include deterministic bash ZIP build and normalized ZIP-mode verification, no-heavy-runtime checks, and vendor-managed generated-skill protections so the bridge does not become a separate workflow engine or mutate generated Spec Kit command skills.
- Real sandbox, Codex, Claude Code, final artifact hash, release workflow, and demo-truth evidence are required before tagging or publishing can be claimed complete.

## [0.7.2] - 2026-06-02

Release-metadata correction for v0.7.1. No bridge runtime behavior changes.

### Changed

- Corrected the v0.7.1 release metadata after the `.github/workflows/release.yml` bash-suite change was deferred: the available GitHub credential cannot push workflow-file edits without `workflow` scope. The existing release workflow still completed successfully for v0.7.1.
- Kept the v0.7.1 Spec Kit `0.9.1` compatibility refresh, bundled `agent-context` source import, generated-skill ignore rules, release runbook cleanup, and ZIP packaging fix.
- Updated release metadata to `0.7.2` across `extension.yml`, `marketplace/catalog-entry.json`, `verified-versions.json`, README badges/maintenance text, and `marketplace/extension-submission-body.md`.

### Compatibility

- Direct upgrade from v0.7.0 or v0.7.1 is supported. Handoff schema, guard rules, script behavior, command count, hook count, and `artifacts_sha256` semantics are unchanged.

## [0.7.1] - 2026-06-02

Spec Kit v0.9.1 compatibility refresh and release-tooling alignment. No bridge runtime behavior changes from v0.7.0; this is a patch release so current v0.7.0 users can upgrade directly.

### Added

- Tracked Spec Kit's bundled `.specify/extensions/agent-context/` extension in this source repo after `specify init --here --script sh --force --integration claude` under Spec Kit v0.9.1. `.specify/extensions.yml` now explicitly installs `agent-context` and registers its optional `after_specify` / `after_plan` context-refresh hooks. This keeps the project ready for Spec Kit's announced removal of inline context updates in v0.12.0.

### Changed

- Refreshed verified compatibility from Spec Kit `0.8.16` to `0.9.1` while retaining Superpowers `5.1.0`: updated README badges, `README.zh-CN.md`, `verified-versions.json`, `extension-submission-body.md`, and marketplace version metadata.
- Kept `extension.yml.requires.speckit_version` and `marketplace/catalog-entry.json.requires.speckit_version` at `>=0.8.10`. Spec Kit v0.9.x's `agent-context` migration affects this repo's bootstrap state, not the bridge extension runtime.
- Ignored generated `.{claude,agents}/skills/speckit-agent-context-update/` directories as vendor-managed integration state, matching the existing generated-skill ignore policy.
- Updated `docs/release-runbook.md` to match the current release flow: pre-tag catalog version bump, release readiness validator, bash smoke suite, validator self-test, build dry run, then tag/push.
- Fixed `scripts/release/build-extension-zip.ps1` to include `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` in the release ZIP, matching the documented package metadata contract.

### Compatibility

- Direct upgrade from v0.7.0 is supported. Handoff schema, guard rules, script behavior, command count, hook count, and `artifacts_sha256` semantics are unchanged.
- Spec Kit v0.9.1 release notes list `agent-context` as bundled extension behavior carried from v0.9.0 plus v0.9.1 fixes for UTF-8 init-option I/O and missing Cline agent-context entries. The bridge does not depend on Cline and needs no non-incremental runtime update.

## [0.7.0] - 2026-05-28

`bridge-status` command + SHA256 handoff artifact-hash drift detection — two pillars borrowed from rpamis/comet's design, adapted to Native-First discipline. Additive on the v1 handoff schema (`schema_version` stays at 1; `additionalProperties: true` is the extension point). All 5 hardcoded guard rules and the 008-era `[bridge state]` print contract are byte-frozen — new lines (`Drift:`, `Next:`) only appear in the new `bridge-status` caller, never in `update-handoff` or `guard-command` output.

### Added

- **012 / FR-001..FR-004 / SC-001 (US1)**: New read-only `bridge-status.{sh,ps1}` helper at `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/`. Reads `.specify/superpowers-handoff.json` without writing, prints the existing 5-field `[bridge state]` block, plus optional `Drift:` line (when handoff has `artifacts_sha256`), plus a `Next:` recommendation derived from a deterministic 12-rule decision table. Supports `--json`/`-Json` for machine-readable output. Exit codes: 0 normal, 2 not-in-repo, 3 corrupted handoff. Contract: `specs/012-bridge-status-and-hash/contracts/bridge-status-output.md`. Solves the "I was away — where am I in this feature?" problem in one command under 1 second.
- **012 / FR-005, FR-006, FR-008 (US2)**: New optional top-level `artifacts_sha256` object on the handoff JSON, mapping `spec.md`/`plan.md`/`tasks.md` to their SHA256 snapshot (lowercase hex or `null` if file missing). Populated by `update-handoff.{sh,ps1}` on every `executing` and `complete` write. On `executing → complete` writes that detect drift against the prior snapshot: emit exactly one `[bridge] WARNING: artifact drift since executing snapshot: <files> (sha256 mismatch)` line to stderr AND append exactly one `artifact_drift_detected` event to `.specify/bridge-events.jsonl`. Exit code stays 0; the transition is not blocked — drift is advisory. Contract: `specs/012-bridge-status-and-hash/contracts/artifact-drift-event.md`.
- **012 / FR-009**: v1 handoff schema (`specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`) gains the `artifacts_sha256` property declaration + a conditional `allOf` rule requiring the field when `status` is `executing` or `complete`. Schema delta documented at `specs/012-bridge-status-and-hash/contracts/handoff-v1.1.delta.md`.
- **012 / FR-012**: New smoke test `tests/test-bridge-status.sh` with 26 cases covering all 14 decision-table vectors (V1..V14), all 5 US1 acceptance scenarios (S-OUT-1..5), all 6 US2 scenarios (S-EVT-1..6), FR-007 read-only enforcement, FR-013 backward-compat, and the SC-003 byte-identical idempotency check. New fixture at `tests/fixtures/pre-070-handoff.json` exercises pre-0.7.0 reader-tolerance.

### Changed

- **012 / FR-005**: `update-handoff.{sh,ps1}` compute SHA256 of the three source-of-truth artifacts on every `executing`/`complete` write and embed them as `artifacts_sha256`. Bash delta: 48 added lines (within SC-010 (c) 60-line budget). PowerShell delta: 47 added lines (within SC-010 (d) 60-line budget). Existing v0.5.0+ `[bridge state]` print contract preserved byte-identical.
- **012 / FR-002, FR-007**: `bridge-state.{sh,ps1}` shared helper gains new pure-function additions (`compute_artifact_sha256`, `build_artifacts_sha256_json`, `get_drift_list`, `build_drift_details_json`, `get_next_command_recommendation` in bash; `Get-ArtifactSha256`, `Get-ArtifactsSha256Map`, `Get-DriftList`, `Get-DriftDetails`, `Get-NextCommandRecommendation` in PowerShell). Existing `write_bridge_state_summary` / `Write-BridgeStateSummary*` functions stay byte-identical so `update-handoff` and `guard-command` outputs remain unchanged.
- **012**: Bridge version 0.6.0 → 0.7.0 across `extension.yml` and `marketplace/catalog-entry.json`. `download_url` unchanged (permanently aliased to `releases/latest/download/speckit-superpowers-bridge.zip` per v0.6.0 decoupling).
- **012 / FR-011**: Project-owned `speckit-superpowers-bridge` SKILL.md peers (Claude + Codex) each gain one bullet under a new `## Useful commands (v0.7.0+)` heading referencing `bridge-status`. Documentation-only — no behavioral instruction changes. Vendor-managed `.{claude,agents}/skills/speckit-*` skills (other than this project-owned peer) untouched.

### Compatibility

- Schema `schema_version` stays at **1**. New `artifacts_sha256` field is **additive** on the v1 schema's `additionalProperties: true` extension point. No reader migration required.
- Handoffs written by **v0.4.x, v0.5.x, v0.6.x** without `artifacts_sha256` continue to read cleanly under v0.7.0+: bridge-status omits the `Drift:` line; update-handoff does NOT emit a false-positive drift warning on the first `complete` write under v0.7.0+ (no prior snapshot to compare against). The next `executing` write populates the field.
- All 5 hardcoded guard rules in `guard-command.{sh,ps1}` **byte-frozen** vs v0.6.0.
- Existing 008-era `[bridge state]` print contract preserved verbatim (5 lines, same order, same labels) for `update-handoff` and `guard-command` callers per SC-008. New `Drift:` + `Next:` lines emitted ONLY by the new `bridge-status` caller.
- Verified against **Superpowers 5.1.0** and **Spec Kit 0.8.16** (verified pair carried forward from v0.6.0; refresh if upstream changes).

## [0.6.0] - 2026-05-28

Comet-style README polish + upstream verified-pair refresh + marketplace `download_url` decoupling. Bridge surface (scripts, guard rules, SKILL.md behavioral instructions, `extensions.yml` hooks) byte-frozen — v0.6.0 ships **zero behavioral changes** beyond documentation, version metadata, and the one-file `verified-versions.json` re-introduction. Net effect: a more discoverable README and one fewer source-of-truth file to edit per future release.

### Added

- **011 (v0.6.0 polish)**: Hero-led README layout modelled on the rpamis/comet structural pattern (`<p align="center">` hero + tagline + 5-badge row with `style=flat-square`, language-toggle blockquote, bold value-prop, `## Why` / `## Quick Start` / `## Positioning` above the first scroll fold, 10 `<details>`-collapsed factual sections including Workflow / Installation / Prerequisites / First Feature / When to Skip / Commands / Configuration / Troubleshooting / Maintenance / Architecture). Uses native Markdown + GitHub-flavored alerts (`> [!TIP]` / `> [!NOTE]` / `> [!WARNING]`) only — no JavaScript, no CSS, no build step, no SVG mirror.
- **011**: `README.zh-CN.md` mirror with structural parity (identical H2 count, identical `<details>` count, identical 5-badge row, identical comparison-table row count); prose translated, commands/paths/code blocks stay English per CLAUDE.md preservation rule.
- **011 / FR-004**: Re-introduced `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` with a locked 5-field schema (`verified_at`, `spec_kit_version`, `superpowers_version`, `bridge_version`, `notes`) and a documented additive-only extension policy. Schema captured in `specs/011-v060-comet-polish/contracts/verified-versions.schema.json`. Closes the long-standing runbook reference / file-absent gap that has been present since v0.3.0.
- **011**: New `## Positioning` comparison table distinguishing the bridge from `speckit.implement`-alone, raw Superpowers, and rpamis/comet (peer hybrid). Factual cell content only; refreshed only when a peer changes positioning.

### Changed

- **011 / FR-007 — DECOUPLED `marketplace/catalog-entry.json.download_url`** from the per-release version pin to the GitHub stable-alias URL `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`. This is a **one-shot freeze**: post-v0.6.0 releases never edit `download_url` again — only the `version` field bumps per release. Empirically safe because every release since v0.5.0 already uploads BOTH the versioned ZIP and the stable-aliased `speckit-superpowers-bridge.zip` asset (verified via GitHub API at clarify time: 44 708 bytes identical). Net effect: one permanent fewer source-of-truth file to edit per release.
- **011 / FR-006**: `.specify/extensions/speckit-superpowers-bridge/extension.yml` `extension.version` 0.5.0 → 0.6.0. `requires.speckit_version` floor STAYS at `>=0.8.10` — no v0.6.0 functionality requires a newer Spec Kit, and bumping the floor would force needless upgrade pressure on existing users.
- **011 / FR-007**: `marketplace/catalog-entry.json.version` 0.5.0 → 0.6.0.
- **011 / FR-017**: `docs/release-runbook.md` Step 10 updated to retire the per-release `download_url` edit instruction; post-publish stable-alias `curl` verification added (broader runbook hygiene around removed-in-0.3.0 script references is deferred to a future cleanup feature — out of v0.6.0 SC-010 lightness budget).
- **009 (WSL dev env alignment, carried from prior Unreleased)**: ported `tests/test-*.ps1` → `tests/test-*.sh` and deleted the PowerShell originals after the bash equivalents verified green on WSL bash (4 ports + a new `tests/run-all.sh` runner; full suite < 10 s on a typical WSL host). Smoke-test surface now bash-only, consistent with the project's primary dev environment moving to WSL.
- **009**: untracked Spec Kit install-time state per `specs/009-wsl-dev-env-alignment/spec.md` Clarifications Q1+Q2 Policy — `.specify/scripts/`, `.specify/init-options.json`, `.specify/integration.json`, `.specify/integrations/*.manifest.json`, and the vendor-managed slash-command skill files under `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-commit,git-feature,git-initialize,git-remote,git-validate}/`. The project-owned `.{claude,agents}/skills/speckit-superpowers-bridge/` remains tracked. Each developer regenerates the install-state locally via `specify init --here --script <ps|sh> --force`.
- **009**: normalized `.gitattributes` + `.gitignore` to LF (FR-002 — corrects a phantom CRLF/LF mismatch surfaced on the maintainer's first WSL run).
- **009**: marketplace docs updated to reference `tests/test-*.sh` (was `.ps1`).
- **010 (pre-spec brainstorming handoff)**: documented the optional Superpowers `brainstorming` → `/speckit-specify` lifecycle decision in README + zh-CN mirror; zero new bridge code or guard rules added. See `specs/010-prespec-brainstorming/spec.md` (doc-only feature; landed alongside v0.6.0).

### Compatibility

- Verified against **Superpowers 5.1.0** and **Spec Kit 0.8.16** — see `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`.
- Bridge script surface (`guard-command.{ps1,sh}`, `update-handoff.{ps1,sh}`, `auto-archive-handoff.{ps1,sh}`, `bridge-state.{ps1,sh}`, `common-actor-resolution.{ps1,sh}`) is **byte-identical** to v0.5.0.
- 5 hardcoded guard rules in `guard-command.{ps1,sh}` are **byte-identical** to v0.5.0.
- Project-owned bridge `SKILL.md` peers at `.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md` carry no behavioral-instruction changes (cosmetic version-line refreshes only, if any).
- Vendor-managed `.{claude,agents}/skills/speckit-*` skills (other than the project-owned `speckit-superpowers-bridge` peers) untouched.
- Minimum direct-upgrade source: still v0.4.2 (carried forward from v0.5.0 baseline).

### Upstream notes (informational only — no bridge remediation required)

- **Superpowers v5.1.0** removed legacy slash commands `/brainstorm`, `/execute-plan`, `/write-plan` (deprecated stubs). The bridge invokes by skill name (`superpowers:brainstorming`, `superpowers:executing-plans`, `superpowers:writing-plans`) — grep-verified clean during planning.
- **Superpowers v5.1.0** removed the `superpowers:code-reviewer` named agent; its persona+checklist merged into `skills/requesting-code-review/code-reviewer.md` as a Task-dispatch template. The bridge invokes `superpowers:requesting-code-review` (the skill) — grep-verified clean.
- **Superpowers v5.1.0** `superpowers:finishing-a-development-branch` is now provenance-scoped — it only cleans worktrees inside `.worktrees/` (created by Superpowers itself). Worktrees outside that path are left alone. Behavior change inside the upstream skill, transparent to the bridge.
- **Superpowers v2.0+** moved skills into a separate `obra/superpowers-skills` repo, leaving the plugin as a lightweight shim. Transparent to bridge consumers; skills still resolve by name through whichever loader each agent uses.
- **Spec Kit v0.8.16** changes (smart JSON merging for `.vscode/settings.json` in `specify init`, multi-install support per PR #2389, build/CI refinements) are transparent to bridge consumers.

## [0.5.0] - 2026-05-16

Bridge drift hardening + v0.5.0 cleanup release. The bridge now surfaces its own state on every script invocation and warns when a feature is marked `complete` while non-deferred tasks remain unchecked — the root-cause fix for the documentation-accuracy drift class of bug that surfaced in the v0.4.2 / v0.4.3 cycles. Resets the minimum direct-upgrade baseline to v0.4.2.

### Added

- **US1**: `bridge-state.{ps1,sh}` shared helper sourced by `update-handoff.{ps1,sh}` and `guard-command.{ps1,sh}`. Computes canonical `Pending tasks: N` count from `<feature_directory>/tasks.md` using the regex `^- \[ \] T\d+` (FR-001 / Clarifications Q4) and respects section-header deferred-exemption per FR-005 / Q6 (any task-ID line under `## Deferred|Optional|Out of Scope|Won't do|Future|Wontfix|Backlog` is excluded). Prints a `[bridge state]` block (Feature directory / Status / Artifact owner / Actor / Pending tasks) on every successful script invocation.
- **US1**: `update-handoff` now logs `prior_actor` in every `bridge-events.jsonl` handoff entry. When a transition changes the actor (e.g., `claude → codex`), the `reason` field is augmented with `actor change <prior> → <new>` (operator-supplied `-Reason` text is preserved with a `;` separator, never overwritten).
- **US1 / FR-003**: `update-handoff` emits `[bridge] WARNING: handoff is 'complete' but tasks.md has <N> unchecked tasks; review or move under a deferred section.` to stderr when transitioning to `complete` while non-deferred unchecked task-ID lines remain. Exit code stays 0 — the warning surfaces the drift; the operator decides how to resolve.
- **US1**: `tests/test-bridge-state-summary.ps1` regression covering SC-001/SC-002/SC-003. PowerShell flavor verified GREEN; bash flavor gated on `jq` + `awk` prerequisites with skip-on-failure semantics (same v0.4.2 B2 strategy chain).
- **US2**: `specs/007-catalog-distribution-polish/verification.md` gained a `## Gate evidence` subsection recording the SC-005 byte-freeze (`0 lines diff`) and SC-006 spec-history checksum (`96e3dffe…`, identical to v0.4.1 baseline) for the 007 cycle's complete point.
- **US3**: `marketplace/README.md` gained a `## Catalog update policy` section citing the upstream-documented method (`extensions/EXTENSION-PUBLISHING-GUIDE.md` at commit `81e9ecd`, dated 2026-05-16) and our Q5=C policy (minor/major releases file an issue; patch releases skip and rely on the stable-alias URL).

### Changed

- **US2**: `specs/007-catalog-distribution-polish/tasks.md` T022-T028 now correctly marked `[x]` with evidence pointers; T029 (optional upstream catalog-update issue) moved under a `## Deferred (per 008 Clarifications Q5)` H2.
- **US2**: `specs/003-bridge-cross-platform-scripts/tasks.md` all 56 v0.4.2-cleanup-tail task-ID checkboxes ticked `[x]`; new `## Deferred (user-side verification, inherited from v0.4.0 tasks.md)` subsection anchors the FR-005/Q6 exemption semantics for any future appended items.
- **US3 / FR-009**: `marketplace/extensions-readme-row.md` column-header comment realigned to upstream's current `Extension | Purpose | Category | Effect | URL` shape (changed since PR #2586's `Name | Description | Category | Permissions | Repository`). Cell content unchanged.
- **US3 / FR-011**: `marketplace/extension-submission-body.md` bumped to v0.5.0 with `<filled-by-workflow-on-tag>` placeholders for SHA256 and workflow URL. Fresh-install smoke notes mention the new `[bridge state]` block and FR-003 warning.
- **US3 / FR-011**: `marketplace/catalog-entry.json` version 0.4.3 → 0.5.0; download_url to the v0.5.0 versioned ZIP.
- **US4**: `extension.yml` `extension.version` 0.4.3 → 0.5.0.
- **US4 / FR-015**: `AGENTS.md` pruned of pre-0.4.2 version references outside historical context; new "Compatibility baseline" pointer declares v0.4.2 as the minimum direct-upgrade source per CHANGELOG `[0.5.0] § Compatibility`.

### Compatibility

- **Minimum direct-upgrade baseline**: **v0.4.2**. Users on v0.4.2 or v0.4.3 upgrade to v0.5.0 with no migration — the handoff schema (`.specify/superpowers-handoff.json`) and event log shape (`.specify/bridge-events.jsonl`) remain byte-stable. The new `prior_actor` field on handoff events is purely additive; pre-v0.5.0 readers ignore it (JSON), post-v0.5.0 readers see `null` on legacy lines.
- Users on **v0.4.0 / v0.4.1** should upgrade through v0.4.2 first OR re-install fresh via the stable-alias URL `releases/latest/download/speckit-superpowers-bridge.zip`. The v0.4.0 → v0.4.1 cycles are no longer called out in supporting docs (AGENTS.md, marketplace) outside historical / CHANGELOG context.
- The previous "branch = release line" pattern (v0.4.0 → v0.4.3 all tagged on `003-cross-platform-cleanup`) is discontinued — v0.5.0+ releases tag on `main`. Long-running release branches are not used going forward.

### Validation

- All 3 pre-existing smoke tests pass (`tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`) — no regression from US1 runtime changes.
- New `tests/test-bridge-state-summary.ps1` passes (PowerShell flavor; bash flavor exercised in sandbox).
- Validator self-test passes (`scripts/release/test-validate-release-readiness.ps1`).
- Local pre-tag validator passes for version 0.5.0.
- Constitution v1.2.0 sandbox gate exercised on Windows PowerShell + WSL Linux bash (PASS rows in `specs/008-bridge-hardening-0-5-0/verification.md`); macOS row PENDING with reason "no host available" per Clarifications Q1.

### Compliance

- SC-013 north-star: `git diff v0.4.3..v0.5.0 -- .specify/extensions/speckit-superpowers-bridge/` is confined to `scripts/{powershell,bash}/` (5 files modified, 2 new helpers) plus the bridge SKILL.md peers. No new Spec Kit commands, no new Superpowers skills, no new top-level directories.
- AI-assistance disclosure: this release was designed and implemented with Claude Code (design + planning + Phase A-D implementation passes) and Codex (cross-flavor review). All artifacts passed human review before commit.

## [0.4.3] - 2026-05-16

Official catalog distribution polish. No bridge runtime behavior changed.

### Changed

- README install instructions now present the official Spec Kit community catalog as the discovery/trust surface, while using the stable latest-release ZIP URL for default installs because the community catalog is discovery-only by default.
- Release automation now uploads both the versioned ZIP and a stable `speckit-superpowers-bridge.zip` alias, enabling `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`.
- Version-pinned ZIP installation remains documented for reproducible installs.
- Marketplace materials were updated for the accepted official listing flow: initial listing accepted in github/spec-kit issue #2581 and PR #2586, future updates go through a new Extension Submission issue as an existing-entry update.
- `marketplace/extensions-readme-row.md` now matches the current upstream `docs/community/extensions.md` table shape: Name, Description, Category, Permissions, Repository.
- Tool metadata was slimmed to the official accepted catalog shape: optional PowerShell, bash, and jq only. Git remains recommended workflow discipline but is not declared as an extension runtime tool.

### Compatibility

Functionally identical to v0.4.2. Users on v0.4.1 or v0.4.2 may upgrade directly; no migration required.

## [0.4.2] - 2026-05-16

Patch / cleanup release with no new bridge capability. This release closes the v0.4.0 → v0.4.1 cleanup tail by addressing **B1**, **B2**, **C1**, **C4**, and **US4** — the five items left open after v0.4.1's marketplace alignment. The bridge runtime (handoff, guard, auto-archive, actor resolution) is byte-frozen aside from one surgical SKILL.md edit (B1).

This release also closes the first execution of the constitution v1.2.0 "End-User Verification Sandbox" gate — `..\test_specify_superpower` is the canonical sibling sandbox; every release artifact from v0.4.2 forward MUST be verified there before its handoff transitions to `complete`.

### Fixed

- **B1**: `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` no longer hardcode `-ArtifactOwner claude` / `--artifact-owner claude` in their step-3 update-handoff example. The 4-step actor-precedence chain inside `update-handoff.ps1` / `update-handoff.sh` was always correct (explicit arg → prior handoff value → resolved actor → `"unknown"`); the SKILL example was overriding step 2 unnecessarily and could clobber a valid prior `artifact_owner` on cross-agent handoff. Both peers now omit the flag and document that the script silently preserves the prior owner. (US1)
- **B2**: `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` now translate Windows paths to bash-reachable paths through a 5-strategy chain (`cygpath` → `/mnt/<drive>` → MSYS shorthand `/<drive>` → native `bash.exe` direct → skip-with-reason). The bash flavor is also gated on a prerequisite probe; if `jq` or another dependency is missing, the flavor is skipped with a recorded reason instead of producing a false-red. PowerShell flavor remains the source of truth on Windows dev boxes. (US2)

### Changed

- **C1**: `.gitignore` now excludes install-time registry state — `.specify/workflows/workflow-registry.json`, `.specify/workflows/*/workflow.yml`, and `.specify/extensions/.registry`. These files are regenerated locally by `specify extension add` / `specify extension list` and should never be tracked. Existing tracked copies were removed from the index in this release. (US3)
- **C4**: `specs/003-bridge-cross-platform-scripts/tasks.md` was refreshed to a v0.4.2 task list focused on the cleanup tail (B1 + B2 + C1 + C4 + US4 sandbox), with a historical pointer to commit `a4aa833` for the original v0.4.0 task list. The previous tail of 17 work-in-progress tasks is absorbed by this redesign. (US3)
- `AGENTS.md` gained a new "Install-time registries are local state, not tracked" subsection documenting the C1 gitignore rule and the rationale (per-developer, locally generated, not vendored).
- `extension.yml`, `marketplace/catalog-entry.json`, and `marketplace/extension-submission-body.md` now target v0.4.2.

### Added

- **US4**: `specs/003-bridge-cross-platform-scripts/verification.md` records the sandbox-install verification run required by constitution v1.2.0 §"End-User Verification Sandbox". Each release from v0.4.2 forward appends one `## <version>` section with a row per supported platform (Windows PowerShell, Linux/macOS bash). Schema is pinned by `contracts/verification-record.md`. v0.4.2 records Windows PowerShell + WSL Linux bash as the two real-host runs; macOS is PENDING with the noted reason "no host available" per Clarifications Q3.

### Compatibility

Functionally identical to v0.4.1. The bridge runtime (handoff schema, guard rules, actor chain, auto-archive, audit log) is byte-frozen. Users on v0.4.0 or v0.4.1 may upgrade directly; no migration required.

### Validation

- All 3 bridge smoke tests green: `tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`.
- Validator self-test green: `scripts/release/test-validate-release-readiness.ps1`.
- Local validator passes for version 0.4.2.
- Constitution v1.2.0 sandbox gate satisfied (`..\test_specify_superpower`): Windows PowerShell + WSL Linux bash recorded in `specs/003-bridge-cross-platform-scripts/verification.md`; macOS deferred per Clarifications Q3.

## [0.4.1] - 2026-05-16

Marketplace alignment patch. No bridge runtime behavior changed.

### Changed

- `extension.yml`, `marketplace/catalog-entry.json`, and install docs now target v0.4.1.
- Catalog tags reduced from six to the five-tag set required by the Extension Submission template: `bridge`, `superpowers`, `cross-agent`, `tdd`, `workflow`.
- Tool metadata now distinguishes the Windows PowerShell flavor from the Linux/macOS bash + jq flavor.
- GitHub Actions release workflow now uses `actions/checkout@v6`.
- Marketplace submission materials were rewritten around the bridge philosophy: Spec Kit owns WHAT, Superpowers owns HOW, and the bridge only orchestrates native capabilities.

### Compatibility

Existing v0.4.0 installs can upgrade directly. The handoff schema, commands, hooks, guard rules, and script behavior are unchanged.

## [0.4.0] - 2026-05-15

Cross-platform compatibility release. The bridge now ships one ZIP that contains both Windows PowerShell scripts and Linux/macOS bash scripts.

### Added

- Four bash runtime scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`: `common-actor-resolution.sh`, `update-handoff.sh`, `guard-command.sh`, and `auto-archive-handoff.sh`.
- `.gitattributes` with `*.sh text eol=lf` so shell scripts keep LF line endings on Windows clones.
- `bash >= 4.0` and `jq >= 1.6` tool metadata in `extension.yml` and `marketplace/catalog-entry.json`.

### Changed

- The execute command now declares the short alias `speckit.superpowers-bridge`, so fresh marketplace installs generate `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` in addition to the canonical fallback.
- `scripts/release/build-extension-zip.ps1` now packages `scripts/bash/` beside `scripts/powershell/`.
- `scripts/release/validate-release-readiness.ps1` now checks bash/PowerShell script parity and the `.gitattributes` shell-script LF rule.
- The retained smoke tests now auto-detect available script flavors and exercise both `ps` and `bash` when present.
- README prerequisites now document Linux/macOS runtime requirements and clarify that `pwsh` is only needed for contributors running the smoke tests.

### Fixed

- Fresh marketplace installs no longer leave users with only the long generated `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute` entrypoint.
- Release ZIPs now place `extension.yml` directly at archive root and use portable `/` entry separators, matching Spec Kit's latest Linux/macOS installer expectations.

### Compatibility

Existing Windows installs continue using the PowerShell flavor. Linux/macOS installs use the bash flavor through Spec Kit's existing `init-options.json.script` setting. No handoff migration is required; both flavors read older v2/v3 handoff documents tolerantly and write the v1 shape.

### Validation

- `tests/test-handoff-shape.ps1` green with `(ps, bash)`.
- `tests/test-guard-hardcoded-rules.ps1` green with `(ps, bash)`.
- `tests/test-claude-codex-skill-parity.ps1` green.
- `scripts/release/test-validate-release-readiness.ps1` green with 7/7 cases.

## [0.3.1] - 2026-05-15

Tooling + alignment patch. No behavior changes in the bridge itself; this release ships the release-automation infrastructure that v0.3.0 didn't have, and aligns several stale references that were missed during the v0.3.0 cut.

### Added

- `.github/workflows/release.yml` — GitHub Actions workflow that fires on `v*.*.*` tag push and automates the build → release → asset upload chain. Runs the validator + bridge smoke tests + release-tooling self-tests before building; extracts the matching CHANGELOG section as release notes; emits SHA256 + asset URL to the workflow's step summary.
- `scripts/release/validate-release-readiness.ps1` — pre-flight validator checking four cross-references (extension.yml version, catalog-entry.json version, catalog-entry.json download_url, CHANGELOG section presence). Runnable locally before tagging and in CI.
- `scripts/release/test-validate-release-readiness.ps1` — 5-case TDD test suite (1 positive + 4 negative) for the validator.
- `scripts/release/build-extension-zip.ps1` — already added in v0.3.0; now made cross-platform (replaced `$env:TEMP` with `[System.IO.Path]::GetTempPath()` so it runs on ubuntu pwsh, not just Windows).

### Changed

- `extension.yml.extension.version` → `0.3.1`.
- `marketplace/catalog-entry.json` `version` + `download_url` → 0.3.1; description shortened earlier in this cycle to 91 chars to stay under the publishing-guide soft cap.
- `marketplace/README.md` — release procedure rewritten to reflect the automated workflow; distinguishes pre-tag manual edits, auto on tag push, and the cross-repo issue comment that stays manual.
- `marketplace/upstream-pr-body.md` — references corrected from auto-archive URL back to release-asset URL; "since v0.2.0" framing corrected to "since v0.1.1" (v0.2.0 was a CHANGELOG marker, never tagged).
- `.specify/workflows/speckit-superpowers/workflow.yml` — `workflow.version` `0.1.1` → `0.3.0` (the trim should have included this; caught during post-release sweep).
- `.specify/workflows/workflow-registry.json` — speckit-superpowers entry version bumped to 0.3.0 with refreshed `updated_at`.
- `.specify/extensions/.registry` — speckit-superpowers-bridge entry version bumped to 0.3.0; `registered_commands` trimmed from 7 (stale) to 3 (current).
- `.gitignore` — `docs/` rule (already in v0.3.0); obsolete cleanup-audit comment removed.

### Fixed

- 5 cross-reference drifts caught by code review on v0.3.0 (commit `f9f5490` in the v0.3.0 timeline):
  - `commands/speckit.speckit-superpowers-bridge.execute.md` referenced deleted `emit-skill-invocation.ps1` and the dropped `-ResumeContext` parameter.
  - `commands/speckit.speckit-superpowers-bridge.guard.md` documented guard rules that didn't match the actual hardcoded set, plus a non-existent `-AllowDiscardSpecArtifacts` parameter.
  - `commands/speckit.speckit-superpowers-bridge.handoff.md` described a 4-step actor chain that the trim collapsed to 3 steps.
  - `contracts/handoff.v1.schema.json` — `artifact_owner` enum was missing `"unknown"` while the script wrote it as default.
  - `contracts/handoff.v1.schema.json` — `supersedes` typed as `string|null` while the script wrote it as an array.

### Compatibility

Functionally identical to v0.3.0. Users on v0.3.0 can upgrade or skip; no migration required.

### Validation

- All 3 bridge smoke tests green.
- 5/5 validator TDD cases green.
- Local validator passes for version 0.3.1.
- Release artifact build verified locally to match `agent-governance` shape.

## [0.3.0] - 2026-05-15

A deliberate drastic trim — the bridge becomes the thin orchestrating layer it was always supposed to be. **~87% PowerShell line reduction**, no functional capability added. See [`specs/006-trim-to-thin-bridge/spec.md`](specs/006-trim-to-thin-bridge/spec.md) for the full rationale, and [`specs/006-trim-to-thin-bridge/cut-inventory.md`](specs/006-trim-to-thin-bridge/cut-inventory.md) for the enumerated removal list.

### Removed

PowerShell scripts (13 deletions):

- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-distribution-manifest.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1` (replaced by README "When to Skip Spec Kit" section; routing decision is now user-driven)
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-resume-signal.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-skill-invocation.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/restore-snapshot.ps1` (snapshot rollback is now manual `cp -r`)
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`

Bridge command markdowns (6 deletions):

- `commands/speckit.speckit-superpowers-bridge.parity.md`
- `commands/speckit.speckit-superpowers-bridge.audit.md`
- `commands/speckit.speckit-superpowers-bridge.validate.md`
- `commands/speckit.speckit-superpowers-bridge.submission-checklist.md`
- `commands/speckit.speckit-superpowers-bridge.cleanup-audit.md`
- `commands/speckit.speckit-superpowers-bridge.recommend-route.md`

Bridge data files (3 deletions):

- `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` (replaced by 5 hardcoded `if`/`elseif` rules inside `guard-command.ps1`)
- `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` (version compatibility is now human-inspection at release time, recorded in this CHANGELOG)
- `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` (catalog-entry.json is sufficient)

Bridge contracts and docs (2 deletions):

- `.specify/extensions/speckit-superpowers-bridge/contracts/plugin-distribution-manifest.schema.json` (the schema for a now-removed manifest)
- `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md` (parameters it documented no longer exist)

Tests under `tests/` (15 deletions; 2 more in commit 5 under `scripts/powershell/`):

- `test-parity-drift.ps1`, `test-install-state-audit.ps1`, `test-validation-pass.ps1`, `test-submission-checklist.ps1`, `test-cleanup-audit.ps1`, `test-distribution-manifest.ps1`, `test-routing-recommender.ps1`, `test-resume-signal.ps1`, `test-skill-invocation-event.ps1`, `test-extension-manifest-install.ps1`, `test-disposition-matrix.ps1`, `test-verified-versions.ps1`, `test-readme-bilingual-parity.ps1`, `test-actor-resolution.ps1`, `test-constitution-checklist-guard.ps1`, `test-guard-uses-matrix.ps1`, `test-hook-surface-resolution.ps1`

Handoff schema v3 fields (now `schema_version: 1` in new writes; older v2/v3 documents are still readable):

- `autonomous_mode`
- `resume_context`
- `archive_history`

Hooks in `.specify/extensions.yml`:

- `before_specify` hook entry removed entirely (its sole handler was `recommend-route`)
- Every hook referencing a removed command was deleted

`docs/` directory:

- `docs/release-runbook.md` and any future maintainer-only files under `docs/` are now gitignored (kept on the maintainer's local disk; not shipped in the repo).

### Changed

- `extension.yml.version` bumped to `0.3.0`.
- `extension.yml.provides.commands` reduced from 9 to 3 (`execute`, `handoff`, `guard`).
- `extension.yml.hooks` reduced from 6 to 5 (`before_specify` removed).
- `marketplace/catalog-entry.json`: version `0.3.0`, `provides.commands: 3`, `provides.hooks: 5`, refreshed description to "A thin orchestrating bridge between Spec Kit (design) and Superpowers (implementation). Cross-agent (Codex + Claude Code). Native skills only — no custom discipline."
- `marketplace/upstream-pr-body.md`: rewritten for 0.3.0; AI-assistance disclosure paragraph preserved verbatim.
- `marketplace/extensions-readme-row.md` + `marketplace/README.md`: updated for 0.3.0 description and the manual-submission workflow.
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1`: 393 → 189 lines. New writes use v1 schema. Reads tolerate v2/v3 unknown fields per FR-009 (the trim's explicit user-friendliness goal for in-flight upgrades).
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`: 259 → 92 lines. Five hardcoded rules replace the matrix lookup.
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1`: 97 → 54 lines. Emits an `archive` event (renamed from `auto_archive`).
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1`: 58 → 41 lines. Three-step actor chain (explicit → env → "unknown"); dropped `.specify/integration.json` consultation.
- `.claude/skills/speckit-superpowers-bridge/SKILL.md`: 149 → 62 lines. Now describes orchestration only.
- `.agents/skills/speckit-superpowers-bridge/SKILL.md`: 146 → 59 lines. Content-identical Codex peer.
- `README.md` + `README.zh-CN.md`: rewritten to reflect the thin bridge; added new `## When to Skip Spec Kit` section replacing the deleted `recommend-route` advisory. Bilingual H2 parity preserved (10 H2s in each, English anchors).
- `AGENTS.md` + `CLAUDE.md`: removed references to deleted commands and to `disposition-matrix.json` / `verified-versions.json`.
- `.gitignore`: added `docs/`; removed an obsolete comment referencing `cleanup-audit`.
- The `bridge-events.jsonl` log no longer carries event types: `skill_invocation`, `parity_check`, `submission_check`, `auto_archive` (the last is now `archive` with `status: "archived"`).

### Compatibility notes

- **Reading old handoff JSON**: a 0.3.0 install reads handoff JSON written by 0.1.x / 0.2.x without error; v2/v3-only fields are silently ignored. The next write produces a clean v1 document. No migration step required.
- **CI / Make files**: if you reference any of the removed scripts (e.g., `parity-check.ps1`, `validation-pass.ps1`, `submission-checklist.ps1`, `cleanup-audit.ps1`, `recommend-route.ps1`), update or remove those references. The trim does not provide compatibility shims.
- **Routing recommendation**: the previous `recommend-route` command is gone. See the new README `## When to Skip Spec Kit` section; the user decides the route.
- **Snapshot rollback**: `restore-snapshot.ps1` is gone. Snapshots are still taken under `.specify/bridge-snapshots/`; rollback becomes a manual `cp -r <snapshot-dir>/* <destination>`.

### Verification

- Three retained smoke tests, all green: `tests/test-claude-codex-skill-parity.ps1` (renamed from `test-claude-skill-parity.ps1`), `tests/test-handoff-shape.ps1` (new), `tests/test-guard-hardcoded-rules.ps1` (new).
- `specs/001-spec-superpowers-bridge` through `specs/005-marketplace-alignment` are byte-identical to their pre-trim state (verified by checksum `1f09423e4e91ec5b9edb396b7c7f2fe4a0a2a56a`).
- PowerShell line surface: 2,984 → 376 (~87.4% reduction across the retained 3 scripts + 1 helper).

## [0.2.0] - 2026-05-15

### Added

- `LICENSE` at repo root (MIT) for upstream catalog submission completeness.
- `marketplace/` directory holding the upstream-PR-ready artifacts: `catalog-entry.json`, `extensions-readme-row.md`, `upstream-pr-body.md`, plus a directory `README.md` explaining their use. Excluded from distribution per `plugin-distribution-manifest.yml`.
- `submission-checklist.ps1` script + `tests/test-submission-checklist.ps1`: mirrors the Spec Kit maintainers' upstream verification (manifest schema, file presence, URL HTTP 200, tag set, semver shape, description length, AI-disclosure presence). Exit 0 = submission-ready.
- `cleanup-audit.ps1` script + `tests/test-cleanup-audit.ps1`: surfaces stale source-repo files (`*.bak`, unreferenced `docs/`, abandoned one-shot scripts, `.gitignore` gaps, distribution manifest inconsistencies). Includes an opt-in `-Fix` mode.
- `docs/release-runbook.md`: 11-step release procedure with explicit `Verify:` lines for every step.
- README badges (4): license, latest release, last commit, Spec Kit compatibility.
- README sections covering pure-Codex / pure-Claude / dual-agent install paths, "first feature in 10 minutes" walkthrough, troubleshooting matrix, maintenance & versioning, and Architecture-in-60-seconds (paraphrasing the [dev.to comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) with attribution).
- Peer-extension comparison paragraph naming AIDE, architect-preview, api-contract-evolution, impact-predictor.
- Two new bridge meta-commands: `speckit.speckit-superpowers-bridge.submission-checklist`, `speckit.speckit-superpowers-bridge.cleanup-audit` (both `COMBINE` in the disposition matrix).

### Changed

- `extension.yml.version` bumped to `0.2.0`.
- `extension.yml.tags` replaced with the locked 6-tag set (`bridge, superpowers, cross-agent, governance, tdd, workflow`) per feature 005 clarify Q3.
- `verified-versions.json.verified_at` refreshed to 2026-05-15T19:00:00Z.
- `README.md` reflowed to the 11-section structure optimized for first-time readers (bilingual toggle → badges → value prop → workflow diagram → install paths → walkthrough → commands → configuration → troubleshooting → maintenance → architecture → contributing).
- `README.zh-CN.md` mirror-reflowed to identical H2 structure; bilingual parity check exits 0.
- `.gitignore` re-audited and grouped by category (per-developer state, OS junk, backup patterns, editor scratch, build artifacts).
- `plugin-distribution-manifest.yml` re-confirmed: `LICENSE`, `CHANGELOG.md`, `docs/release-runbook.md` in includes; `marketplace/**` added to excludes with reason.

### Fixed

- `extension.yml.tags` was 4 generic terms (`superpowers, implementation, handoff, bridge`); now matches the discoverability-tuned 6-tag set chosen via feature 005's clarify.

## [0.1.1] - 2026-05-15

### Added

- Bridge handoff schema v3: `autonomous_mode` + `resume_context` fields.
- Bridge meta-commands `speckit.speckit-superpowers-bridge.audit`, `.validate`, `.parity`, `.recommend-route`, `.execute` with corresponding scripts (`audit-install-state.ps1`, `validation-pass.ps1`, `parity-check.ps1`, `recommend-route.ps1`).
- Five mirrored `.claude/skills/speckit-git-*/SKILL.md` for cross-agent parity (`speckit-git-commit`, `-feature`, `-initialize`, `-remote`, `-validate`).
- Bilingual README scaffold (`README.md` + `README.zh-CN.md`) with structural parity check.
- `plugin-distribution-manifest.yml` declaring marketplace includes/excludes.
- 8 smoke test suites under `tests/`.
- `disposition-matrix.json` (31 entries) classifying every Spec Kit command + Superpowers skill as COMBINE / FORBID-UNDER-HANDOFF / SUPERSEDED-BY / REVIEW-ONLY.
- `verified-versions.json` pinning Spec Kit and Superpowers skill-pack versions.

### Changed

- Bridge `SKILL.md` on both Codex and Claude rewritten to issue explicit `Skill` tool / `$skill-name` invocations at named lifecycle phases.
- Actor resolution rewritten to a 4-step chain: explicit `-Actor` argument → `SPECKIT_BRIDGE_ACTOR` env var → `.specify/integration.json.default_integration` → `unknown`. Hard-coded `-Actor codex` defaults removed.
- Bridge extension commands moved to the official namespace `speckit.speckit-superpowers-bridge.*`.

### Fixed

- **CG-006**: Handoff command no longer hardcodes `-Actor codex`; correct actor resolved per the chain.
- **CG-003**: A `complete` handoff for one feature no longer blocks contract changes on a different feature (auto-archive path + cross-feature guard exemption added).
- **CG-004**: First-touch artifact-ownership claim now happens automatically via the auto-archive helper.

## [0.1.0] - 2026-05-15

### Added

- Initial bridge protocol with handoff state file (`.specify/superpowers-handoff.json`), guard rules (`guard-command.ps1`), audit logging (`bridge-events.jsonl`), rollback snapshots (`bridge-snapshots/`).
- Codex (`.agents/skills/speckit-superpowers-bridge/SKILL.md`) and Claude Code (`.claude/skills/speckit-superpowers-bridge/SKILL.md`) bridge skills.
- Local validation scripts: `update-handoff.ps1`, `restore-snapshot.ps1`, `test-bridge-guard.ps1`.
- AGENTS.md as the master cross-agent protocol; CLAUDE.md as the Claude-specific supplement.
- Constitution (`.specify/memory/constitution.md`) ratifying 5 principles: lightweight & repo-local, design/implementation separation, agent-neutral protocol, smooth bidirectional handoff, vendor-managed boundaries.

[Unreleased]: https://github.com/lihan3238/speckit-superpowers-bridge/compare/v0.4.3...HEAD
[0.5.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.5.0
[0.4.3]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.3
[0.4.2]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.2
[0.4.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.1
[0.4.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.0
[0.3.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.3.1
[0.3.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.3.0
[0.2.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.2.0
[0.1.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.1
[0.1.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.0
