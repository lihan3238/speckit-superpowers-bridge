# Data Model: Bridge Cross-Platform Scripts — Cleanup Tail

**Feature**: 003-bridge-cross-platform-scripts (v0.4.2 cycle)
**Date**: 2026-05-16

This feature adds zero new runtime entities. All existing entities from feature 003 v0.4.0 (Handoff State v1, Bridge Event, Snapshot Directory, install-time registries) carry forward unchanged. This document captures the **two design-time entities** the cleanup tail introduces, plus a clarification of the precedence chain B1 restores in the existing Handoff State entity.

---

## Entity A: Artifact Owner Precedence Chain (CLARIFIES Handoff State semantics)

The Handoff State entity from feature 006 §1 (file `.specify/superpowers-handoff.json`) has an `artifact_owner` field. The v0.4.x cycle broke its preservation discipline. The B1 fix restores a 4-step precedence chain that MUST hold for both `update-handoff.ps1` and `update-handoff.sh`.

### Resolution rules

```text
GIVEN inputs: $ARTIFACT_OWNER (explicit CLI flag), prior file's artifact_owner, $ACTOR (resolved)

artifact_owner =
    if $ARTIFACT_OWNER is non-empty:       $ARTIFACT_OWNER   (step 1: explicit override)
    elif prior file value is non-empty:    prior value       (step 2: silent preservation)  ← THE FIX
    elif $ACTOR in {codex, claude}:        $ACTOR            (step 3: actor fallback)
    else:                                  "unknown"         (step 4: literal default)
```

### Validation rules

- Final resolved `artifact_owner` MUST be one of `{codex, claude, unknown}` (matches the v1 handoff schema enum).
- Step 2 (preservation) MUST be silent — no warning, no log line at the script level. The audit trail in `bridge-events.jsonl` records the final value, which is sufficient.
- Step 2 reading MUST tolerate older v2/v3 documents (the field name is the same — no schema risk).

### Trade-offs accepted

- A user who legitimately wants to change `artifact_owner` mid-feature MUST pass `-ArtifactOwner` / `--artifact-owner` explicitly. Worsens discoverability slightly; documented in spec Edge Cases.
- Per spec FR-002, fixing the currently-poisoned live state requires a one-shot `-ArtifactOwner claude` invocation; the script does NOT auto-correct retroactively.

---

## Entity B: Verification Record (NEW)

**File**: `specs/003-bridge-cross-platform-scripts/verification.md`
**Owner**: This feature creates it; future releases append rows per the constitution v1.2.0 gate.
**Reader**: Humans during review; future contributors verifying the gate's history.

### Fields (per row)

| Field | Type | Required | Description |
|---|---|---|---|
| `version` | string | yes | Release tag verified (e.g., `v0.4.2`). Matches `gh release list` output. |
| `platform` | enum | yes | One of `windows-powershell`, `wsl-linux-bash`, `linux-native-bash`, `macos-bash`. |
| `bridge_sha256` | string (lowercase hex) | yes | SHA256 of the published release asset ZIP exercised. MUST match the workflow run's reported hash. |
| `date_utc` | ISO 8601 date | yes | Day of the run, UTC. |
| `operator` | enum | yes | `claude` / `codex` / `human`. Who ran the verification. |
| `result` | enum | yes | `PASS` / `FAIL` / `PENDING` / `SKIPPED`. `PENDING` for platforms without hardware (e.g., macOS in v0.4.2); `SKIPPED` for explicit out-of-scope. |
| `notes` | free-text | no | Observed gaps, install-time messages, or follow-up items. ≤ 200 chars. |

### Structure on disk

Single markdown file with one `## <version>` H2 section per release verified. Inside each section, a markdown table with one row per platform attempt. Example:

```markdown
# Verification Records

## v0.4.2

| Platform | bridge_sha256 | Date | Operator | Result | Notes |
|---|---|---|---|---|---|
| windows-powershell | abc123… | 2026-05-16 | claude | PASS | full cycle clean |
| wsl-linux-bash | abc123… | 2026-05-16 | claude | PASS | jq pre-installed, no friction |
| macos-bash | abc123… | — | — | PENDING | no host hardware available |
```

### Validation rules

- Every release that ships an artifact MUST add a `## <version>` section. Enforced by spec convention; no automated validator (yet).
- `bridge_sha256` per row MUST match what `gh release view <tag> --json assets` reports (or `Get-FileHash` of a freshly downloaded asset). Mismatch = either re-built ZIP after upload (forbidden — non-deterministic Compress-Archive per [[speckit-extension-release-strategy]]) or wrong asset cited.
- A release with `FAIL` on any required platform (per spec FR-008 — Windows + WSL Linux are required for v0.4.2) MUST have the handoff blocked.
- `PENDING` rows for macOS in v0.4.2 are acceptable per Clarifications Q3.

### Trade-offs accepted

- No JSON Schema for verification.md (it's markdown). A future feature COULD add a validator script if records start drifting; for now the constitution gate is human-procedural.
- The file grows linearly with releases (one section per release). At 10 releases that's still < 200 lines — no scaling concern.

---

## Entity C: Cross-Platform Bash Path Translation Strategy (NEW, test-only)

**Lives in**: Inline in `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` (duplicated per the inline-helper precedent from feature 003 v0.4.0).
**Type**: A small algorithm; not a persistent runtime entity. Pinned here for cross-reference with bash-cli-contract.md.

### Algorithm

Implemented as the `Convert-ToBashPath` function rewrite (research.md §R2). Strategy chain:

```text
INPUT: $path (raw, Windows-style or Unix-style)
OUTPUT: a bash-reachable path string, OR a "skip with reason" decision

1. Try `cygpath -u` via bash subshell → if exit 0 AND output non-empty → use output
2. Else if path matches /mnt/<drive>/... → use as-is (already WSL form)
3. Else if path matches <Drive>:<sep>... → translate to /<drive-lower>/... (MSYS shorthand fallback)
4. Else → use path verbatim with `\` → `/` normalization (Linux/macOS native)

POST-VERIFICATION: `bash -c "[ -f '<translated>' ] && echo OK"` → must print OK; else skip bash branch with reason
```

### Trade-offs accepted

- The function is duplicated in 2 test files (~25 lines each). Per `feedback_cross_reference_drift_needs_tests`, both copies MUST be updated together if the logic changes. No shared helper extraction because the test-file count is capped at 3 (FR-012 of feature 006).
- The post-verification step adds one extra `bash -c` invocation per test. Cost ~50ms; acceptable.

---

## Relationships

```text
[Handoff State]
   │ artifact_owner field
   │ (governed by Precedence Chain A)
   ▼
[Bridge Event log]
   │ records every transition with the resolved owner

[Verification Record (NEW)]
   │ references release artifacts by sha256
   │ written manually per US4 sandbox runs
   │ no programmatic relation to handoff state
   │ but: FAIL → operator transitions handoff to blocked

[Path Translation Strategy (NEW, test-only)]
   │ used by test-handoff-shape and test-guard-hardcoded-rules
   │ not invoked at runtime; not part of the published surface
```

---

## Schemas

No new JSON / YAML schemas introduced. The v1 handoff schema from feature 006 (`specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`) governs `artifact_owner` and stays the authority.

The verification record format is documented in `contracts/verification-record.md` (Phase 1 deliverable below) — markdown convention, not a formal schema.

---

## State transitions

Unchanged from feature 006 (`ready` → `executing` → `complete` | `blocked`). The B1 fix changes which value of `artifact_owner` gets written on each transition; it does NOT change the state machine itself.

The US4 verification adds one operational rule: `complete` MAY only be reached AFTER the verification record for the current release shows PASS on all required platforms. Spec-level rule, not state-machine logic.
