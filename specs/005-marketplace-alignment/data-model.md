# Data Model: Marketplace Alignment

**Feature**: 005-marketplace-alignment
**Date**: 2026-05-15

Entities introduced or extended by this feature. Bridge runtime state is unchanged — this feature is purely about packaging + documentation + verification scripts.

---

## Catalog Entry (new entity)

The JSON object pasted into upstream `extensions/catalog.community.json`. Drafted in this repo as `marketplace/catalog-entry.json`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Globally unique, lowercase-hyphenated. Ours: `speckit-superpowers-bridge`. |
| `name` | string | yes | Human-readable. Ours: `"Superpowers Implementation Bridge"`. |
| `description` | string ≤200 chars | yes | One-sentence elevator pitch. |
| `author` | string | yes | Maintainer name / handle. Ours: `lihan3238`. |
| `version` | string (semver) | yes | Matches `extension.yml.extension.version`. |
| `license` | string (SPDX ID) | yes | `MIT`. |
| `repository` | string (URL) | yes | GitHub repo URL. |
| `download_url` | string (URL) | yes | Release ZIP URL (HTTP 200 required). |
| `homepage` | string (URL) | optional | Typically the repo root. |
| `documentation` | string (URL) | optional | Typically `<repo>#readme` or a docs site. |
| `changelog` | string (URL) | optional | Link to `CHANGELOG.md`. |
| `requires` | object `{speckit_version, tools[]?}` | yes | `speckit_version: ">=0.8.10"`. Tools optional. |
| `provides` | object `{commands?, hooks?}` | optional | Integer counts of provided commands/hooks. |
| `tags` | array of string | yes (2–10) | Lowercase-hyphenated. Ours: the locked 6-tag set from clarify Q3. |
| `verified` | boolean | (set by upstream) | Defaults `false`; maintainers set `true`. |
| `downloads` / `stars` | integer | (auto) | Catalog auto-updates. |
| `created_at` / `updated_at` | ISO 8601 | (auto) | Catalog auto-updates. |

**Validation rules**:
- `description.Length ≤ 200`.
- `tags.Count ∈ [2, 10]`; lowercase-hyphenated; matches the locked vocabulary set.
- `download_url` resolves with HTTP 200 (HEAD request).
- `version` parses as semver.
- `requires.speckit_version` parses as a version specifier.

**Storage**: `marketplace/catalog-entry.json` in source repo (excluded from distribution per R5). Pasted into `extensions/catalog.community.json` in upstream PR.

---

## Extensions README Row (new entity)

A single Markdown table row pasted into upstream `extensions/README.md` alongside the catalog entry. Drafted as `marketplace/extensions-readme-row.md`.

Shape (matches upstream's existing community-extensions table):

```markdown
| [speckit-superpowers-bridge](https://github.com/lihan3238/speckit-superpowers-bridge) | bridge, superpowers, cross-agent, governance, tdd, workflow | Spec Kit stays source of truth for design; Superpowers executes implementation via explicit skill invocations. Cross-agent (Codex+Claude). |
```

The table row format is determined by the upstream `extensions/README.md` — this draft is updated if upstream changes columns.

**Storage**: `marketplace/extensions-readme-row.md`.

---

## Upstream PR Body (new entity)

Markdown document holding the PR description template, with the mandated AI-disclosure paragraph.

| Section | Required | Notes |
|---|---|---|
| Summary | yes | One paragraph naming what's added (a new community extension entry). |
| Catalog entry rationale | yes | Why this extension belongs in the catalog (briefly). |
| Validation | yes | Confirms manifest schema valid, repo URL reachable, release ZIP reachable, AI disclosure present. |
| AI-assistance disclosure | yes | The canonical paragraph from Spec Kit CONTRIBUTING.md requirement. |
| Contact | optional | Maintainer email or issue tracker. |

**Storage**: `marketplace/upstream-pr-body.md`.

---

## Submission Checklist Report (new entity)

Output of `submission-checklist.ps1`. Same envelope shape as `parity-check.ps1`'s ParityCheckReport (data-model.md from feature 002).

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | integer | yes | `1`. |
| `generated_at` | string (ISO 8601) | yes | Run timestamp. |
| `target_version` | string | yes | The version being audited (read from `extension.yml`). |
| `checks` | array of `{name, passed, severity, message}` | yes | One entry per check from research §R2. |
| `findings` | array of `Finding` | yes | Same `Finding` shape as parity-check (`code`, `severity`, `target`, `message`, `suggested_fix`). |
| `summary` | object `{total, by_severity}` | yes | Counts. |
| `exit_code` | integer | yes | `0` clean, `1` P0, `2` P1, `3` P2-in-strict-mode. |

---

## Cleanup Audit Report (new entity)

Output of `cleanup-audit.ps1`. Same shape as Submission Checklist Report (reuses `Finding`).

Specific finding codes:
- `backup_file_present` — `*.bak`, `*.bak-*`, `*.orig`, `*.tmp`
- `unreferenced_doc` — file under `docs/` not linked from `README.md` or `extension.yml`
- `abandoned_script` — root-level migration / bump script not invoked by any current script or doc
- `gitignore_gap` — `.gitignore` missing one of the 5 required categories
- `manifest_path_inconsistency` — `plugin-distribution-manifest.yml` includes a path that doesn't exist, OR a path appears in both `includes` and `excludes`

---

## Release Runbook (new entity, document not data)

The ordered procedure in `docs/release-runbook.md`. See research §R1 for the 11 steps.

This is documentation, not a programmatic entity. No schema.

---

## Bridge Event (existing entity, optional new event type)

Add `submission_check` action to the bridge-events.jsonl event vocabulary (additive, schema unchanged).

| Field | Value |
|---|---|
| `action` | `"submission_check"` |
| `decision` | `"allow"` (clean) / `"deny"` (any P0 or P1 finding) |
| `reason` | Short summary of finding counts |

Optional polish — the submission-checklist script can append this event on each run so the audit history is preserved alongside other bridge activity.

---

## Relationships

```
Catalog Entry  ──pasted into──> extensions/catalog.community.json (upstream)
                ─validated by─> Submission Checklist Report
                ─referenced by─> Extensions README Row

Extensions README Row  ──pasted into──> extensions/README.md (upstream)

Upstream PR Body  ─pasted into──> PR description on github/spec-kit
                  ─required by──> Spec Kit CONTRIBUTING.md AI-disclosure rule
                  ─asserted by──> Submission Checklist Report (check 8)

Release Runbook  ─orchestrates──> all of the above + test suite + parity-check + validation-pass

Cleanup Audit Report  ─independent of release path; runs at maintainer's discretion
```
