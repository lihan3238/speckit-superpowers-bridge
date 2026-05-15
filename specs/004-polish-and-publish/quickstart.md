# Quickstart: Polish & Publish

**Feature**: 004-polish-and-publish
**Audience**: Maintainer or contributor validating feature 004
**Time**: 15 minutes

## Prerequisites

- Windows with PowerShell 5.1 or 7.x
- `git` 2.30+
- Spec Kit 0.8.9 in the repo
- Codex or Claude Code integration installed
- Feature 002 outputs present: bridge guard, parity check, disposition matrix, verified versions

## 1. Actor resolution

```powershell
$env:SPECKIT_BRIDGE_ACTOR = "codex"
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor claude

$env:SPECKIT_BRIDGE_ACTOR = "codex"
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready

$env:SPECKIT_BRIDGE_ACTOR = ""
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready
```

Expected: explicit `-Actor` wins, then `SPECKIT_BRIDGE_ACTOR`, then `.specify/integration.json.default_integration`, then `unknown`.

## 2. Install-state audit

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json -Actor codex
```

Expected: JSON output with `exit_code: 0`, installed integrations, git extension state, and no missing per-agent skills. P2 `skill_content_diverged` findings may appear for generated Codex/Claude skills because invocation syntax differs; the remediation is `specify integration upgrade codex` and `specify integration upgrade claude`.

## 3. Autonomous mode and resume context

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status executing -AutonomousMode $true
(Get-Content .specify\superpowers-handoff.json -Raw | ConvertFrom-Json).autonomous_mode

.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\emit-skill-invocation.ps1 `
  -SkillId "superpowers:test-driven-development" `
  -Phase "before-implementation-task" `
  -TaskId "T012" `
  -Actor codex
```

Expected: `autonomous_mode` is true and a `skill_invocation` event is appended.

## 4. Validation pass

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json -Actor codex
```

Expected: `exit_code: 0`, every step passed, and no P0/P1 compatibility gaps.

## 5. Explicit Superpowers invocation wording

```powershell
Select-String -Path .claude\skills\speckit-superpowers-bridge\SKILL.md -Pattern 'Skill tool|superpowers:' | Select-Object -First 20
Select-String -Path .agents\skills\speckit-superpowers-bridge\SKILL.md -Pattern '\$superpowers-|superpowers:' | Select-Object -First 20
```

Expected: both bridge skill files explicitly name `superpowers:test-driven-development`, `superpowers:systematic-debugging`, `superpowers:verification-before-completion`, `superpowers:requesting-code-review`, and `superpowers:finishing-a-development-branch`.

## 6. Bilingual README parity

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\check-readme-bilingual-parity.ps1
```

Expected: `README parity: passed`, exit 0.

## 7. Distribution manifest validation

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\check-distribution-manifest.ps1

$target = Join-Path $env:TEMP "speckit-bridge-install-smoke"
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\check-distribution-manifest.ps1 -SimulateInstall $target
Remove-Item $target -Recurse -Force
```

Expected: manifest passes and simulated install copies only manifest-listed plugin assets, not `specs/`, `bridge-events.jsonl`, snapshots, or handoff state.

## 8. Routing recommender

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\recommend-route.ps1 -Description "fix the typo in README" -Json
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\recommend-route.ps1 -Description "design a new module for authentication with OAuth2 support" -Json
```

Expected: first output recommends `direct-superpowers`; second output recommends `full-pipeline`.

## 9. Run all feature 004 tests

```powershell
$tests = @(
  "tests/test-actor-resolution.ps1",
  "tests/test-resume-signal.ps1",
  "tests/test-install-state-audit.ps1",
  "tests/test-skill-invocation-event.ps1",
  "tests/test-readme-bilingual-parity.ps1",
  "tests/test-distribution-manifest.ps1",
  "tests/test-routing-recommender.ps1",
  "tests/test-validation-pass.ps1"
)

foreach ($t in $tests) {
  Write-Host "=== $t ==="
  & $t
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: every suite prints `<suite>-tests-ok`.

## 10. Compatibility gap log

```powershell
Get-Content specs\004-polish-and-publish\compat-gaps.md
```

Expected: CG-006 is `CLOSED-IN-FEATURE`. Any newly discovered gap from validation is recorded with severity and proposed resolution.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Actor resolution returns `unknown` | No explicit actor, no env var, no default integration | Set `SPECKIT_BRIDGE_ACTOR` or run `specify integration use <agent>` |
| Validation reports `skill_invocations_absent` | No recent explicit Superpowers skill event | Run bridge execution or seed the relevant `emit-skill-invocation.ps1` event before validation |
| README parity fails | Heading or code-fence drift between languages | Keep identical English anchor headings in both files |
| Distribution check reports conflict | Simulated target has a user-modified file | Merge manually; the bridge intentionally refuses to clobber |

## Where to read next

- [spec.md](spec.md)
- [plan.md](plan.md)
- [research.md](research.md)
- [data-model.md](data-model.md)
- [contracts/](contracts/)
- [compat-gaps.md](compat-gaps.md)
- [tasks.md](tasks.md)
