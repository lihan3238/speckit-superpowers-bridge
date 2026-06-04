# Data Model: v1.0.0 Stable Protocol Release Hardening

## Compatibility Baseline

**Purpose**: Records the upstream and bridge versions verified for the 1.0.0 release.

**Fields**:

- `verified_at`: UTC timestamp for the verification record.
- `bridge_version`: Expected to be `1.0.0`.
- `spec_kit_version`: Verified Spec Kit CLI version.
- `superpowers_version`: Verified Superpowers version.
- `codex_cli_version`: Verified Codex CLI version, or blocked status with reason.
- `claude_code_version`: Verified Claude Code version, or blocked status with reason.
- `platforms`: List of platform verification rows.
- `notes`: Human-readable compatibility notes and known caveats.

**Validation rules**:

- `bridge_version` must match the version in `extension.yml` and marketplace metadata.
- Each claimed tool verification must include exact version output and date.
- Blocked or unverified tools must not be described as verified in release notes.

**Relationships**:

- Summarizes Platform Verification Matrix and Agent Verification Record outcomes.
- Packaged in the release artifact through `verified-versions.json`.

## Platform Verification Matrix

**Purpose**: Establishes Windows and Linux as first-class release targets.

**Fields**:

- `platform`: `linux-bash` or `windows-powershell`.
- `environment`: Host details such as WSL, native Linux, or native Windows.
- `script_flavor`: `sh` or `ps`.
- `install_source`: Release URL, release-equivalent ZIP, or blocked reason.
- `artifact_sha256`: Hash of the package installed.
- `smoke_result`: Pass/fail result for in-repo platform smoke tests.
- `sandbox_result`: Pass/fail result for sandbox install and bridge cycle.
- `readiness_result`: Pass/fail result for readiness/status checks.
- `notes`: Platform-specific observations.

**Validation rules**:

- 1.0.0 completion requires one passing Linux bash row and one passing Windows PowerShell row.
- WSL bash can satisfy only the Linux bash row.
- A missing, blocked, or failed row blocks release completion.

**Relationships**:

- Contributes to Compatibility Baseline.
- Referenced by release runbook and verification evidence.

## Agent Verification Record

**Purpose**: Proves Codex and Claude Code can operate the bridge from their own user-facing surfaces.

**Fields**:

- `agent`: `codex` or `claude`.
- `version`: Exact CLI version output.
- `platform`: Platform used for the run.
- `sandbox_path`: Location of the end-user sandbox.
- `prompt_boundary`: Description of the bounded prompt and prohibited actions.
- `operations_exercised`: Status/readiness, guard, handoff, execute boundary, package install, or docs discovery.
- `result`: `pass`, `fail`, or `blocked`.
- `evidence_path`: Path to transcript, log, or summary.
- `manual_intervention`: Any user action needed during the run.

**Validation rules**:

- A release announcement may claim an agent only if its record is `pass`.
- Blocked records must include exact attempted command and failure reason.
- Agent runs must not modify this source repository outside intended verification evidence.

**Relationships**:

- Stored in feature verification evidence.
- Summarized in Compatibility Baseline.

## Readiness Report

**Purpose**: Gives users and maintainers an actionable install-health and current-state view.

**Fields**:

- `script_flavor`: Active shell flavor or detected flavor.
- `required_tools`: Tool availability and versions where relevant.
- `namespace_status`: Extension id, command namespace, hook command namespace, and catalog id alignment.
- `package_status`: Required files and script flavor presence.
- `bridge_state`: Current feature, handoff status, owner, actor, pending tasks, drift if available, and next action.
- `agent_status`: Codex/Claude availability when checked.
- `overall_status`: `ready`, `warning`, or `failed`.

**Validation rules**:

- Failed categories must name the failing item.
- Report must be read-only for user source files and bridge handoff state.
- Report must not create a new lifecycle state file.

**Relationships**:

- May be implemented through existing `bridge-status` and release readiness scripts.
- Referenced in quickstart and README documentation.

## Release Artifact

**Purpose**: The installable bridge ZIP published for users.

**Fields**:

- `versioned_zip`: Version-specific asset path or URL.
- `stable_alias_zip`: Stable latest alias asset path or URL.
- `sha256`: Hash of the versioned ZIP.
- `root_manifest`: `extension.yml` at archive root.
- `commands`: Bridge command files.
- `bash_scripts`: Bash script flavor files.
- `powershell_scripts`: PowerShell script flavor files.
- `docs`: README, Chinese README, changelog, license, and verified version evidence.

**Validation rules**:

- ZIP entries must use portable `/` separators.
- Required root manifest and both script flavors must be present.
- Versioned asset and stable alias must refer to the same release contents after publication.

**Relationships**:

- Installed into the sandbox for Platform Verification Matrix rows.
- Referenced by Catalog Submission Package.

## Catalog Submission Package

**Purpose**: Keeps upstream Spec Kit community catalog metadata aligned with the shipped bridge.

**Fields**:

- `catalog_entry`: Marketplace JSON payload.
- `readme_row`: Community extensions table row.
- `submission_body`: Issue/PR body.
- `version`: Must be `1.0.0`.
- `download_url`: Stable alias policy unless intentionally changed.
- `capability_counts`: Command and hook counts.
- `support_matrix`: Windows/Linux support claim.

**Validation rules**:

- Catalog id must match extension id.
- Version must match release artifact version.
- Download URL must follow the stable-alias policy documented by the project.

**Relationships**:

- Uses Release Artifact metadata.
- Summarizes Compatibility Baseline and documentation claims.

## Demo Evidence

**Purpose**: Ensures release visuals and transcripts reflect actual behavior.

**Fields**:

- `type`: GIF, transcript, screenshot, or illustrative asset.
- `source_run`: Sandbox or agent run used to produce it.
- `tooling`: Capture tools used, or missing-tool reason.
- `truth_label`: Real run, transcript-derived, or illustrative.
- `path`: Documentation asset path.

**Validation rules**:

- Assets derived from fake shell scripts must not be labelled as real agent output.
- If capture tools are missing, transcript evidence is acceptable and must be labelled.

**Relationships**:

- Referenced by README, demo docs, release notes, or verification evidence.

## Release Readiness State

**Purpose**: Tracks whether the feature is allowed to proceed to release tagging.

**States**:

- `draft`: Spec and plan are being prepared.
- `implemented`: Release tooling, docs, tests, and metadata are updated.
- `packaged`: Release-equivalent artifact exists and has a hash.
- `linux-verified`: Linux bash row passed.
- `windows-verified`: Windows PowerShell row passed.
- `agents-verified`: Codex and Claude rows passed or explicitly blocked without claimed verification.
- `ready-to-tag`: All mandatory gates passed.
- `published`: Tag and release assets exist.
- `catalog-submitted`: Upstream catalog submission prepared or opened.

**Validation rules**:

- `ready-to-tag` requires `packaged`, `linux-verified`, `windows-verified`, and required release workflow checks.
- `published` requires the stable alias asset to resolve.
- `catalog-submitted` may occur after `published`; upstream merge is outside repo control.
