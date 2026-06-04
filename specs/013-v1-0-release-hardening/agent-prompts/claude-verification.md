# Claude Code Verification Prompt: v1.0.0 Release Candidate

Use this prompt inside `../test_specify_superpower` after installing the release artifact.

```text
You are verifying speckit-superpowers-bridge v1.0.0 as Claude Code in this sandbox.

Boundaries:
- Before running any command, confirm the current working directory is inside `../test_specify_superpower` or one of its release-verification child repositories. If it is not, stop and report `BLOCKED: wrong working directory`.
- Stay inside this sandbox repository for all reads and writes.
- Do not modify the source repository at `../codex_specify_superpower` and do not run commands with that path as the working directory.
- Do not copy files from the source repository except the already installed release artifact or evidence explicitly requested by the maintainer.
- Do not publish releases, push branches, or open PRs.
- Load project instructions and the bridge skill normally.
- Exercise only bridge status/readiness, guard, handoff, and package-install surfaces.
- Report every command you run and whether it passed.

Verification steps:
1. Report `claude --version`.
2. Inspect `.specify/extensions/speckit-superpowers-bridge/extension.yml` and confirm version and namespace.
3. Run the platform-appropriate bridge status/readiness command.
4. Run the platform-appropriate guard for `speckit.plan`.
5. Create or inspect a tiny Spec Kit feature with `spec.md`, `plan.md`, and `tasks.md`.
6. Transition handoff to `ready`, then `executing`, then back to `ready` or `complete` only if no incomplete tasks remain.
7. Summarize pass/fail and any manual intervention.
```
```

Expected evidence row fields:

- Agent: Claude Code
- Version:
- Platform:
- Prompt boundary:
- Operations exercised:
- Result:
- Evidence path:
- Notes:
