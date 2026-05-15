# marketplace/

This directory holds the **submission-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` by the Spec Kit maintainer. |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md` by the maintainer. |
| `extension-submission-body.md` | Clean final Extension Submission issue body. It leads with the bridge philosophy and contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** - they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Release workflow (automated via `.github/workflows/release.yml`)

Per the upstream [EXTENSION-PUBLISHING-GUIDE](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md), community-extension submissions go **through an issue template**, not a fork+PR. The release-asset build + publish flow is automated; the cross-repo issue comment stays manual.

**Manual pre-tag steps (do these all in one commit on `main`):**

1. Bump `.specify/extensions/speckit-superpowers-bridge/extension.yml` -> `extension.version: "X.Y.Z"`.
2. Bump `marketplace/catalog-entry.json` -> `"version": "X.Y.Z"` and `"download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/vX.Y.Z/speckit-superpowers-bridge-vX.Y.Z.zip"`.
3. Add a `## [X.Y.Z] - <date>` section to `CHANGELOG.md` (this becomes the GitHub release notes).
4. Commit + push to `main`.
5. Verify locally before tagging:
   ```powershell
   pwsh scripts/release/validate-release-readiness.ps1 -Version X.Y.Z
   ```
   The validator checks version/download/changelog alignment plus script-flavor parity and shell-script LF rules. Exit 0 = ready.

**Tag the release:**

```powershell
git tag -a vX.Y.Z -m "vX.Y.Z - <one-line description>"
git push origin vX.Y.Z
```

**Automated on tag push** (`.github/workflows/release.yml`):

1. Validate release readiness (same 4 checks as the local validator).
2. Run all 3 bridge smoke tests (`tests/test-*.ps1`).
3. Run release-tooling self-tests (`scripts/release/test-*.ps1`).
4. Build the ZIP via `scripts/release/build-extension-zip.ps1`.
5. Extract `[X.Y.Z]` section from `CHANGELOG.md` as release notes.
6. `gh release create` with notes + ZIP attached.
7. Print SHA256 + asset URL in the workflow's GitHub Step Summary.

The workflow is sequential - any failure stops the release before the asset is published. Local dry-run is supported: each script can be invoked manually with the same arguments the workflow uses.

**Manual post-release step (cross-repo, intentionally not automated):**

8. Open a clean catalog-submission issue at github/spec-kit via the **[Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)**. Use `marketplace/extension-submission-body.md` as the issue body, paste `catalog-entry.json` into the "Proposed Catalog Entry" section, and copy the vX.Y.Z ZIP SHA256 from the GitHub release asset into the testing details.
9. Close any stale superseded submission issue with a short pointer to the clean issue. Do not delete history.
10. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json`** - the upstream guide explicitly forbids that.

### Why hand-built ZIP (not auto-archive)?

Some canonical catalog entries use the GitHub auto-generated archive at `archive/refs/tags/vX.Y.Z.zip`. Those repos place `extension.yml` at the repo root. **Our repo doesn't**: the bridge content lives under `.specify/extensions/speckit-superpowers-bridge/` because the repo is also a Spec Kit dev environment used to dogfood the bridge on itself. The hand-built ZIP from `scripts/release/build-extension-zip.ps1` produces a standard extension ZIP tree (extension.yml at top, plus commands/, scripts/, LICENSE, README) so the catalog install path works without restructuring the source repo.

### Cross-platform ZIP

The release ZIP carries both runtime flavors: `scripts/powershell/` for Windows and `scripts/bash/` for Linux/macOS. The validator enforces file-count/name parity and `.gitattributes` keeps shell scripts LF-clean on Windows clones.
