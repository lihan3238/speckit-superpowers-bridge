# Parity Check Contract

**Feature**: 002-complete-bridge-protocol
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`
**Slash command (Claude)**: `/speckit-superpowers-parity`
**Codex command**: `$speckit-superpowers-parity`
**Internal Spec Kit command ID**: `speckit.superpowers.parity`

## Synopsis

```
parity-check.ps1 [-Json] [-Strict] [-Actor <codex|claude|unknown>]
```

## Parameters

| Param | Type | Default | Meaning |
|---|---|---|---|
| `-Json` | switch | off | Emit a single JSON document on stdout matching the Parity Check Report schema. When off, emit a human-readable summary on stdout and findings on stderr. |
| `-Strict` | switch | off | Treat P2 findings as failure-eligible (raises exit code). Default counts only P0/P1 as failure-eligible. |
| `-Actor` | enum | `unknown` | Recorded in the bridge event log entry written when this command runs. |

## Inputs (read from disk)

- `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml`
- `.specify/extensions/speckit-superpowers-bridge/verified-versions.yml`
- `.specify/extensions.yml`
- `.agents/skills/*/SKILL.md` (presence + name)
- `.claude/skills/*/SKILL.md` (presence + name)
- `.specify/integrations/*.manifest.json` (for recorded agent-side commands)

## Checks performed

1. **Schema validity** — both YAML files parse and conform to their JSON Schemas.
2. **Verified-version drift** — installed Spec Kit version (from `.specify/init-options.json`) and the runtime-exposed Superpowers skill set match the pin in `verified-versions.yml`. Any mismatch is a `version_drift` finding (P1 by default).
3. **Matrix coverage** — every command/skill in the verified pin has a `Disposition Entry`. Missing → `missing_disposition` finding (P0).
4. **Replacement validity** — every `SUPERSEDED-BY` entry's `superseded_by` target resolves to another entry. Missing → `missing_replacement` finding (P0).
5. **Per-agent surface parity** — for every `hooks.*` command in `.specify/extensions.yml`, both `.agents/skills/<id>/SKILL.md` and `.claude/skills/<id>/SKILL.md` MUST exist (or the command MUST be provided by an installed extension that targets both integrations). Missing → `missing_invocation_surface` finding (P1, scoped to the missing agent).
6. **Doc/matrix consistency** — `AGENTS.md` and `CLAUDE.md` MUST reference the matrix file in their respective bridge sections. Inconsistency → `matrix_doc_inconsistency` finding (P2).

## Outputs

### stdout (when `-Json`)

A single JSON document matching the Parity Check Report schema described in
[data-model.md](../data-model.md). Newline-terminated. No leading prelude.

### stdout (default)

A short human-readable summary like:

```
Parity check: 24 entries verified, 0 P0 findings, 1 P1 finding.
P1: missing_invocation_surface — .claude/skills/speckit-git-feature/SKILL.md is absent (suggested fix: copy from .agents/skills/speckit-git-feature/SKILL.md).
```

### stderr (default)

One line per finding, prefixed with severity:

```
[P1] missing_invocation_surface  speckit.git.feature on claude — .claude/skills/speckit-git-feature/SKILL.md absent. Fix: cp -r .agents/skills/speckit-git-feature .claude/skills/speckit-git-feature
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All checks pass (or only P2/P3 findings exist and `-Strict` is off). |
| `1` | At least one P0 finding. |
| `2` | At least one P1 finding (and no P0). |
| `3` | At least one P2 finding **and** `-Strict` is on (and no P0/P1). |
| `64` | Bad invocation (unknown flag, malformed argument). |
| `66` | Required input file missing (`disposition-matrix.yml` or `verified-versions.yml`). |
| `70` | Schema validation failed on an input YAML file. |

## Side effects

- Appends one `bridge_event` entry to `.specify/bridge-events.jsonl` with
  `action == "parity_check"`, `decision == "allow"|"deny"`, and a summary in
  `reason`. The event is appended even when the check is purely advisory (P2/P3 only).
- Does NOT modify any input file. Read-only otherwise.

## Performance contract

- MUST complete in under 30 seconds on a clean checkout of this repository
  (SC-005). Typical run on the verified install is expected to be < 5 s.

## Testing

`test-bridge-guard.ps1` is extended with parity-check cases:
- Happy path: all entries present, no drift → exit 0.
- Synthetic missing-Claude-skill: temporarily remove `.claude/skills/speckit-git-feature` → exit 2, finding present.
- Synthetic version drift: edit `verified-versions.yml` to a different `spec_kit_version` → exit 2 (P1), finding present.
- Synthetic missing-disposition: add a new fake skill name to `verified-versions.yml.superpowers_skills` without adding to the matrix → exit 1 (P0), finding present.

All synthetic cases MUST restore the modified file in their `finally` block.
