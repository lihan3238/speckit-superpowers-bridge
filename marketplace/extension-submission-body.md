# Extension Submission: Superpowers Implementation Bridge

### Extension ID

speckit-superpowers-bridge

### Extension Name

Superpowers Implementation Bridge

### Version

0.7.1

### Description

Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.

### Author

lihan3238

### Repository URL

https://github.com/lihan3238/speckit-superpowers-bridge

### Download URL

https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip

(Version-pinned alternative for reproducible installs:)

https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.7.1/speckit-superpowers-bridge-v0.7.1.zip

> **Note for catalog maintainers**: as of v0.6.0 the canonical `download_url` is the GitHub `/releases/latest/download/` stable-alias (above). Every release tag attaches BOTH the versioned and the stable-aliased asset. The decoupling means the catalog `download_url` does NOT need editing on future bridge releases — only the `version` field bumps for audit trail.

### License

MIT

### Homepage (optional)

https://github.com/lihan3238/speckit-superpowers-bridge

### Documentation URL (optional)

https://github.com/lihan3238/speckit-superpowers-bridge#readme

### Changelog URL (optional)

https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/CHANGELOG.md

### Required Spec Kit Version

>=0.8.10

(Verified compatibility for v0.7.1: Spec Kit `0.9.1`. The floor stays at `>=0.8.10` — Spec Kit v0.9.x's `agent-context` migration affects project bootstrap state, not the bridge extension runtime.)

### Required Tools (optional)

- PowerShell `>=5.1` for the Windows runtime flavor.
- Bash `>=4.0` and `jq >=1.6` for the Linux/macOS runtime flavor.
- `sha256sum` (GNU coreutils 8+, ubiquitous on WSL/Linux/macOS) for the new v0.7.0 hash-snapshot logic; Windows uses PowerShell's built-in `Get-FileHash -Algorithm SHA256` — no extra install.
- Superpowers `v5.1.0` skills in the active agent runtime when users want Superpowers implementation discipline.
- Codex and Claude Code are both supported; Spec Kit renders the generated commands into each integration's native command style.

### Number of Commands

3

### Number of Hooks (optional)

5

### Tags

bridge, superpowers, cross-agent, tdd, workflow

### Key Features

- Keeps Spec Kit as the design source of truth: constitution, spec, clarify, plan, tasks, checklists, and analyze stay Spec Kit-owned.
- Uses Superpowers as the implementation discipline: TDD, systematic debugging, executing plans, review, verification, and branch finishing stay native Superpowers capabilities.
- Adds a thin handoff/guard layer so the two systems do not duplicate planning or execution ownership.
- Supports Windows, Linux, and macOS through one ZIP containing PowerShell and bash script flavors.
- Supports Codex, Claude Code, or both; the short entrypoint is `$speckit-superpowers-bridge` for Codex and `/speckit-superpowers-bridge` for Claude Code.
- **New in v0.7.1**: verified compatibility refreshed to Spec Kit `0.9.1`, with the source repo explicitly tracking Spec Kit's bundled `agent-context` extension and ignoring its generated agent skills. Bridge runtime is unchanged from v0.7.0.
- **New in v0.7.0** (US1): `bridge-status.{sh,ps1}` — read-only on-demand bridge state introspection. Prints the existing 5-field `[bridge state]` block plus a `Next:` command recommendation derived from a deterministic 12-rule decision table (no LLM call, no network — only file-existence checks). `--json` / `-Json` for machine-readable output. Designed for the "I was away — where am I in this feature?" recovery moment. Sub-second wall-clock on the reference WSL bash environment. Read-only: never writes the handoff, never appends to the event log.
- **New in v0.7.0** (US2): SHA256 artifact-drift detection on phase transitions. `update-handoff` snapshots SHA256 of `spec.md`/`plan.md`/`tasks.md` into an additive `artifacts_sha256` object on every `executing`/`complete` write. On `complete` writes that detect drift vs the prior snapshot, the script emits exactly one `[bridge] WARNING:` line to stderr AND appends exactly one `artifact_drift_detected` event to `bridge-events.jsonl` — exit code stays 0, transition is not blocked, drift is advisory. The new `bridge-status --json` surfaces drift passively via a `Drift:` line (read-only).
- **Carried from v0.6.0**: hero-led + bilingual README with a 5-badge row, `## Why` / `## Quick Start` / `## Positioning` sections above the fold, and 10 collapsed `<details>` sections — modelled on the rpamis/comet structural pattern using native Markdown + GitHub-flavored alerts only (no JS / CSS / build step). `verified-versions.json` at the bridge package root (now refreshed for v0.7.1). Marketplace `download_url` permanently decoupled from the version pin — only the catalog `version` field bumps per release.

### Testing Checklist

- [x] Extension installs successfully via download URL
- [x] All commands execute without errors
- [x] Documentation is complete and accurate
- [x] No security vulnerabilities identified
- [x] Tested on at least one real project

### Submission Requirements

- [x] Valid `extension.yml` manifest included
- [x] README.md with installation and usage instructions
- [x] LICENSE file included
- [x] GitHub release created with version tag
- [x] All command files exist and are properly formatted
- [x] Extension ID follows naming conventions (lowercase-with-hyphens)

### Testing Details

Tested on:

- WSL Ubuntu bash 5.x with Spec Kit `0.9.1`, Claude Code integration, Codex integration, bundled `agent-context`, and bash flavor (post-009 dev environment alignment — primary smoke surface).
- Windows PowerShell 5.1+ with Spec Kit `0.8.10+`, Codex integration, and PowerShell flavor (functional parity by inspection plus the v0.7.0 PowerShell precedence bug fixed at `bridge-state.ps1:228` per code review, commit `22d5190`).
- Superpowers release baseline `v5.1.0` (grep-verified clean against v5.1.0's removed slash commands and removed `superpowers:code-reviewer` named agent — bridge invokes by skill name only).

Release validation:

- `specify --version` -> `specify 0.9.1` (maintainer dev environment, installed from `github/spec-kit` tag `v0.9.1`); floor `>=0.8.10` carried forward.
- v0.7.1 release ZIP published: both `speckit-superpowers-bridge-v0.7.1.zip` and the stable-aliased `speckit-superpowers-bridge.zip` (same content; SHA256 recorded in the release workflow summary).
- `bash tests/run-all.sh` -> all 5 smoke tests pass on WSL bash, including the new `tests/test-bridge-status.sh` (26 cases: all 14 decision-table vectors V1..V14 + 5 US1 acceptance scenarios + 5 US2 scenarios + SC-003 byte-identical idempotency check + 6 edge cases).
- Version triplet consistency: `extension.yml.extension.version == catalog-entry.json.version == verified-versions.json.bridge_version == "0.7.1"`.
- `jq -e '.verified_at and .spec_kit_version and .superpowers_version and .bridge_version and .notes' .specify/extensions/speckit-superpowers-bridge/verified-versions.json` -> exit 0 (5-field schema validates).
- SC-010 lightness-budget audit (all 9 sub-checks PASS): `bridge-status.sh` 173 lines (≤200); `bridge-status.ps1` 191 lines (≤200); `update-handoff.sh` delta +48 (≤60); `update-handoff.ps1` delta +47 (≤60); exactly 1 new event type (`artifact_drift_detected`); 4 new files in bridge package (2 helpers + 1 test + 1 fixture); 0 new state files; 0 new commands/hooks at the slash/extension layer; 0 edits to vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` (only the project-owned `speckit-superpowers-bridge` SKILL.md peers gained the FR-011 one-line documentation reference).
- SC-008 (no regression in 008-era `[bridge state]` print contract): existing 4 smoke tests stay green after v0.7.0 changes.
- Constitution VI Native-First gate: Q1 ("does upstream do this?") = no for both pillars (no equivalent introspector for the bridge's project-local handoff JSON; no equivalent artifact-hash mechanism in upstream Spec Kit/Superpowers); Q2 ("is upstream the right place to fix this?") = no for both. New surface justified as local-owned extension of the bridge's existing protocol.

Fresh install smoke (end-user verification sandbox — see [`specs/012-bridge-status-and-hash/verification.md`](https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/specs/012-bridge-status-and-hash/verification.md)):

- WSL bash + Claude: installed from the v0.7.0 stable-alias URL in `..\test_specify_superpower`; drove cycle `(no handoff) → ready → executing (artifacts_sha256 populated) → inject drift in tasks.md → bridge-status shows Drift: tasks.md → complete → stderr [bridge] WARNING + artifact_drift_detected event appended`. Exit code 0 throughout. Existing 008-era pending-tasks warning still fires alongside the new drift warning (SC-008 confirmed).
- Coverage: 3 US1 + 4 US2 + 2 cross-cutting scenarios — well above SC-007's "at least one passing per story" floor.
- ZIP structure: `extension.yml` at archive root; `commands/`, `scripts/powershell/`, `scripts/bash/` (with new `bridge-status.sh`), and the refreshed `verified-versions.json` at archive root all use portable `/` separators.

Backward compatibility (FR-013 / SC-009):

- Pre-0.7.0 handoffs (without the `artifacts_sha256` field) read cleanly under v0.7.0+ tooling. `bridge-status` omits the `Drift:` line; `update-handoff` does NOT emit a false-positive drift warning on the first `complete` write under v0.7.0+ (there is no prior snapshot to compare against). The next `executing` write populates the field. No migration script required. Verified live by transitioning this repo's own pre-0.7.0 handoff to `complete` under v0.7.0+ tooling — `artifacts_sha256` populated, no false-positive event emitted.

### Example Usage

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip

$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-tasks
$speckit-superpowers-bridge

# New in v0.7.0 — read-only state introspection on demand:
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
# or on Windows:
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\bridge-status.ps1
```

Claude Code users run the same flow with slash commands:

```text
/speckit-specify
/speckit-clarify
/speckit-plan
/speckit-tasks
/speckit-superpowers-bridge
```

### Proposed Catalog Entry

```json
{
  "name": "Superpowers Implementation Bridge",
  "id": "speckit-superpowers-bridge",
  "description": "Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.",
  "author": "lihan3238",
  "version": "0.7.1",
  "download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip",
  "repository": "https://github.com/lihan3238/speckit-superpowers-bridge",
  "homepage": "https://github.com/lihan3238/speckit-superpowers-bridge",
  "documentation": "https://github.com/lihan3238/speckit-superpowers-bridge#readme",
  "changelog": "https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/CHANGELOG.md",
  "license": "MIT",
  "requires": {
    "speckit_version": ">=0.8.10",
    "tools": [
      { "name": "powershell", "version": ">=5.1", "required": false },
      { "name": "bash", "version": ">=4.0", "required": false },
      { "name": "jq", "version": ">=1.6", "required": false }
    ]
  },
  "provides": {
    "commands": 3,
    "hooks": 5
  },
  "tags": ["bridge", "superpowers", "cross-agent", "tdd", "workflow"],
  "verified": false,
  "downloads": 0,
  "stars": 0,
  "created_at": "2026-05-16T00:00:00Z",
  "updated_at": "<filled-by-maintainer-on-merge>"
}
```

### Additional Context

This is the **v0.7.1 patch update** for the already accepted `speckit-superpowers-bridge` community catalog entry. Prior upstream issue history (audited via GitHub search): initial listing accepted via #2575 / #2581 (closed); v0.4.3 update via #2599 / #2600 (closed); v0.5.0 update via #2601 (closed). This patch refreshes the verified Spec Kit pair from `0.8.16` to `0.9.1` and aligns release tooling; bridge runtime behavior is unchanged from v0.7.0.

**Catalog edit requested in this issue:**

1. Bump `version` to `0.7.1`. Leave `download_url` unchanged at the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias URL.

**What's new in v0.7.0** (two pillars borrowed from [rpamis/comet](https://github.com/rpamis/comet)'s design and adapted to this bridge's Native-First discipline):

1. **`bridge-status.{sh,ps1}`** — on-demand bridge state introspection. Reads the local `superpowers-handoff.json`, prints the existing 5-field `[bridge state]` block plus optional `Drift:` line + `Next:` recommendation. Solves the "I was away for a day — where am I?" recovery problem in one sub-second command, without needing to spawn a guard check or write the handoff just for the side-effect of the printout.
2. **`artifacts_sha256` + `artifact_drift_detected` event** — handoff artifact integrity. Adds an additive optional `artifacts_sha256` object on the handoff JSON. `update-handoff` snapshots SHA256 of `spec.md`/`plan.md`/`tasks.md` on every `executing`/`complete` write. On `complete` writes that detect drift vs the prior snapshot, emits one stderr `[bridge] WARNING:` + one `artifact_drift_detected` event. Exit code stays 0 — drift is advisory, not blocking; the operator decides whether to abort or roll back.

**What's carried from v0.6.0** (documentation + metadata, no breaking surface):

- Hero-led + bilingual README modelled on the rpamis/comet structural pattern (5-badge row, `## Why` / `## Quick Start` / `## Positioning` above the fold, 10 `<details>`-collapsed sections). Native Markdown + GFM alerts only — no JS / CSS / build step.
- `verified-versions.json` artifact at the bridge package root (5-field locked schema; refreshed for v0.7.1).
- The `download_url` decoupling (edit #2 above).

The bridge combines Spec Kit and Superpowers by keeping their responsibilities separate:

- **Spec Kit owns WHAT**: constitution, spec, clarify, plan, tasks, checklists, and analysis remain the durable design artifacts.
- **Superpowers owns HOW**: TDD, systematic debugging, executing plans, code review, verification, and finishing the development branch remain native Superpowers implementation discipline.
- **The bridge only orchestrates**: it writes the handoff JSON, enforces five boundary guard rules, appends event logs/snapshots, and exposes generated command skills for Codex and Claude Code.
- **No overlap, no replacement**: the extension does not run `speckit.implement`, does not create a second planning system, does not edit the global Superpowers cache, and does not implement custom execution discipline.

v0.7.0 is a **thin behavioral-additive** release: SC-010 lightness-budget audit (9 sub-checks) all PASS — bridge-status helpers ≤200 lines each; update-handoff deltas ≤60 added lines each; 4 new files total (2 helpers + 1 test + 1 fixture); 0 new state files; 0 new commands at the slash/extension layer; 0 edits to vendor-managed Spec Kit skills. The 5 hardcoded guard rules in `guard-command.{sh,ps1}` are **byte-frozen** vs v0.5.0. The existing 008-era `[bridge state]` print contract is preserved verbatim for `update-handoff` and `guard-command` callers; the new `Drift:` and `Next:` lines are emitted only by the new `bridge-status` caller. v1 handoff schema's `schema_version` field stays at `1` (additive via the existing `additionalProperties: true` extension point).

Design direction still follows [Spec Kit vs Superpowers - A Comprehensive Comparison & Practical Guide to Combining Both](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj): Spec Kit remains the source of truth for design; Superpowers executes the implementation discipline at the lifecycle phases the bridge dispatches. The two new v0.7.0 pillars are operational quality-of-life additions (state introspection + integrity audit) rather than new design surface.

### AI-Assistance Disclosure

Per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md), this extension was developed using AI coding assistants. Claude Code handled design and planning across the Spec Kit artifacts. Codex handled implementation and release-alignment passes in earlier features. The v0.7.0 feature (bridge-status + artifacts_sha256) was driven end-to-end by Claude Code (Opus 4.7) following the project's bridge protocol (specify → plan → tasks → bridge → executing-plans → verification-before-completion → requesting-code-review → finishing-a-development-branch → sandbox verification → complete), with code review surfacing one real PowerShell operator-precedence bug fixed in commit `22d5190`. Every artifact passes human review before commit.
