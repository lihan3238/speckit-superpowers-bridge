# Quickstart: Fire speckit.implement before/after hooks from the bridge

**Feature**: `017-fire-implement-hooks`

## Run the smoke suite

```bash
bash tests/run-all.sh
# EXPECTED: "All 7 bash smoke tests passed."
```

The new `test-implement-hooks-dispatch.sh` asserts the hook-dispatch contract is
present in `execute.md` and both per-agent SKILL peers:

```bash
bash tests/test-implement-hooks-dispatch.sh
# EXPECTED: "implement-hooks-dispatch-tests-ok (bash)"
```

## Manual contract check

Confirm the three files carry the dispatch rules:

```bash
grep -n 'before_implement\|after_implement\|Skip any hook whose' \
  .specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md \
  .agents/skills/speckit-superpowers-bridge/SKILL.md \
  .claude/skills/speckit-superpowers-bridge/SKILL.md
```

## Release-readiness (version grounds)

```powershell
# Windows PowerShell — validates all seven release-checklist files carry 1.2.0.
.\scripts\release\validate-release-readiness.ps1 -Version 1.2.0
```

## End-user verification (deferred to release)

After the v1.2.0 ZIP is published, verify live in `../test_specify_superpower`:

1. Register a dummy `before_implement` and `after_implement` hook in
   `.specify/extensions.yml`.
2. Drive one full bridge cycle (`/speckit-specify` → … → `/speckit-tasks` →
   bridge execution).
3. Confirm both hooks fire (before the `executing` transition and after
   `complete`), and that the bridge's own `before_implement` guard does **not**
   fire.
