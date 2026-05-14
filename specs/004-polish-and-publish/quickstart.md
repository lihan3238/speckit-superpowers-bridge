# Quickstart: Polish & Publish

**Feature**: 004-polish-and-publish
**Audience**: Maintainer or contributor about to validate or extend this feature
**Time**: 15 minutes

## Prerequisites

- Windows with PowerShell 5.1 or 7.x
- `git` ≥ 2.30
- Spec Kit `0.8.9` installed in the repo
- Either Codex or Claude Code as the active agent
- Feature 002's outputs are present (bridge guard, parity-check, disposition matrix, verified-versions)

## 1. Actor resolution

Confirm the new shared resolver works:

```bash
# Explicit override wins
SPECKIT_BRIDGE_ACTOR=codex powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status ready -Actor claude
# Expect: handoff.actor recorded as 'claude' (explicit arg wins)

# Env var fallback
SPECKIT_BRIDGE_ACTOR=codex powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status ready
# Expect: handoff.actor recorded as 'codex'

# default_integration fallback (unset env var)
unset SPECKIT_BRIDGE_ACTOR
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status ready
# Expect: handoff.actor recorded as the project's default_integration (codex on this repo)
```

## 2. Install-state audit

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1 \
  -Json -Actor claude
```

**Expected**: JSON output, `exit_code: 0`, `findings: []`, all integrations OK, git extension installed, no per-agent skill mismatches.

Synthetic divergence test:

```bash
# Append a harmless comment to one agent's bridge skill
echo "" >> .agents/skills/speckit-superpowers-bridge/SKILL.md
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1 -Json
# Expect: structural parity check still passes; content hash diverges but is in the "intentionally diverged" list — exit 0
# Restore:
git checkout .agents/skills/speckit-superpowers-bridge/SKILL.md
```

## 3. Autonomous mode + resume context

```bash
# Enable autonomous mode in the handoff
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1 \
  -Status executing -AutonomousMode 1

# Verify the handoff carries the field
cat .specify/superpowers-handoff.json | grep autonomous_mode
# Expect: "autonomous_mode": true

# Simulate an interrupt by writing a resume_context
# (Normally the bridge skill does this before each Superpowers invocation)
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-skill-invocation.ps1 \
  -SkillId "superpowers:test-driven-development" -Phase "before-implementation-task" -TaskId "T012" -Actor claude

# Now the next session's bridge SKILL.md will emit a one-line resume signal mentioning T012 + the skill
```

## 4. Validation pass (end-to-end)

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1 \
  -Json -Actor claude
```

**Expected**: JSON output with `steps` array, every step `passed: true`, `exit_code: 0`.

If any step fails, the script appends one CG row per finding to `specs/004-polish-and-publish/compat-gaps.md`.

## 5. Bridge SKILL.md explicit invocation rewrite

Visual inspection:

```bash
grep -n 'Skill tool\|superpowers:' .claude/skills/speckit-superpowers-bridge/SKILL.md | head -20
grep -n '\$superpowers-\|superpowers:' .agents/skills/speckit-superpowers-bridge/SKILL.md | head -20
```

**Expected**: each agent's bridge SKILL.md explicitly names the skills to invoke at each named phase (Q1 of clarify), with the agent-native syntax.

## 6. Bilingual README parity

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1
```

**Expected**: `README parity: passed`, exit 0.

Synthetic break:

```bash
# Add a heading to EN that's not in zh-CN
echo "## TEMP heading" >> README.md
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1
# Expect: failed, exit 2, naming the orphan heading
# Restore:
git checkout README.md
```

## 7. Distribution manifest validation

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-distribution-manifest.ps1
```

**Expected**: each `includes:` entry resolves to a real file/glob; no `includes:` path also in `excludes:`; exit 0.

## 8. Routing recommender (US5 P3)

```bash
# Direct invocation with a small-scope description
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1 \
  -Description "fix the typo in README"
# Expect: recommendation = direct-superpowers, reason mentions the matched keyword 'fix'

powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1 \
  -Description "design a new module for authentication with OAuth2 support"
# Expect: recommendation = full-pipeline, no reason mentioned
```

## 9. Run all new tests

```bash
for t in \
  tests/test-actor-resolution.ps1 \
  tests/test-resume-signal.ps1 \
  tests/test-install-state-audit.ps1 \
  tests/test-skill-invocation-event.ps1 \
  tests/test-readme-bilingual-parity.ps1 \
  tests/test-distribution-manifest.ps1 \
  tests/test-routing-recommender.ps1 ; do
  echo "=== $t ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$t"
done
```

**Expected**: every suite prints `<suite>-tests-ok`.

## 10. Compatibility gap log

```bash
type specs/004-polish-and-publish/compat-gaps.md
```

**Expected**: CG-006 (handoff command hardcodes `-Actor codex`) is `CLOSED-IN-FEATURE`. Any newly-discovered gap from a fresh validation pass is recorded with severity and proposed resolution.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Actor resolution always returns `unknown` | `default_integration` empty in `.specify/integration.json` AND env var unset AND no explicit `-Actor` | Set `default_integration` or pass `-Actor` |
| Validation pass reports `skill_invocations_absent` | The bridge SKILL.md hasn't been rewritten to call the explicit Skill tool invocations | Re-apply the rewrite per `contracts/validation-pass-contract.md` |
| README parity fails on heading anchors | Translator added/removed a section | Keep H2 anchors in English on both sides, translate the body |
| Audit reports `skill_content_diverged` for `speckit-superpowers-bridge` | The structural-parity exemption isn't kicking in | Verify the audit script lists `speckit-superpowers-bridge` in its `intentionally_diverged` set |

## Where to read next

- [spec.md](spec.md) — what we're building and why
- [plan.md](plan.md) — design decisions + minimal scope
- [research.md](research.md) — 10 plan-time unknowns and the chosen resolutions
- [data-model.md](data-model.md) — Resume Context, Install-State Audit Report, Skill Invocation Event, Plugin Distribution Manifest entities
- [contracts/](contracts/) — schemas + CLI contracts for every new script
- [compat-gaps.md](compat-gaps.md) — live compatibility-gap log
- `tasks.md` (generated by `/speckit-tasks`) — the ordered work list
- [Primary Design Reference (dev.to article)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)
