# Install-State Audit Contract

**Feature**: 004-polish-and-publish
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1`
**Slash command (Claude)**: `/speckit-superpowers-audit`
**Codex command**: `$speckit-superpowers-audit`
**Internal Spec Kit command ID**: `speckit.superpowers.audit`

## Purpose

Single-shot diagnostic of the host project's bridge-relevant install state. Surfaces:

1. Installed Spec Kit version + default integration.
2. Which agent integrations are installed.
3. Whether the git extension is installed (and its version + provided commands).
4. Per-agent skill parity (Codex ↔ Claude): missing peers, content divergence (SHA-256 of `SKILL.md`).
5. Script flavour (ps vs sh).
6. A flat list of findings (same envelope as parity-check.ps1).

## Synopsis

```
audit-install-state.ps1 [-Json] [-Strict] [-Actor <codex|claude|unknown>]
```

| Param | Default | Meaning |
|---|---|---|
| `-Json` | off | Emit a single JSON document matching Install-State Audit Report. Otherwise human-readable summary. |
| `-Strict` | off | Treat P2 findings as failure (raises exit code). |
| `-Actor` | resolved per common-actor-resolution.ps1 | Recorded on the appended bridge event. |

## Inputs (read from disk)

- `.specify/integration.json`
- `.specify/init-options.json`
- `.specify/integrations/*.manifest.json`
- `.specify/extensions/git/extension.yml` (if present)
- `.agents/skills/*/SKILL.md`
- `.claude/skills/*/SKILL.md`

## Checks performed

1. **Spec Kit version**: read `integration.json.version`. Compare against `.specify/extensions/speckit-superpowers-bridge/verified-versions.json.spec_kit_version`. Mismatch → P1 finding (`spec_kit_version_drift`).
2. **Default integration**: read `integration.json.default_integration`. If empty or not in `["codex", "claude"]` → P2 (`ambiguous_default_integration`).
3. **Integration manifests**: each `installed_integrations` entry must have a corresponding manifest file. Missing → P1 (`missing_integration_manifest`).
4. **Git extension presence + version**: if `.specify/extensions/git/extension.yml` exists, parse it. Absence is informational, not a finding (a project can legitimately ship without the git extension).
5. **Per-agent skill parity**:
   - Enumerate `.agents/skills/<id>/SKILL.md` and `.claude/skills/<id>/SKILL.md`.
   - Any skill present on one side but not the other → P1 (`missing_per_agent_skill`).
   - Any skill present on BOTH sides with diverging SHA-256 → P2 (`skill_content_diverged`) UNLESS the skill is documented as "intentionally diverged" (see "Allowed divergence" below).
6. **Script flavour**: `init-options.json.script` matches the `script:` entries in `extensions.yml`'s `script` settings. Mismatch → P2 (`script_flavour_mismatch`).

## Allowed divergence

The `speckit-superpowers-bridge/SKILL.md` files on Codex and Claude are EXPECTED to differ in invocation syntax (Codex `$skill-name` vs Claude `/skill-name`, and Skill-tool vs slash references). The script ignores this specific skill from the divergence check OR compares structurally (heading count + section list, not content hash). Decision: skip the content-hash check for `speckit-superpowers-bridge` specifically; check structural parity instead via the same algorithm used by `check-readme-bilingual-parity.ps1`'s heading-set comparison.

## Outputs

### stdout (with `-Json`)

JSON matching the Install-State Audit Report schema in [data-model.md](../data-model.md). Newline-terminated.

### stdout (default)

```
Install-state audit: spec_kit 0.8.9 / default_integration codex
  Integrations: codex (ok), claude (ok)
  Git extension: installed (1.0.0, 5 commands)
  Skill parity: 0 missing, 1 diverged (acceptable: speckit-superpowers-bridge structural OK)
  Findings: P0=0 P1=0 P2=0
```

### stderr

One line per finding (when not `-Json`).

## Exit codes

Same convention as parity-check.ps1:
- `0` clean (or only P2/P3 without `-Strict`)
- `1` at least one P0
- `2` at least one P1
- `3` at least one P2 with `-Strict`
- `64` bad invocation
- `66` required input file missing

## Side effects

Appends one bridge event per run:
```json
{"timestamp":"...","action":"install_state_audit","status":"<handoff-status>","feature_directory":"<...>","decision":"<allow|deny>","reason":"<summary>","actor":"<resolved>","snapshot_id":null}
```

Read-only otherwise.

## Performance

Target: under 5 seconds on this repository (no hashing or comparison of unbounded data).

## Testing

`tests/test-install-state-audit.ps1` covers:
- Happy path on this repo → exit 0.
- Synthetic missing-claude-skill: temporarily remove a `.claude/skills/<id>` → expect P1 + `missing_per_agent_skill` finding; restore in `finally`.
- Synthetic version drift: temporarily mutate `verified-versions.json` → expect P1 + `spec_kit_version_drift`; restore.
- Synthetic content divergence: temporarily append a comment to `.agents/skills/speckit-git-feature/SKILL.md` → expect P2 + `skill_content_diverged`; restore.
