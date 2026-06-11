# Implementation Plan: Spec Kit 0.10.x Compatibility Alignment & Evidence Refresh

**Branch**: `014-speckit-0-10-x-alignment` | **Date**: 2026-06-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/014-speckit-0-10-x-alignment/spec.md`

## Summary

Patch release v1.0.3: align the bridge's docs, manifest metadata, and
verification evidence with Spec Kit 0.10.x (CLI upgraded 0.9.3 → 0.10.2;
runtime already verified compatible — 6/6 smoke tests pass unchanged). Three
deliverable groups: (1) AGENTS.md bootstrap guidance for 0.10.0's init-time
breaking changes (git extension opt-in, legacy `--ai*` flags removed,
`branch_numbering`→`feature_numbering`); (2) declare new first-class
`category: process` / `effect: read-write` fields in `extension.yml` and
`marketplace/catalog-entry.json`; (3) refresh `verified-versions.json`,
README badges (EN+zh-CN), CHANGELOG, version bump to 1.0.3, with end-user
sandbox verification on Spec Kit 0.10.2 before handoff `complete`.

## Technical Context

**Language/Version**: Bash 5.2 (test suite + bridge scripts), PowerShell 5.1 (parity flavor, untouched), YAML/JSON metadata

**Primary Dependencies**: Spec Kit CLI 0.10.2 (dev/bootstrap), bridge runtime floor `>=0.8.10` (unchanged), jq >=1.6, gh CLI

**Storage**: N/A (flat files: extension.yml, catalog-entry.json, verified-versions.json, markdown docs)

**Testing**: `bash tests/run-all.sh` (6 smoke tests), release validators (`tests/test-release-package.sh` + validation script), end-user sandbox in `../test_specify_superpower`

**Target Platform**: Linux bash (WSL2 primary), Windows PowerShell 5.1+ (existing evidence retained, no script changes)

**Project Type**: Spec Kit extension (CLI-installed docs/scripts package)

**Performance Goals**: N/A (no runtime code paths change)

**Constraints**: No new bridge surface; handoff v1 schema / guard rules / actor semantics frozen; `download_url` stays the stable latest-release alias; claims must be evidence-backed (no advertised support without a verification row)

**Scale/Scope**: ~8 files touched (AGENTS.md, extension.yml, catalog-entry.json, verified-versions.json, README.md, README.zh-CN.md, CHANGELOG.md, feature verification doc); 0 new files outside `specs/014-*/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Lightweight & Repo-Local | No new infra; flat-file edits only | PASS |
| II. Design/Implementation Separation | Spec Kit artifacts drive; implementation via bridge handoff | PASS |
| III. Agent-Neutral Protocol | No protocol change; both agent surfaces untouched | PASS |
| IV. Smooth Bidirectional Handoff | Handoff used normally for this feature | PASS |
| V. Vendor-Managed Boundaries | No edits to generated speckit-* skills; only bridge-owned files | PASS |
| VI. Native-First Compatibility | No NEW surface added. Q1 "does upstream already do this?" — upstream *defined* the new fields; we adopt values upstream already assigned. Q2 "is upstream the right place?" — no: manifest fields must live in the bridge's own manifest | PASS |

> **Release gate** (constitution §"End-User Verification Sandbox", v1.2.0+):
> v1.0.3 ships a release artifact → sandbox verification in
> `../test_specify_superpower` from the published release URL is REQUIRED
> before handoff `complete`. Planned under Polish phase (Linux bash on Spec
> Kit 0.10.2 is the new-evidence row; Windows PowerShell evidence from
> v1.0.0/v1.0.2 is retained as dated historical evidence since the `ps`
> script flavor is byte-identical in this release — re-verification optional,
> documented either way).
>
> **Native-First gate** (constitution §"VI. Native-First Compatibility",
> v1.3.0+): No new skill, hook, script, state file, or convention. The two
> new manifest fields are upstream-defined schema slots, not bridge
> conventions. Gate answered above; nothing enters Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/014-speckit-0-10-x-alignment/
├── plan.md              # This file
├── research.md          # Phase 0: upstream 0.9.4→0.10.2 change audit
├── quickstart.md        # Phase 1: validation/run guide
├── verification.md      # Sandbox + evidence record (filled during implementation)
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

No `data-model.md` / `contracts/`: this feature defines no new entities or
interfaces — the existing handoff v1 schema and `[bridge state]` contract are
explicitly frozen (spec Out of Scope).

### Source Code (repository root)

```text
AGENTS.md                                              # bootstrap table + 0.10.x notes
README.md / README.zh-CN.md                            # badge + verified claims
CHANGELOG.md                                           # [1.0.3] entry
.specify/extensions/speckit-superpowers-bridge/
├── extension.yml                                      # +category +effect, version 1.0.3
└── verified-versions.json                             # 0.10.2 evidence rows
marketplace/catalog-entry.json                         # +category +effect, version 1.0.3
tests/                                                 # unchanged; must stay green
```

**Structure Decision**: Single existing repo layout; all edits in place. The
release pipeline (existing GitHub Actions workflow + validators) is reused
without modification.

## Complexity Tracking

No constitution violations; table intentionally empty.
