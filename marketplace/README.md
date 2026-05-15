# marketplace/

This directory holds the **submission-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` by the Spec Kit maintainer. |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md` by the maintainer. |
| `upstream-pr-body.md` | The submission body (history note: filename predates the change to issue-based submission; content is still used for the issue body and any future communications). Contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** — they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Release workflow (automated via `.github/workflows/release.yml`)

Per the upstream [EXTENSION-PUBLISHING-GUIDE](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md), community-extension submissions go **through an issue template**, not a fork+PR. The release-asset build + publish flow is automated; the cross-repo issue comment stays manual.

**Manual pre-tag steps (do these all in one commit on `main`):**

1. Bump `.specify/extensions/speckit-superpowers-bridge/extension.yml` → `extension.version: "X.Y.Z"`.
2. Bump `marketplace/catalog-entry.json` → `"version": "X.Y.Z"` and `"download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/vX.Y.Z/speckit-superpowers-bridge-vX.Y.Z.zip"`.
3. Add a `## [X.Y.Z] - <date>` section to `CHANGELOG.md` (this becomes the GitHub release notes).
4. Commit + push to `main`.
5. Verify locally before tagging:
   ```powershell
   pwsh scripts/release/validate-release-readiness.ps1 -Version X.Y.Z
   ```
   The validator checks all four cross-references (extension.yml, catalog-entry.json version, catalog-entry.json download_url, CHANGELOG section). Exit 0 = ready.

**Tag the release:**

```powershell
git tag -a vX.Y.Z -m "vX.Y.Z — <one-line description>"
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

The workflow is sequential — any failure stops the release before the asset is published. Local dry-run is supported: each script can be invoked manually with the same arguments the workflow uses.

**Manual post-release step (cross-repo, intentionally not automated):**

8. Open or update the catalog-submission issue at github/spec-kit via the **[Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)**. Paste `catalog-entry.json` into the "Proposed Catalog Entry" section, and `marketplace/upstream-pr-body.md` (with the new SHA256 from the workflow summary) into the "Additional Context" section. For an in-flight submission, comment on the existing issue rather than opening a new one — preserves the maintainer's queue position.
9. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json`** — the upstream guide explicitly forbids that.

### Why hand-built ZIP (not auto-archive)?

Some canonical catalog entries (`agent-assign`, `agent-governance`) use the GitHub auto-generated archive at `archive/refs/tags/vX.Y.Z.zip`. Those repos place `extension.yml` at the repo root. **Our repo doesn't**: the bridge content lives under `.specify/extensions/speckit-superpowers-bridge/` because the repo is also a Spec Kit dev environment used to dogfood the bridge on itself. The hand-built ZIP from `scripts/release/build-extension-zip.ps1` produces an `agent-governance`-shaped tree (extension.yml at top, plus commands/, scripts/, LICENSE, README) so the catalog install path works without restructuring the source repo.

### Future Linux/macOS port (feature 003 stub)

When `.specify/extensions/.../scripts/bash/` lands, add one `Copy-Item scripts/bash` line to `build-extension-zip.ps1`. Same release workflow; the ZIP just carries both script dirs.
