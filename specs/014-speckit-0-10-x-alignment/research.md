# Phase 0 Research: Spec Kit 0.9.4 → 0.10.2 Upstream Change Audit

**Date**: 2026-06-12 | **Method**: GitHub release notes + merged-PR bodies + validator source diff + empirical re-bootstrap of this repo

## R1. Which upstream changes affect the bridge?

**Decision**: Only init-time/docs-level changes affect us; zero runtime impact.

**Rationale** — full audit of release notes v0.9.4 through v0.10.2:

| Upstream change | Version | Bridge impact |
|---|---|---|
| Git extension opt-in; `--no-git` removed; init no longer auto-installs git | 0.10.0 (#2873) | **Docs**: AGENTS.md bootstrap must add `specify extension add git` for fresh clones (bridge's `before_specify` flow depends on git extension) |
| Legacy `--ai`, `--ai-commands-dir`, `--ai-skills` flags removed | 0.10.0 (#2872) | **Docs**: bootstrap commands already use `--integration`; confirm no stale flag references |
| `init-options.json`: `branch_numbering` → `feature_numbering` | 0.10.x | **None at runtime**: bridge scripts never read this field (grep-verified); git extension reads its own `git-config.yml` first. Docs note only |
| `category` + `effect` first-class extension schema fields | 0.10.2 (#2899) | **Metadata**: declare in `extension.yml` + `marketplace/catalog-entry.json`. Optional fields; backward compatible |
| Per-event hook lists with priority ordering | 0.10.0 (#2798) | **None**: existing single-mapping form explicitly unaffected ("Existing single-mapping manifests are unaffected"). Adopting lists = new surface, rejected per Native-First |
| `extension add --force` overwrite reinstall | 0.9.4 (#2530) | None (convenience only) |
| Catalog payload shape validation, preset URL hardening, etc. | 0.10.1/0.10.2 | None (upstream-internal) |

**Empirical confirmation**: this repo was re-bootstrapped with CLI 0.10.2
(`specify init --here --integration claude --script sh --force`) on
2026-06-12. Results: all 3 extensions remained registered and enabled;
`.specify/scripts/bash/` regenerated under the new path layout
(`scripts/bash/` — note 0.10.x writes `bash/` not `sh/`); all 6 bash smoke
tests pass unchanged; only `init-options.json` field rename and template
overwrites observed (project-customized templates restored from git).

**Alternatives considered**: raising bridge runtime floor to `>=0.10.0` —
rejected: nothing the bridge runs requires 0.10.x, and the floor bump would
orphan 0.8.x/0.9.x consumers for zero benefit.

## R2. Are the new manifest fields safe under the `>=0.8.10` floor?

**Decision**: Yes — declare `category: process`, `effect: read-write`.

**Rationale**: read 0.8.10's `ExtensionManifest._validate()` source directly:
it checks required fields and known-section shapes only; unknown keys under
`extension:` are ignored (no strict/closed-schema check). 0.10.2 validates
`effect` against a closed set (`read-only`/`read-write`) — our value is in
set. Upstream's own `catalog.community.json` already assigns exactly
`category: process` / `effect: read-write` to the bridge entry (added in
upstream PR #2899 catalog backfill), so we adopt upstream's values verbatim.

**Alternatives considered**: leaving fields catalog-only — rejected: the
0.10.2 design sources catalog values from manifests going forward; a manifest
without the fields risks regression on future catalog syncs.

## R3. What evidence refresh is honest for v1.0.3?

**Decision**: New evidence row: Spec Kit 0.10.2 + Linux bash (WSL2) + real
sandbox install from published release URL. Retain existing dated rows
(Windows PowerShell 5.1 native, Codex 0.137.0, Claude Code 2.1.162 from
v1.0.0-rc) marked with their original dates; re-confirm Codex/Claude rows in
the 0.10.2 sandbox if the agents are available during verification, else
retain as dated historical evidence with the release notes saying so.

**Rationale**: constitution End-User Verification Sandbox demands real-URL
install per release; FR-004 forbids advertising unverified claims. The `ps`
script flavor is byte-identical in this release, so prior Windows evidence
remains truthful when clearly dated.

**Alternatives considered**: full native-Windows re-verification — kept
optional: no `ps` bytes change; mandatory re-run would gate the release on
hardware availability without adding information.

## R4. Stale handoff blocking the pipeline?

**Decision**: Resolved before this feature started.

**Rationale**: `.specify/superpowers-handoff.json` carried a stale
`executing` state for `specs/006-trim-to-thin-bridge` (2026-06-04). On
2026-06-12 it was transitioned to `complete` (with the expected 25-pending-
tasks drift warning — 006 tasks superseded by later features) and
auto-archived (snapshot `20260611T184717083Z-ready`). Handoff is now
`ready` / no feature directory; guard allows `speckit.plan` for 014.
