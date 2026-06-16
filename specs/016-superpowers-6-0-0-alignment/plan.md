# Implementation Plan: Superpowers 6.0.0 Compatibility Alignment & Evidence Refresh

**Branch**: `016-superpowers-6-0-0-alignment` | **Date**: 2026-06-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/016-superpowers-6-0-0-alignment/spec.md`

## Summary

Minor release **v1.1.0**: move the bridge's verified-against-Superpowers
baseline from **5.1.0 → 6.0.0** (a major upstream bump) and refresh every
version-pinned claim, **with zero bridge runtime change**. The upstream-impact
analysis (`research.md`) proves the major's breaking changes are all internal to
Superpowers skills and transparent to the thin bridge (skill names unchanged;
consumer contract for `tasks.md` intact; grep audit clean). Two deliverable
groups: (1) **evidence + metadata** — `verified-versions.json` (5.1.0→6.0.0,
bridge 1.1.0, fresh date + 6.0.0 evidence note), version bump in `extension.yml`
+ `marketplace/catalog-entry.json`, CHANGELOG `[1.1.0]` with the upstream-impact
verdicts; (2) **public claims** — README EN/zh badges + maintenance + install
example, and the two `marketplace/` release-gate files. The green smoke suite
(6/6 under Superpowers 6.0.0) is the in-repo gate; the published-artifact
sandbox cycle is deferred to the maintainer's release/tag step (per the chosen
"stop before tag" scope).

## Technical Context

**Language/Version**: Bash 5.2 (smoke suite + bridge scripts, untouched), PowerShell 5.1 (parity flavor, untouched), YAML/JSON metadata, Markdown docs

**Primary Dependencies**: Superpowers 6.0.0 (live, verified target), Spec Kit CLI 0.10.2 (dev/bootstrap, unchanged), bridge runtime floor `>=0.8.10` (unchanged), jq >=1.6, gh CLI

**Storage**: N/A (flat files: extension.yml, catalog-entry.json, verified-versions.json, README, CHANGELOG, marketplace/*.md)

**Testing**: `bash tests/run-all.sh` (6 smoke tests incl. release-package against the rebuilt v1.1.0 ZIP); end-user sandbox in `../test_specify_superpower` (published-artifact cycle deferred to release/tag)

**Target Platform**: Linux bash (WSL2 primary); Windows PowerShell 5.1+ (existing dated evidence retained — `ps` flavor byte-identical this release)

**Project Type**: Spec Kit extension (CLI-installed docs/scripts package)

**Performance Goals**: N/A (no runtime code paths change)

**Constraints**: No new bridge surface; SKILL/command/script bytes frozen; handoff v1 schema / guard rules / actor semantics / `[bridge state]` output untouched; `download_url` stays the stable latest-release alias; every advertised claim must be evidence-backed

**Scale/Scope**: ~8 files touched outside `specs/016-*/` (extension.yml, catalog-entry.json, verified-versions.json, README.md, README.zh-CN.md, CHANGELOG.md, marketplace/extensions-readme-row.md, marketplace/extension-submission-body.md); 0 new runtime files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Lightweight & Repo-Local | No new infra; flat-file metadata/doc edits only | PASS |
| II. Design/Implementation Separation | Spec Kit artifacts (this set) drive; release work is the deliverable | PASS |
| III. Agent-Neutral Protocol | No protocol change; both `.claude`/`.agents` surfaces untouched | PASS |
| IV. Smooth Bidirectional Handoff | Handoff schema/flow unchanged | PASS |
| V. Vendor-Managed Boundaries | No edits to generated `speckit-*` skills; only bridge-owned files | PASS |
| VI. Native-First Compatibility | **The point of this feature.** No NEW surface; no logic added to "track" the upstream major. Q1 "does upstream already do this?" — yes, the upstream skills own the changes; the bridge composes them by name. Q2 "is upstream the right place?" — yes; the bridge correctly carries nothing. Aligning the *verified baseline* is metadata, not surface | PASS |

> **Native-First gate** (constitution §"VI", v1.3.0+): This release adds **zero**
> bridge surface and deliberately makes **zero** behavior change in response to a
> major upstream bump — that non-change *is* the Principle VI compliance.
> `research.md` is the evidence. Nothing enters Complexity Tracking.
>
> **Release gate** (constitution §"End-User Verification Sandbox", v1.2.0+):
> v1.1.0 will ship a release artifact, so the published-artifact sandbox cycle
> is REQUIRED **before the handoff transitions to `complete`**. Per the chosen
> "update + commit, stop before tag" scope, the publish/tag step (and therefore
> the published-v1.1.0 sandbox cycle) is deferred to the maintainer's release
> step; this feature's handoff is intentionally **not** driven to `complete`
> this session. The strongest in-repo gate that CAN run now — the 6/6 smoke
> suite green with Superpowers 6.0.0 installed — is run, and the bridge runtime
> bytes are byte-identical to the v1.0.3 artifact that already passed the
> published-artifact sandbox cycle (see `verification.md`).

## Project Structure

### Documentation (this feature)

```text
specs/016-superpowers-6-0-0-alignment/
├── plan.md              # This file
├── spec.md              # Full-tier spec
├── research.md          # 5.1.0→6.0.0 upstream-impact analysis (grep-backed)
├── quickstart.md        # Validation/run guide
├── verification.md      # Evidence record (filled during implementation)
├── checklists/
│   └── requirements.md  # Full-tier spec-quality checklist
└── tasks.md             # Implementation contract
```

No `data-model.md` / `contracts/`: no new entities or interfaces — the handoff
v1 schema and `[bridge state]` contract are explicitly frozen (spec Out of
Scope).

### Source Code (repository root)

```text
README.md / README.zh-CN.md                            # Superpowers badge 5.1.0→6.0.0, maintenance, install example 1.1.0
CHANGELOG.md                                           # [1.1.0] entry + upstream-impact verdicts
.specify/extensions/speckit-superpowers-bridge/
├── extension.yml                                      # version 1.0.3 → 1.1.0
└── verified-versions.json                             # superpowers 6.0.0, bridge 1.1.0, fresh evidence
marketplace/catalog-entry.json                         # version 1.1.0 + updated_at; download_url unchanged
marketplace/extensions-readme-row.md                   # v1.1.0 support summary
marketplace/extension-submission-body.md               # v1.1.0 baseline + support matrix + proposed catalog entry
tests/                                                 # unchanged; must stay green (rebuild v1.1.0 ZIP for release-package test)
```

**Structure Decision**: Single existing repo layout; all edits in place. The
release pipeline (existing GitHub Actions workflow + validators) is reused
without modification. No bridge SKILL/command/script file is edited.

## Phasing

- **Phase 0 — Research** (`research.md`, done): upstream diff + grep audit → no bridge change.
- **Phase 1 — Evidence + metadata**: `verified-versions.json`, `extension.yml`, `marketplace/catalog-entry.json`, CHANGELOG `[1.1.0]`.
- **Phase 2 — Public claims**: README EN/zh, `marketplace/extensions-readme-row.md`, `marketplace/extension-submission-body.md`.
- **Phase 3 — Verify**: rebuild v1.1.0 ZIP, `bash tests/run-all.sh` 6/6, record evidence in `verification.md` (sandbox-publish step deferred to release).

## Complexity Tracking

No constitution violations; table intentionally empty.
