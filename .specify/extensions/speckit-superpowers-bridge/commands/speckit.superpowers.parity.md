---
description: "Run the bridge parity check to audit disposition coverage, per-agent surfaces, and version pinning"
---

# Bridge Parity Check

Audit the Spec Kit + Superpowers bridge for non-overlap policy completeness and cross-agent surface parity.

## When to use

- On-demand audit before opening a PR or merging implementation work.
- After upgrading Spec Kit or the Superpowers skill pack (verified-versions drift).
- When a new compatibility gap is suspected.
- Automatically via the optional `before_tasks` hook in `.specify/extensions.yml` (off by default — opt-in for stricter teams).

## Behavior

Runs `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1` which performs six checks:

1. Schema validity of `disposition-matrix.json` and `verified-versions.json`.
2. Verified-version drift between installed and pinned Spec Kit / Superpowers versions.
3. Matrix coverage — every command/skill in the verified pin has a disposition entry.
4. Replacement validity — every `SUPERSEDED-BY` entry's target resolves.
5. Per-agent surface parity — every hook command in `.specify/extensions.yml` has a registered surface (slash command on Claude Code, `$speckit-*` on Codex, or extension command on both).
6. Doc/matrix consistency — `AGENTS.md` and `CLAUDE.md` reference the matrix.

The check is read-only and idempotent.

## Execution

Run this from the repository root:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1 -Json -Actor <codex|claude>
```

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | All checks pass (or only P2/P3 findings without `-Strict`) |
| `1` | At least one P0 finding |
| `2` | At least one P1 finding (no P0) |
| `3` | At least one P2 finding AND `-Strict` is on |
| `64` | Bad invocation |
| `66` | Required input file missing |
| `70` | Schema validation failed |

## Output

With `-Json`, emits a single Parity Check Report document on stdout. Without `-Json`, prints a short summary on stdout and per-finding lines on stderr.

Every run appends a `bridge_event` of `action: parity_check` to `.specify/bridge-events.jsonl` recording the actor and aggregate decision.

## See also

- `specs/002-complete-bridge-protocol/contracts/parity-check-contract.md`
- `specs/002-complete-bridge-protocol/contracts/disposition-matrix.schema.json`
- `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json`
- `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`
