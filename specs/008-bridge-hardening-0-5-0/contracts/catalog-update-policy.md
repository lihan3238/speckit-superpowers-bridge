# Contract: Catalog Update Policy

**Owner**: `marketplace/README.md` (documentation contract, not a script).

**Consumers**: Future maintainers preparing a release (`vX.Y.Z`); the operator filing or skipping the upstream catalog issue.

**Stability**: Policy may evolve. The CONTRACT here is the *shape* of the policy statement; the bytes inside that shape may change with each policy revision.

## Contract

`marketplace/README.md` MUST contain a section titled `## Catalog update policy` (or equivalent header beginning with "Catalog update") with the following structure:

```markdown
## Catalog update policy

**As of <YYYY-MM-DD>**, the upstream-documented process for already-accepted catalog entries is: <one-line summary, citing the upstream source>.

**Source**: <permalink URL to a specific commit-pinned or tag-pinned file/section in `github/spec-kit`>.

**Our policy**:

| Bump magnitude | Action |
|---|---|
| Patch (e.g., 0.5.0 → 0.5.1) | <skip-or-file> |
| Minor (e.g., 0.5.x → 0.6.0) | <skip-or-file> |
| Major (e.g., 0.x → 1.0.0) | <skip-or-file> |

**Rationale**: <one paragraph linking back to the Clarifications Q5 decision in the latest active spec>.

**How to file an update issue** (when applicable):

1. Copy [`marketplace/extension-submission-body.md`](./extension-submission-body.md) into the upstream "Extension Submission" issue template body.
2. Title format: `Extension Submission Update: speckit-superpowers-bridge vX.Y.Z`.
3. Reference any open prior catalog issues with `Supersedes #<N>` in the body.
4. Do NOT open a PR against `extensions/catalog.community.json`. Upstream applies the change on their side.
```

## Rules

- **R-POL-1**: `As of <YYYY-MM-DD>` MUST be a real date. When the policy is reviewed/refreshed, the date MUST be updated even if the policy text itself doesn't change. This anchors the audit trail.
- **R-POL-2**: `Source:` MUST be a permalink (commit SHA or tag-pinned), NOT a `blob/main` URL. Upstream may rewrite `main`; we MUST snapshot the version we read.
- **R-POL-3**: The bump-magnitude table MUST have rows for `Patch`, `Minor`, and `Major`. Missing a row is a policy hole.
- **R-POL-4**: `<skip-or-file>` is a free-form cell but MUST resolve to one of: `Skip (rely on stable-alias URL)`, `File upstream issue`, or `Conditional (see below)` with an inline footnote.
- **R-POL-5**: The rationale paragraph MUST link to the latest Clarifications Q resolution that drove the policy (e.g., `[spec.md § Clarifications Q5](../specs/008-.../spec.md)`).
- **R-POL-6**: "How to file" steps MUST explicitly prohibit PRs against `catalog.community.json` (the prohibition is the upstream rule, not ours — but we propagate it because operators sometimes forget).

## Acceptance scenarios

### S1. v0.5.0 first instantiation

After v0.5.0 ships, `marketplace/README.md` should read (substantively):

```markdown
## Catalog update policy

**As of 2026-05-16**, the upstream-documented process for already-accepted catalog entries is: file a fresh "Extension Submission" issue against `github/spec-kit` per release. No automated path is documented as of this date.

**Source**: <permalink to relevant section of github/spec-kit/CONTRIBUTING.md at commit <SHA> as of 2026-05-16>

**Our policy**:

| Bump magnitude | Action |
|---|---|
| Patch (e.g., 0.5.0 → 0.5.1) | Skip (rely on stable-alias URL `releases/latest/download/speckit-superpowers-bridge.zip`) |
| Minor (e.g., 0.5.x → 0.6.0) | File upstream issue |
| Major (e.g., 0.x → 1.0.0) | File upstream issue |

**Rationale**: Balances "strictly follow upstream method" with "minimize per-release issue overhead". Patches in this project are typically docs/marketplace polish or surgical bridge fixes that don't change the catalog-visible surface; users discover the latest version through the stable-alias URL added in v0.4.3. See [spec.md § Clarifications Q5](../specs/008-bridge-hardening-0-5-0/spec.md) for the decision record.

**How to file an update issue** (when applicable):

1. Copy [`marketplace/extension-submission-body.md`](./extension-submission-body.md) into the upstream "Extension Submission" issue template body.
2. Title format: `Extension Submission Update: speckit-superpowers-bridge vX.Y.Z`.
3. Reference any open prior catalog issues with `Supersedes #<N>` in the body.
4. Do NOT open a PR against `extensions/catalog.community.json`. Upstream applies the change on their side.
```

### S2. Hypothetical upstream automated path

If FR-009 research uncovers that upstream now supports automated catalog updates (e.g., release-feed polling), the table changes to:

```markdown
| Patch | Automated (no action needed) |
| Minor | Automated (no action needed) |
| Major | File upstream issue (signal a notable change) |
```

The rationale paragraph is updated; the structure stays.

## Constraints

- **C-POL-1**: The policy statement is the SINGLE source of truth for our catalog-update process. `extension-submission-body.md` is the issue-body template; `catalog-entry.json` is the JSON shape; this policy doc is the process glue.
- **C-POL-2**: When a release ships, the policy doc's date MUST be the release date OR more recent. Releasing with a stale policy date is a documentation defect (caught by any future operator skimming `marketplace/README.md`).
