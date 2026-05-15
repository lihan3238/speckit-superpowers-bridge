# marketplace/

This directory holds the **upstream-PR-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` (alphabetical by `id`). |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md`. |
| `upstream-pr-body.md` | The PR description template for the upstream fork+PR. Contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** — they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Workflow

1. Cut a release (update `extension.yml.extension.version`, write a `CHANGELOG.md` entry, tag a release, attach the ZIP to the GitHub release).
2. Update `catalog-entry.json` (bump `version` and `download_url` to point at the new release ZIP).
3. Fork `github/spec-kit`, paste `catalog-entry.json` into `extensions/catalog.community.json`, paste `extensions-readme-row.md` into `extensions/README.md`, open a PR with `upstream-pr-body.md` as the description.

The previous automated submission-checklist / release-runbook tooling was removed in v0.3.0 (see `CHANGELOG.md`). The above is the manual procedure that replaced it.
