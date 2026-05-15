# marketplace/

This directory holds the **upstream-PR-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` (alphabetical by `id`). Validated against `specs/005-marketplace-alignment/contracts/catalog-entry.schema.json`. |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md`. |
| `upstream-pr-body.md` | The PR description template for the upstream fork+PR. Contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** — they describe US to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension. The exclusion is recorded in [`plugin-distribution-manifest.yml`](../.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml).

## Workflow

1. Cut a release per `docs/release-runbook.md`.
2. Update `catalog-entry.json` (bump `version` and `download_url` to point at the new release ZIP).
3. Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1` — exit 0.
4. Fork `github/spec-kit`, paste `catalog-entry.json` into `extensions/catalog.community.json`, paste `extensions-readme-row.md` into `extensions/README.md`, open a PR with `upstream-pr-body.md` as the description.

See [`docs/release-runbook.md`](../docs/release-runbook.md) for the full 11-step procedure.
