# Add `speckit-superpowers-bridge` to the community catalog

> **Paste this content into the PR description** when submitting the upstream PR
> against `github/spec-kit`. Update version numbers in `Validation` if a newer
> release has been cut between drafting this and opening the PR.

## Summary

This PR adds **speckit-superpowers-bridge** (v0.2.0) to the community catalog.

The bridge is a lightweight repo-local protocol that formalizes the combination
pattern Spec Kit and [Superpowers](https://github.com/obra/superpowers) were
designed to support but never explicitly contracted:

- **Spec Kit owns WHAT** — constitution, spec, clarify, plan, tasks, checklists,
  analysis. These are the durable design artifacts.
- **Superpowers owns HOW** — TDD, debugging, executing-plans, code review,
  verification, finishing-a-development-branch. These are the implementation
  discipline.
- The bridge codifies the non-overlap policy as a `disposition-matrix.json`
  (one entry per Spec Kit command + Superpowers skill), enforced by a guard
  that runs before every potentially-overlapping action.
- The bridge invokes Superpowers skills **explicitly** at named lifecycle
  phases (per the [dev.to comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)'s
  warning that auto-trigger can derail sessions), and every invocation is
  logged as a `skill_invocation` event for audit.

## Catalog entry rationale

- **Tags** (`bridge, superpowers, cross-agent, governance, tdd, workflow`)
  surface the bridge to users searching for any of: a way to combine Spec Kit
  with Superpowers, a non-overlap governance layer, cross-agent (Codex + Claude
  Code) tooling, or formal TDD enforcement.
- **`requires.speckit_version: ">=0.8.10"`** matches the locally-verified
  baseline; older Spec Kit versions lack the extension-manifest fields the
  bridge relies on.
- **`provides.commands: 9`** counts the bridge meta-commands (handoff, guard,
  audit, validate, parity, recommend-route, execute, submission-checklist,
  cleanup-audit).
- **`provides.hooks: 6`** counts the Spec Kit lifecycle hooks the extension
  registers (`before_specify`, `before_clarify`, `before_plan`, `before_tasks`,
  `before_implement`, `after_tasks`).

## Validation

Verified against the [Spec Kit publishing
guide](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md)
checklist:

- [x] Public GitHub repository at `https://github.com/lihan3238/speckit-superpowers-bridge`.
- [x] Tagged semantic release `v0.2.0` with downloadable ZIP at the URL in
      `download_url`.
- [x] `extension.yml` declares every required field and conforms to schema
      version `"1.0"`.
- [x] `LICENSE` (MIT), `README.md`, `CHANGELOG.md`, `.gitignore`, `commands/`
      directory all present.
- [x] Catalog entry JSON validates against
      `contracts/catalog-entry.schema.json` (mirroring the upstream catalog
      entry schema).
- [x] `submission-checklist.ps1` exit 0 — local mirror of the upstream
      automated verification (manifest schema, file presence, URL HTTP 200,
      tag set, description ≤200 chars, semver shape, AI-disclosure paragraph
      present).
- [x] `parity-check.ps1` exit 0 and `validation-pass.ps1` exit 0.
- [x] Full smoke-test suite (17 suites) green.

## AI-assistance disclosure

> Per the AI-disclosure requirement in
> [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md):
> this extension was developed using AI coding assistants. **Claude Code**
> handled design and planning (constitution, spec, clarify, plan, tasks for
> each of the five feature increments); **Codex** handled most of the
> implementation passes (the bridge scripts, the disposition matrix, the
> validation/audit/parity helpers). Every artifact passed human review before
> commit. The bridge's own `validation-pass.ps1` + 17 smoke tests + the
> `submission-checklist.ps1` are the verification surface, all run before this
> PR was opened.

## Contact

Issues and discussion: <https://github.com/lihan3238/speckit-superpowers-bridge/issues>
