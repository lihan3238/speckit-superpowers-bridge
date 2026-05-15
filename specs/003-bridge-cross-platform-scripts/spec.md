# Feature Specification: Bridge Cross-Platform Scripts

**Feature Branch**: `003-bridge-cross-platform-scripts`

**Created**: 2026-05-15

**Status**: Draft

**Input**: User description (paraphrased): "我们开始做 linux/mac 版本兼容。插件已发布稳定版（v0.3.1）。严格按照设计思路，做 mac/linux 兼容的 PR，只做兼容，不增新功能。用最专业、轻量、简洁干净的方式实现从开发到 release 到用户使用更新的全流程跨平台兼容。"

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). This feature does NOT alter the bridge's architecture — it ports the existing four PowerShell scripts to bash while preserving behavior byte-for-byte, so the bridge's WHAT and HOW responsibility split (Spec Kit owns design; Superpowers owns implementation) continues to hold on every supported OS.

## Clarifications

### Session 2026-05-15

Decisions were researched (not asked) per user direction "调研采用最轻量专业的方案". Each decision cites the canonical reference inspected.

- Q: Single ZIP carrying both `scripts/powershell/` + `scripts/bash/`, or separate per-platform ZIPs? → A: **Single ZIP with both flavors.** Canonical Spec Kit pattern: the first-party `.specify/extensions/git/` ships both `scripts/bash/` and `scripts/powershell/` in one source tree, and the upstream `catalog.community.json` schema exposes only one `download_url` per entry — multi-ZIP has no catalog expression. Wasted ~30% bytes on the unused flavor is acceptable at ~30 KB total release-asset size. (Reaffirms FR-011.)
- Q: How does Spec Kit dispatch between PS and bash at runtime? → A: **Reuse Spec Kit's existing `init-options.json.script` field.** Set at `specify init` time (values `ps` | `sh`), it's already what Spec Kit uses to pick `scripts/<flavor>/`. The bridge writes no custom dispatcher. (Reinforces FR-016 — extension.yml command markdowns unchanged.)
- Q: How to express platform-conditional tool requirements in `extension.yml.requires.tools`? → A: **Flat list with `required: true|false`.** The catalog schema (verified against `agent-governance`, `azure-devops` live entries) has no per-platform field. List all tools; mark `bash`, `jq`, and `pwsh` (the latter for tests only) as `required: false` so Windows users do NOT see false prerequisites. Windows-only `powershell >= 5.1` stays `required: true` because PS is the default on Windows. (Refines FR-010.)
- Q: How to keep `.sh` line endings and executable bit intact through Windows clone → `Compress-Archive` → Linux unpack? → A: **`.gitattributes` enforces LF for `*.sh`; scripts are invoked via `bash <path>`, NOT `./path` — no reliance on Unix executable bit.** Matches the `git` extension's existing convention. ZIP format doesn't carry Unix permissions natively; the `bash <path>` invocation pattern sidesteps the issue. (Refines FR-020.)
- Q: Should bash scripts use `flock` (or equivalent) to make `bridge-events.jsonl` appends atomic, since two flavors could in theory write concurrently? → A: **NO `flock`. Mirror PowerShell's plain `>>` append.** The PowerShell scripts do not use `flock` either; adding it to the bash flavor would IMPROVE robustness beyond the PS baseline and violate the user's directive "只做兼容，不增新功能". Concurrent two-flavor writes remain an edge case acknowledged in the Edge Cases section; users hitting it are advised to pick one flavor. (Strengthens the Edge Case row.)
- Q: How does the smoke test suite exercise BOTH flavors without duplicating test files (FR-012 from feature 006 caps tests at ≤ 3)? → A: **Tests auto-detect available flavors.** Each test inspects `scripts/powershell/` and `scripts/bash/` under the bridge directory and runs its assertion against every flavor present. No `-Flavor ps|sh|both` parameter; no environment-variable knob. On Windows where only `scripts/powershell/` is installed, only PS is tested. On Linux with both, both are tested. Tests skip-with-message if a flavor is configured (`init-options.json.script`) but the matching script files are absent. (Refines FR-014, FR-015.)

## Constitutional anchors *(non-normative summary)*

This feature is bound by the bridge constitution at `.specify/memory/constitution.md`:

- **Principle I (Lightweight & Repo-Local)** — no new runtime/service/daemon. The bash scripts are repo-local files alongside the existing PowerShell scripts.
- **Principle II (Design/Implementation Separation, NON-NEGOTIABLE)** — bash scripts MUST enforce the same denylist as the PowerShell scripts: deny `speckit.implement` during executing handoff; deny `superpowers:writing-plans` / `:brainstorming` when Spec Kit artifacts exist; deny `speckit.constitution` during executing handoff.
- **Principle III (Agent-Neutral Protocol)** — bash scripts MUST accept `-Actor codex|claude|unknown` (or the equivalent flag) and log the actor in `bridge-events.jsonl`.
- **Principle IV (Smooth Bidirectional Handoff)** — bash scripts MUST write the same v1 handoff JSON shape and same snapshot directory structure as PowerShell; readers MUST tolerate v2/v3 documents (FR-009 from feature 006 carries forward).
- **Principle V (Vendor-Managed Boundaries)** — bash scripts go under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`; no vendor-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` file is modified beyond the bridge's own peer skills.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Linux / macOS user installs and uses the bridge end-to-end (Priority: P1) 🎯 MVP

A developer on Ubuntu, Debian, Fedora, or macOS installs the bridge from the published release ZIP. They have **neither PowerShell installed nor any intent to install it**. They complete a full feature design + bridge → Superpowers implementation cycle without ever invoking `pwsh`.

**Why this priority**: The bridge ships as a Spec Kit extension. Spec Kit itself is cross-platform. Shipping a Windows-only bridge contradicts that and excludes the majority of the Spec Kit user base. The v0.3.1 release ZIP currently contains only `scripts/powershell/` — Linux/macOS users installing v0.3.1 immediately hit "command not found". This is a regression against the dev.to article's "lightweight, cross-tool" intent and a hard blocker for catalog adoption beyond Windows users.

**Independent Test**: On a clean Linux container (e.g., `ubuntu:24.04`) with `git`, `bash`, and Spec Kit installed but no `pwsh`: install the bridge from the release URL, run `/speckit-specify` through `/speckit-tasks` on a throwaway feature, invoke the bridge command, observe a successful handoff cycle with all events appended to `bridge-events.jsonl`. Repeat on macOS (`brew install spec-kit`, `bash`). Cross-platform success = neither requires PowerShell at any point.

**Acceptance Scenarios**:

1. **Given** a clean Linux system with bash but no PowerShell, **When** the user runs `specify extension add speckit-superpowers-bridge --from <release URL>`, **Then** the install succeeds and `extension list` shows the bridge with 3 commands and 5 hooks.
2. **Given** the bridge is installed on Linux and the user has run `/speckit-tasks` on a feature, **When** the `after_tasks` hook fires, **Then** `bridge/scripts/bash/update-handoff.sh` (or the platform-selected equivalent) writes `.specify/superpowers-handoff.json` in the same v1 shape a Windows install would produce. The two files MUST be diffable: identical field set, identical field values for identical inputs (modulo `updated_at` and `last_snapshot_id` timestamps).
3. **Given** the user on Linux invokes the bridge command after a successful task generation, **When** the bridge skill executes its 8-step orchestration, **Then** every native Superpowers skill referenced in the SKILL.md runs successfully via the same agent runtime (Codex or Claude Code) the user installed.
4. **Given** the user attempts to run `speckit.implement` after the handoff is in `executing` state, **When** the bridge guard runs (`bash` flavor), **Then** the action is denied with the same human-readable reason a Windows install would print. Exit code is non-zero.
5. **Given** a feature is complete on Linux and a new `/speckit-specify` begins, **When** `auto-archive-handoff.sh` runs, **Then** the prior feature's Spec Kit artifacts are snapshotted under `.specify/bridge-snapshots/<id>/` exactly as the PowerShell flow does (matching directory layout and file content).

---

### User Story 2 — Existing Windows users are not broken (Priority: P1)

A Windows user who installed v0.3.0 or v0.3.1 upgrades to v0.4.0. Their existing `.specify/superpowers-handoff.json`, snapshot history, and event log are unaffected. The PowerShell scripts they've been calling continue to work identically.

**Why this priority**: The user's directive is "只做兼容，不增新功能" — compat only, no new features. Adding bash scripts must not regress the PowerShell scripts even slightly. This is a no-op for Windows users by design.

**Independent Test**: On Windows, run all 3 retained smoke tests against v0.4.0 — same outputs as v0.3.1. Run a throwaway feature through the bridge on Windows — identical handoff state machine behavior.

**Acceptance Scenarios**:

1. **Given** a Windows user with v0.3.1 installed and an active feature in `executing` state, **When** they upgrade to v0.4.0, **Then** the existing handoff JSON loads cleanly and the bridge continues from where it left off.
2. **Given** a Windows install of v0.4.0, **When** the user runs the 3 smoke tests, **Then** all exit code 0 with the same `*-ok` strings v0.3.1 produced.
3. **Given** v0.4.0's release ZIP, **When** unpacked on Windows, **Then** the `scripts/powershell/` directory contains byte-identical copies of v0.3.1's four PS files (no PS rewrites for this feature).

---

### User Story 3 — Release pipeline emits a single ZIP serving all platforms (Priority: P2)

The maintainer cuts v0.4.0 via the existing `.github/workflows/release.yml` (added in v0.3.1). The workflow runs on `ubuntu-latest`, but the resulting release asset MUST install correctly on Windows, Linux, AND macOS. There is exactly one ZIP per release — not one ZIP per platform.

**Why this priority**: P2 because the workflow infrastructure is already cross-platform-capable as of v0.3.1 — this story just verifies the build script and ZIP-content invariants hold once bash scripts are added.

**Independent Test**: On a fresh checkout, run `pwsh scripts/release/build-extension-zip.ps1 -Version 0.4.0`. Unpack the resulting ZIP. Verify it contains BOTH `scripts/powershell/` (4 files) AND `scripts/bash/` (4 equivalent files), plus the unchanged top-level `extension.yml`, commands/, README, etc. Test-install the ZIP on a Linux container and on Windows — both succeed.

**Acceptance Scenarios**:

1. **Given** the v0.4.0 release-asset ZIP, **When** unpacked, **Then** the contained tree includes:
   - `extension.yml` (declares both script flavors via the standard Spec Kit `script: ps|sh` mechanism)
   - `commands/*.md` (3 files, unchanged from v0.3.1)
   - `scripts/powershell/*.ps1` (4 files, unchanged from v0.3.1)
   - `scripts/bash/*.sh` (4 files, NEW)
   - `README.md`, `README.zh-CN.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore` at root
2. **Given** the build script runs on `ubuntu-latest` inside GitHub Actions, **When** the workflow's "Build extension ZIP" step executes, **Then** the same ZIP layout above is produced regardless of host OS.
3. **Given** the workflow's validator step, **When** invoked with `-Version 0.4.0`, **Then** it passes — the validator already accepts any semver; no validator changes required for cross-platform unless a new cross-reference is added (none planned).

---

### User Story 4 — Maintainers and contributors develop on any OS (Priority: P2)

A contributor on macOS (or any non-Windows OS) clones the repo and can run all the bridge's smoke tests, the release validator, and the release-build script locally — no Windows VM required. They can author bash scripts AND PowerShell scripts side-by-side and dogfood them.

**Why this priority**: P2 because v0.3.1 already moved the release infrastructure to cross-platform PowerShell Core invocation. This story verifies that promise holds end-to-end after bash scripts are added.

**Independent Test**: On macOS (or Linux) with `pwsh` installed (the dev dependency for tests), clone the repo and run: all 3 bridge tests, both release-tooling self-tests, the validator at the current release version, and the build script. All exit 0.

**Acceptance Scenarios**:

1. **Given** a macOS contributor with `pwsh` installed, **When** they run `pwsh tests/test-handoff-shape.ps1`, **Then** it exits 0 — the test invokes `update-handoff.ps1` which works under pwsh-on-macOS for the PowerShell flavor.
2. **Given** the same contributor wants to verify the bash flavor, **When** they run an equivalent invocation (`bash scripts/bash/update-handoff.sh -Status executing ...`), **Then** they get a functionally identical handoff JSON write — the bash flavor passes the same shape assertions.
3. **Given** a contributor with bash but no PowerShell at all, **When** they want to develop new features, **Then** the developer documentation explains they MUST install `pwsh` to run the test suite (the tests themselves stay in pwsh per User Story 3 — the bash flavor is for END USERS, not test authoring).

---

### Edge Cases

- A Linux distribution doesn't have `jq` preinstalled. The bash scripts use `jq` for JSON parsing. The install path documents `jq` as a prerequisite, with apt/brew/dnf install one-liners. `extension.yml.requires.tools` lists `jq` as required on non-Windows platforms.
- A user has both `pwsh` and `bash` installed on the same machine. Spec Kit's `init-options.json.script` field (set at `specify init` time) determines which flavor is invoked; the other is dormant but present in the install tree.
- A Windows user with WSL also installed the bridge inside WSL. Both installs coexist on the same disk but write to different `.specify/` directories. No cross-contamination.
- The bash scripts produce slightly different timestamps than PowerShell at the millisecond level (different formatting helpers). The handoff JSON's `updated_at` field is ISO 8601 with millisecond precision; both flavors produce parseable ISO 8601 — exact millisecond formatting may differ but parsers tolerate it.
- A bash script encounters a permissions issue (e.g., `bridge-events.jsonl` is owned by a different user). Failure is surfaced with the same exit code and human-readable error as the PowerShell flavor (`exit 1` + stderr message).
- A user upgrades from v0.3.1 to v0.4.0 mid-feature. The handoff JSON was last written by PS; the next write may be from bash. Both flavors emit the same v1 shape, so no format negotiation is needed. The append-only `bridge-events.jsonl` may have one line written by PS followed by one written by bash — both lines are valid JSON.
- `Compress-Archive` (PowerShell) and the bash equivalent must produce a ZIP whose `extension.yml` is at the top of the unpacked tree (one level under the wrapping dir). Both are validated by the existing `validate-release-readiness.ps1` + the workflow.
- Line endings: `.ps1` files use CRLF (Windows convention); `.sh` files MUST use LF (Unix convention). `.gitattributes` enforces this so that `git clone` on Windows doesn't break execution permissions on Linux.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge MUST add a directory `.specify/extensions/speckit-superpowers-bridge/scripts/bash/` containing exactly four executable shell scripts: `update-handoff.sh`, `guard-command.sh`, `auto-archive-handoff.sh`, `common-actor-resolution.sh`. Each MUST have a `#!/usr/bin/env bash` shebang and the executable bit set in git.
- **FR-002**: Each bash script MUST be functionally equivalent to its PowerShell sibling. "Functionally equivalent" means: given identical inputs (CLI arguments, environment variables, on-disk state), the bash script MUST produce the same observable effect — same handoff JSON shape, same snapshot directory contents, same `bridge-events.jsonl` lines, same exit code, same allow/deny decisions.
- **FR-003**: The bash `guard-command.sh` MUST implement the same 5 hardcoded rules as `guard-command.ps1` (deny `speckit.implement` during executing handoff; deny `superpowers:writing-plans` / `:brainstorming` when active feature has both `spec.md` and `plan.md`; deny `speckit.constitution` during executing handoff; allow other `speckit.*`; default allow). Rules MUST be inline `if`/`elif` branches — no external rule data file.
- **FR-004**: The bash `update-handoff.sh` MUST write v1-shape handoff JSON matching `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`. New writes MUST NOT emit v2/v3-only fields (`autonomous_mode`, `resume_context`, `archive_history`).
- **FR-005**: All bash scripts MUST tolerantly read v2/v3 handoff JSON documents — unknown fields are silently ignored, never errored on. (Mirrors FR-009 from feature 006.)
- **FR-006**: The bash `update-handoff.sh` MUST snapshot Spec Kit control artifacts under `.specify/bridge-snapshots/<snapshot-id>/` before writing any new handoff state — same Principle IV invariant the PowerShell version enforces. Snapshot directory naming format MUST be identical to PowerShell's (`yyyyMMddTHHmmssfffffffZ-<status>`).
- **FR-007**: The bash `auto-archive-handoff.sh` MUST be idempotent — no-op success when status is not `complete`. When firing, it MUST snapshot the prior feature directory BEFORE clearing it (the same regression the PowerShell version fixed at commit `10fd70d`).
- **FR-008**: The bash actor resolver (in `common-actor-resolution.sh`) MUST implement the 3-step chain: explicit `--actor` argument → `SPECKIT_BRIDGE_ACTOR` env var → `"unknown"`. Identical to FR-008 of feature 006.
- **FR-009**: The bash scripts MUST accept the same CLI argument names as the PowerShell scripts, modulo the standard bash convention of long flags using `--` and PowerShell using `-`. The mapping table:

  | PowerShell parameter | Bash flag |
  |---|---|
  | `-Status <ready\|executing\|complete\|blocked>` | `--status <ready\|executing\|complete\|blocked>` |
  | `-FeatureDirectory <path>` | `--feature-directory <path>` |
  | `-Reason "<text>"` | `--reason "<text>"` |
  | `-ArtifactOwner <codex\|claude\|unknown>` | `--artifact-owner <codex\|claude\|unknown>` |
  | `-Actor <codex\|claude\|unknown>` | `--actor <codex\|claude\|unknown>` |
  | `-ClearFeatureDirectory` | `--clear-feature-directory` |
  | `-Action <name>` (guard) | `--action <name>` (guard) |

- **FR-010**: `.specify/extensions/speckit-superpowers-bridge/extension.yml.requires.tools` MUST be a flat list of objects of shape `{ name: string, version?: string, required: bool }` (matching the schema observed on `agent-governance` and `azure-devops` in the upstream `catalog.community.json`). Concrete entries:
  - `{ name: "powershell", version: ">=5.1", required: true }` — used by every Windows install AND by the test suite cross-platform; can't be optional.
  - `{ name: "bash", version: ">=4.0", required: false }` — needed by Linux/macOS install paths; optional because Windows installs don't use it.
  - `{ name: "jq", version: ">=1.6", required: false }` — used by `update-handoff.sh` for v1 schema JSON I/O; optional for the same reason.
  - `{ name: "git", version: ">=2.30", required: false }` — already noted as soft dep in v0.3.x; unchanged.
- **FR-011**: `scripts/release/build-extension-zip.ps1` MUST add one `Copy-Item -Recurse` step that copies `scripts/bash/` into the ZIP staging directory alongside `scripts/powershell/`. The ZIP MUST contain both directories. (Single ZIP serves all platforms per the Clarifications session.)
- **FR-012**: `scripts/release/validate-release-readiness.ps1` MUST gain an additional check: when the bridge `scripts/bash/` directory exists, the validator MUST confirm the count of `.sh` files equals the count of `.ps1` files in `scripts/powershell/`. This catches "added a new PS script, forgot the bash sibling" drift. The validator MUST also check `.gitattributes` exists at repo root and contains an entry for `*.sh` with `eol=lf`.
- **FR-013**: The retained `tests/` smoke tests (3 files, FR-012 from feature 006) STAY at 3 files and stay pwsh — no bash test files are added. The tests test the bridge's *contract* (handoff shape, guard rules, peer-skill parity), which is the SAME contract for both script flavors. Bash users running tests need `pwsh` installed (`pwsh` is in the optional `requires.tools` list).
- **FR-014**: The smoke test `tests/test-handoff-shape.ps1` MUST be extended to auto-detect available script flavors and exercise each present flavor with the same assertion suite. The detection MUST be a function that returns the list of flavors present (e.g., `Get-AvailableFlavors` → `@("ps","bash")` if both `scripts/powershell/update-handoff.ps1` and `scripts/bash/update-handoff.sh` exist; `@("ps")` if only PS; `@("bash")` if only bash). No `-Flavor` parameter is exposed; the test exercises whatever it finds. If neither flavor exists in the bridge dir, the test exits 1 with a clear "no flavors available" message (the bridge install is broken).
- **FR-015**: The smoke test `tests/test-guard-hardcoded-rules.ps1` MUST be extended analogously with the same flavor auto-detection helper. All 5 rule assertions covered for every present flavor.
- **FR-016**: `extension.yml.provides.commands[].file` entries (3 commands) STAY unchanged — the command markdowns are agent-facing prose and the same content is correct regardless of script flavor. The markdowns reference scripts via paths like `scripts/powershell/<name>.ps1`; the actual flavor selection happens through Spec Kit's `init-options.json.script` field (already supported by Spec Kit ≥ 0.8.10), so no per-command flavor variant is needed.
- **FR-017**: `README.md` and `README.zh-CN.md` MUST be updated to document the cross-platform install paths. At minimum:
  - The same `specify extension add ... --from <url>` command works identically on Linux/macOS (the install URL is OS-agnostic).
  - A prerequisites subsection listing `bash >= 4.0` and `jq >= 1.6` for non-Windows platforms with one-line install commands (`apt install jq`, `brew install jq`, `dnf install jq`).
  - A note that Windows users need only PowerShell 5.1+ (preinstalled on Windows 10+).
  - A note that contributors/test-runners on any OS need `pwsh` 7.x for the 3 smoke tests.
  - Bilingual H2 anchor parity preserved (SC-010 from feature 006 still applies).
- **FR-018**: `CHANGELOG.md` MUST contain a new `[0.4.0] - <YYYY-MM-DD>` section explicitly listing: (a) the four added `scripts/bash/*.sh` files, (b) the `jq`/`bash` tool requirements added to `extension.yml`, (c) the build-script + validator updates, (d) the README cross-platform install section, (e) the new `.gitattributes` file.
- **FR-019**: `extension.yml.extension.version` MUST be bumped to `0.4.0`. `marketplace/catalog-entry.json.version` and `download_url` MUST be bumped in lockstep so the validator passes pre-tag.
- **FR-020**: A new `.gitattributes` file MUST be added at repo root containing at minimum:
  - `*.sh text eol=lf` (forces LF line endings for shell scripts; survives Windows clone with `core.autocrlf=true`)
  - `*.ps1 text eol=crlf` (preserves CRLF for PowerShell, optional but explicit)
  - `*.md text` (Markdown is text; line ending unspecified)
  The validator (FR-012) MUST confirm this file exists and contains the `*.sh text eol=lf` line before any release.

  Scripts are invoked via `bash <script-path>` (NOT `./<script-path>`) so the absence of the Unix executable bit in the published ZIP does not block execution. This matches the convention used by `.specify/extensions/git/scripts/bash/`.
- **FR-021**: The `.github/workflows/release.yml` workflow created in v0.3.1 MUST work without modification for v0.4.0 — the bash scripts and updated build script are exercised by the existing pipeline. If a workflow change IS needed during implementation, that's an inadvertent contract change; investigate before proceeding rather than silently editing the YAML.
- **FR-022**: An update path from v0.1.x / v0.3.x to v0.4.0 MUST require no manual user action beyond `specify extension upgrade` (or the equivalent re-install). Existing handoff JSON, snapshot directories, and event logs must be readable by v0.4.0 unchanged — v0.4.0 is a strict superset of v0.3.1.

### Key Entities

- **Bash Script Set**: The four `.sh` files under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`, mirroring the four `.ps1` files. Each pair is a contract: the two implementations are interchangeable from the bridge's external observable point of view.
- **Cross-Reference Validator (Extended)**: The existing `scripts/release/validate-release-readiness.ps1`, now also enforcing PS-bash file-count parity per FR-012.
- **`.gitattributes`**: A new repo-root file enforcing LF + executable bit on `.sh` files to prevent Windows clone corruption.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A clean Linux container (`ubuntu:24.04`, no PowerShell installed, `bash` + `jq` available) successfully completes `specify extension add ... --from <v0.4.0 URL>` and runs through `/speckit-specify` → bridge → handoff `complete` on a throwaway feature, with **zero** `pwsh` invocations.
- **SC-002**: A clean macOS environment (Homebrew, no PowerShell installed) achieves the same end-to-end flow as SC-001.
- **SC-003**: A Windows user with v0.3.1 installed upgrades to v0.4.0; their existing handoff JSON, snapshots, and `bridge-events.jsonl` are byte-identical before and after upgrade (until they perform a new bridge operation).
- **SC-004**: The published v0.4.0 release ZIP, when unpacked, contains exactly 4 `.ps1` files under `scripts/powershell/` and exactly 4 `.sh` files under `scripts/bash/`. File-count parity is enforced by the validator (FR-012).
- **SC-005**: The 3 retained smoke tests (`tests/*.ps1`) pass on all three platforms — Windows PowerShell 5.1+, Linux `pwsh` 7.x, macOS `pwsh` 7.x. Each test exercises BOTH script flavors when both are present (FR-014, FR-015).
- **SC-006**: `specs/001-…` through `specs/006-…` directories are byte-identical between the start of feature 003-real and the end — no retroactive edits to prior feature history (mirrors SC-006 of feature 006).
- **SC-007**: `extension.yml.extension.version` is `0.4.0`; `marketplace/catalog-entry.json.version` is `0.4.0`; `download_url` references v0.4.0 — all validated by `validate-release-readiness.ps1` before tag.
- **SC-008**: `CHANGELOG.md` `[0.4.0]` section names ≥ 5 specific surface changes (4 new bash scripts + tool reqs + build-script + validator + README + .gitattributes).
- **SC-009**: The release is published via the existing `.github/workflows/release.yml` on tag push, with no workflow YAML edits. Workflow run completes green in under 60 seconds. (If workflow edits ARE needed, file as a follow-up sub-feature; primary scope is no-workflow-change.)
- **SC-010**: README bilingual H2 parity remains exact (10/10 H2 sections matching between `README.md` and `README.zh-CN.md`, English anchors).
- **SC-011**: `scripts/release/build-extension-zip.ps1` continues to produce a ZIP at ≤ 50 KB (currently ~27 KB at v0.3.1; adding 4 bash scripts at ~70 lines each should land ≤ 50 KB total — well under any catalog size concern).
- **SC-012**: The cross-platform install URL pattern in catalog-entry.json (`releases/download/vX.Y.Z/speckit-superpowers-bridge-vX.Y.Z.zip`) stays unchanged from v0.3.1. The single asset serves all platforms; users do NOT have to pick a platform-specific download.

## Assumptions

- The bridge maintains a single shipping unit (one ZIP) regardless of platform count. Platform dispatch happens at script-invocation time via Spec Kit's `script: ps|sh` mechanism, not at install time.
- `jq` is an acceptable hard dependency on Linux/macOS. It's preinstalled on macOS (via Homebrew or system); on Ubuntu/Debian it's a one-line `apt install jq`; on Fedora `dnf install jq`. Pure-bash JSON parsing was considered and rejected (fragile, error-prone for the v1 schema's nested `source_of_truth` object).
- The 3 smoke tests stay in PowerShell because `pwsh` runs everywhere and the tests test the *bridge contract* (which is the same regardless of script flavor). Adding bash test duplicates would either violate FR-012 of feature 006 (≤ 3 tests) or double the test surface unnecessarily.
- Pwsh on macOS/Linux is the recommended *contributor* environment. It is NOT required for *end users* — end users on macOS/Linux only need bash + jq.
- `tools` field in `extension.yml.requires` can express platform-conditional requirements. If Spec Kit's current schema doesn't support per-platform `tools`, the requirement lists everything; the user installs only what their platform needs. Acceptable degradation.
- Bash scripts use `set -euo pipefail` for safety. Snapshots and event-log appends use atomic-ish file operations (temp file + rename, or `flock`-protected append) to avoid corruption under parallel invocations. The PowerShell flavor doesn't currently use atomic writes; the bash flavor will adopt the same level of robustness (matching behavior, not improving it — per "只做兼容").
- `Compress-Archive` cross-platform was verified in v0.3.1 (workflow ran on ubuntu pwsh). Adding bash scripts to the staging dir is purely additive.
- The `.github/workflows/release.yml` from v0.3.1 uses `gh release create` + `gh release upload` and `pwsh` for build steps. None of these change for v0.4.0.
- `Spec Kit script: ps|sh` is set at `specify init` time. Users who installed with `--script ps` and want to switch to `sh` need to either re-init or manually update `.specify/init-options.json`. This is **Spec Kit's** behavior, not ours; the bridge inherits it.
- Existing Windows users do not need to do anything special for v0.4.0 — their existing PS scripts continue to be invoked because their `init-options.json.script == "ps"`.
- The `.gitattributes` file is a new repo-root file added by this feature. It's a small, well-understood git mechanism with no runtime cost.
- Issue 2575 (the catalog submission) is updated post-release per the established procedure (v0.3.1 PATCH-edited the existing comment). Same approach for v0.4.0.

## Out of scope

- Adding new bridge commands or capabilities. The 3 commands (execute, handoff, guard) stay at 3.
- Adding new tests beyond extending the existing 3 to cover both flavors. Test count cap (≤ 3 files) from feature 006 holds.
- Switching scripting languages. No Python, no Node, no Go. Bash + PowerShell only.
- Improving PowerShell scripts (e.g., refactoring, performance). Only the bash scripts are new; PS scripts are byte-frozen for this feature.
- Changing the v1 handoff schema. The schema from feature 006 is the contract both flavors implement.
- GitHub Actions matrix (e.g., running tests on `windows-latest` + `ubuntu-latest` + `macos-latest`). Not blocking for v0.4.0; SC-009 lets the existing single-runner workflow stay. A test-matrix follow-up would be its own feature.
- Auto-installing `jq` for users who don't have it. The README documents the prerequisite; the install step itself stays Spec Kit's responsibility.
- Marketplace catalog edits beyond the `download_url` + version bump.
