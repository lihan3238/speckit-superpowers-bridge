# marketplace/

This directory holds the **submission-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` by the Spec Kit maintainer. |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md` by the maintainer. |
| `upstream-pr-body.md` | The submission body (history note: filename predates the change to issue-based submission; content is still used for the issue body and any future communications). Contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** — they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Workflow (Spec Kit-aligned)

Per the upstream [EXTENSION-PUBLISHING-GUIDE](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md), community-extension submissions go **through an issue template**, not a fork+PR:

1. Cut a release locally:
   - Bump `extension.yml.extension.version`, write a `CHANGELOG.md` entry.
   - Tag: `git tag v0.3.0 && git push origin v0.3.0`.
   - The release archive is auto-generated at `https://github.com/<org>/<repo>/archive/refs/tags/v0.3.0.zip` — no manual ZIP build required.
2. Update `marketplace/catalog-entry.json` to reflect the new version + `download_url`.
3. Open or update the catalog submission issue via the **[Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)**. Paste the contents of `catalog-entry.json` into the "Proposed Catalog Entry" section, and the contents of `upstream-pr-body.md` into the "Additional Context" section (preserving the AI-disclosure paragraph verbatim).
4. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json`** — the upstream guide explicitly forbids that.

For an in-flight submission, comment on the existing issue with version updates rather than opening a new one — this preserves the maintainer's queue position.

The previous automated submission-checklist / release-runbook tooling was removed in v0.3.0 (see `CHANGELOG.md`). The above is the manual procedure that replaced it.
