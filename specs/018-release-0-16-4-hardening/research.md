# Research: v1.2.0 Release Hardening and Upstream Alignment

**Feature**: `018-release-0-16-4-hardening` | **Date**: 2026-08-18

## R1 — PR #14 is valid but its contract needs a latest-upstream correction

**Decision**: Keep PR #14's implement-hook behavior, add Spec Kit 0.16.4's mandatory-hook directive/actual-invocation language, and run `after_implement` hooks before the handoff transitions to `complete`.

**Rationale**: The contribution fixes a real drop-in gap and its 7-test suite passed. Spec Kit 0.16.4's `templates/commands/implement.md` requires mandatory hooks to emit `EXECUTE_COMMAND: <command>`, actually invoke the hook in the current agent, and wait. Completion is reported only after mandatory post-hooks. Leaving the bridge `complete` before a failing mandatory post-hook would misrepresent the workflow state.

**Alternatives considered**:

- Keep the PR text unchanged: rejected because it was authored against the 0.11.1 baseline and does not encode the current directive contract.
- Mark the handoff complete before post-hooks: rejected because a post-hook failure would leave false-success state.
- Add a deterministic bridge hook runner: rejected because Spec Kit intentionally keeps core-command hook execution agent-driven and Constitution Principle VI forbids shadowing it.

## R2 — Spec Kit's native event subsystem does not replace command lifecycle hooks

**Decision**: Continue composing `before_implement` / `after_implement` from `.specify/extensions.yml` in the bridge execute instructions.

**Rationale**: Spec Kit 0.15.0 added first-class agent-native runtime events, exposed through `specify event run`, for integration events such as session/tool hooks. The 0.16.4 core `implement` template still reads `.specify/extensions.yml` and dispatches command lifecycle hooks through agent instructions. There is no public CLI that emits a core lifecycle event on the bridge's behalf.

**Alternatives considered**:

- Call `specify event run before_implement`: rejected; the command accepts a registered event-command handler, not an extension lifecycle event name.
- Import Spec Kit's internal `HookExecutor` from a bridge script: rejected; that would add a Python/runtime coupling, depend on internal APIs, and still would not invoke agent skills by itself.

## R3 — Use a component-wise portable canonicalizer for missing paths

**Decision**: Replace `realpath -m` with one private Bash helper that starts from an absolute path, collapses `.` / `..`, resolves existing symlink components with portable `readlink`, permits missing suffix components, limits symlink traversal, and prints a normalized absolute path.

**Rationale**: GNU `realpath -m` provides both missing-component tolerance and symlink-aware canonicalization. A purely lexical normalizer would incorrectly classify a repository-contained symlink that targets outside the repository. Python would be simple but would become a new direct bridge runtime dependency. macOS and Linux both provide `readlink`; Bash >=4.0 is already declared by the bridge manifest.

**Alternatives considered**:

- Remove `-m` and use BSD `realpath`: rejected because missing paths would fail.
- Use `python3 -c 'os.path.realpath(...)'`: rejected to keep the bridge runtime dependency set unchanged.
- Lexically collapse path segments only: rejected because existing symlink semantics would regress.
- Require users to install GNU coreutils: rejected because the extension advertises macOS bash support without that prerequisite.

## R4 — Spec Kit 0.16.4 requires a real tracked-source refresh, not only `init`

**Decision**: Refresh the tracked bundled `git` and `agent-context` extension directories from the official 0.16.4 source, install the Codex integration alongside Claude, retain the new managed `.specify/.gitignore`, and restore project-owned bridge skill peers after installer alias collisions.

**Rationale**: `specify init --force` updated core templates and init metadata but left already-installed bundled extension source at older bytes. The 0.16.4 git extension adds branch templates/prefixes, Conventional Commit support, renamed branch scripts, and Python script flavor. Agent-context adds multi-file/self-seeding configuration, path containment hardening, nested-plan discovery, and a Python implementation. These are material tracked-source changes for this repository's own bootstrap.

**Alternatives considered**:

- Leave tracked bundled sources stale because the bridge runtime does not depend on them: rejected; this repository dogfoods Spec Kit and explicitly tracks those sources because `.specify/extensions.yml` references them.
- Treat `.specify/.gitignore` as untracked install state: rejected; upstream scaffolds it as the shared policy that keeps `feature.json` and local overrides machine-local.
- Accept `init` overwriting `.claude/skills/speckit-superpowers-bridge`: rejected; that short peer is a project deliverable, not a generated extension skill.

### Dirty-tree disposition after the 0.16.4 init refresh

| Path | Origin | Disposition |
|---|---|---|
| `.gitignore` | generated-skill catalog gained `speckit-converge` | KEEP |
| `.specify/.gitignore` | new upstream managed local-state policy | KEEP and document |
| `.specify/extensions.yml` | refreshed registered hook priority/prompt metadata | KEEP after extension refresh |
| `.specify/templates/checklist-template.md` | upstream checklist ownership semantics | KEEP |
| `.specify/templates/plan-template.md` | upstream refresh removed project governance callouts | KEEP upstream deltas, REAPPLY project gates |
| `.specify/templates/tasks-template.md` | upstream refresh removed project release example | KEEP upstream deltas, REAPPLY project gate |
| `.claude/skills/speckit-superpowers-bridge/SKILL.md` | generated extension alias overwrote project deliverable | RESTORE from the project-owned orchestrator peer, then apply 018 hook hardening |
| `CLAUDE.md` | managed plan marker | KEEP with corrected 018 plan path |
| `specs/018-release-0-16-4-hardening/` | current feature artifacts | KEEP |

## R5 — Preserve project-owned gates on top of latest templates

**Decision**: Keep upstream 0.16.4 checklist/plan/tasks template updates, then reapply the release-sandbox and Native-First callouts removed by `init --force`.

**Rationale**: Upstream clarified custom-checklist ownership and command placeholders. The project constitution independently requires the release sandbox and native-first gates. Generated upstream refresh must not erase stronger project governance.

**Alternatives considered**:

- Keep the freshly generated templates byte-identical to upstream output: rejected because it would drop mandatory project gates.
- Revert all template changes: rejected because it would miss upstream checklist semantics and template maintenance.

## R6 — Spec Kit 0.11.1 → 0.16.4 audit outcome

**Decision**: Advance the development/verified baseline to 0.16.4 without raising `requires.speckit_version` above `>=0.8.10`.

**Rationale**: Relevant changes are compatible or development-state improvements: agent-context became fully opt-in (already explicitly installed here); core/bundled scripts gained Python flavors; mandatory hook instructions now require actual invocation; git gained branch templates and Conventional Commit support; checklist ownership was clarified; `.specify/.gitignore` became managed; extension manifests gained optional `provides.templates` / `provides.scripts`; integrations gained native runtime events. None changes the bridge's handoff schema, guard API, command namespace, or required shell script interface.

**Alternatives considered**:

- Raise the runtime floor to 0.16.4: rejected because the bridge package still uses only manifest/hook/script capabilities available at the existing floor.
- Add a Python bridge flavor because Spec Kit supports `py`: rejected; no repeated deterministic gap justifies a third bridge implementation.

## R7 — Superpowers 6.3.0 remains compatible at the bridge boundary

**Decision**: Advance the verified Superpowers baseline from 6.0.0 to 6.3.0 after recording the source audit.

**Rationale**: All names the bridge invokes remain present: `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, and `finishing-a-development-branch`. Changes from 6.1.0 through 6.3.0 are internal discipline/harness improvements: lower bootstrap cost, plan-scoped subagent ledgers, positive test-quality guidance, safer branch finishing, event-driven Codex waits, and additional harness support. The bridge passes Spec Kit `tasks.md` and invokes skills by name only.

**Alternatives considered**:

- Retain 6.0.0 evidence indefinitely: rejected because the latest stable source is available and the invoked surface can be audited directly.
- Adopt Superpowers `writing-plans` or `brainstorming` changes: rejected; Spec Kit artifacts remain authoritative by contract.

## R8 — Verification and release sequence

**Decision**: Add a macOS release source/runtime gate, run all local source checks, merge the feature branch, tag v1.2.0, wait for the GitHub release asset, then install that public asset in the Windows and WSL sibling sandboxes before marking the handoff complete.

**Rationale**: The release workflow already gates Linux and Windows before publication. macOS source coverage directly protects Issue #13. The constitution requires published-URL sandbox evidence before handoff completion, not before the tag exists; therefore completion follows publication and sandbox verification.

**Alternatives considered**:

- Claim macOS verification from a Linux stub alone: rejected; the stub is regression coverage, not native-platform evidence.
- Delay Issue #13 to a later patch: rejected; it is a core supported-platform failure and is in scope for this unreleased version.
