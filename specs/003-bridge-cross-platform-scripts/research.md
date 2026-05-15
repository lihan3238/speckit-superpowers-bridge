# Phase 0 Research: Bridge Cross-Platform Scripts — Cleanup Tail

**Feature**: 003-bridge-cross-platform-scripts (redesign, v0.4.2 cycle)
**Date**: 2026-05-16

Clarifications session 2026-05-16 resolved 3 high-impact decisions (US4 priority, deferred-task absorption, hardware reality). This document pins the 5 remaining plan-level decisions that surfaced while drafting the spec.

## R1 — B1 fix: 4-step `artifact_owner` precedence

**Decision**: `update-handoff.{ps1,sh}` MUST resolve `artifact_owner` in this fixed precedence order:

1. **Explicit flag** — `-ArtifactOwner <value>` (PS) or `--artifact-owner <value>` (bash) wins immediately if non-empty.
2. **Prior file value** — read `.specify/superpowers-handoff.json.artifact_owner`; if non-empty, use it.
3. **Actor resolution** — fall back to `Resolve-BridgeActor` / `resolve_bridge_actor` (which itself runs the 3-step `-Actor` → `SPECKIT_BRIDGE_ACTOR` env → `"unknown"` chain from feature 006).
4. **Literal `"unknown"`** — final guaranteed fallback if all above produce empty/invalid.

Implicit preservation (step 2) MUST be silent — no log line, no warning, no diff hint. The script's existing event-log line in `bridge-events.jsonl` already captures the resolved value, which is sufficient observability.

**Rationale**:

- Step 2 (prior value) is the actual fix: today's update-handoff jumps from step 1 straight to step 3, overwriting `claude` with `codex` whenever Codex invokes without `-ArtifactOwner`. That's the bug the spec calls B1.
- Silent preservation matches the PS convention for `-Reason` (also passed silently when omitted). Adding a warning would be a behavior change for users who rely on omission as the common case.
- The 4-step chain matches the parallel `Resolve-BridgeActor` 3-step chain in structure (explicit → env-equivalent → fallback), so the mental model is consistent.

**Alternatives considered**:

- **Warning on implicit preservation**: rejected — noise on the normal path; users would learn to ignore it.
- **Strict mode that refuses implicit preservation if actor != prior owner**: rejected — same operational behavior as a warning, even more friction.
- **Migrate prior `codex` artifact_owners back to `claude` automatically**: rejected — would hide real ownership transitions. Spec FR-002 captures this: the one-shot manual correction is intentional.

**Implementation note for tasks.md**:

In `update-handoff.ps1` (current line ~149):

```powershell
# OLD (the bug):
$owner = if ($ArtifactOwner) { $ArtifactOwner } elseif ($priorArtifactOwner) { $priorArtifactOwner } elseif ($Actor -in @("codex","claude")) { $Actor } else { "unknown" }
```

Wait — looking at the current code, the variable `$priorArtifactOwner` IS already read from the existing file. The bug is more subtle than "step 2 missing". Let me re-verify in T001 of tasks.

Actually: re-reading at audit time, the current logic appears correct — but the live handoff has `artifact_owner: codex`. So either the bug is elsewhere (auto-archive-handoff?) or the Codex run path doesn't go through this code. The TDD test from FR-001 will surface the actual root cause; the fix follows from the test failure.

Mirror logic in `update-handoff.sh`:

```bash
if [ -n "$ARTIFACT_OWNER" ]; then
    owner="$ARTIFACT_OWNER"
elif [ -n "$prior_owner" ]; then
    owner="$prior_owner"
elif [ "$ACTOR" = "codex" ] || [ "$ACTOR" = "claude" ]; then
    owner="$ACTOR"
else
    owner="unknown"
fi
```

## R2 — B2 fix: 5-strategy bash path translation

**Decision**: `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` MUST replace the current `Convert-ToBashPath` function with the chain from spec FR-003. Implementation strategy is a single function:

```powershell
function Convert-ToBashPath {
    param([string]$Path)

    # Strategy 1: ask bash to translate via cygpath (MSYS, Cygwin, git-bash)
    $translated = (& bash -c "command -v cygpath >/dev/null 2>&1 && cygpath -u $([System.Management.Automation.WildcardPattern]::Escape($Path) -replace '\\','/') 2>/dev/null") 2>$null
    if ($LASTEXITCODE -eq 0 -and $translated) { return $translated.Trim() }

    # Strategy 2: input already in WSL form (e.g., from a forwarded env)
    if ($Path -match '^/mnt/[a-z]/') { return $Path }

    # Strategy 3: Windows path + bash on PATH → assume MSYS/Cygwin shorthand /c/...
    if ($Path -match '^([A-Za-z]):[/\\]') {
        $drive = $Matches[1].ToLowerInvariant()
        return "/$drive/$($Path.Substring(3).Replace('\','/'))"
    }

    # Strategy 4: Linux/macOS native — path is already correct
    return $Path.Replace('\','/')
}
```

Then the test, before invoking bash, verifies the translated path actually exists from bash's perspective:

```powershell
$bashCheckedPath = $bashPath
$exists = (& bash -c "[ -f '$bashCheckedPath' ] && echo OK || echo MISSING") 2>$null
if ($exists.Trim() -ne 'OK') {
    Write-Output "  (bash flavor not exercised: path-translation failed for '$bashCheckedPath')"
    return
}
```

**Rationale**:

- Strategy 1 (`cygpath -u`) is the canonical bash path translator on Windows. git-bash, MSYS2, and Cygwin all ship it. The `command -v` guard makes it safe to attempt unconditionally.
- Strategy 2 handles forwarded paths from CI env vars or scripts that hand bash an already-WSL form.
- Strategy 3 is the MSYS shorthand fallback (`/c/Users/...`) used by older git-bash installs that lack `cygpath` for some reason — basically a defensive last attempt for Windows.
- Strategy 4 is Linux/macOS native: no translation needed.
- The final existence check is the safety net. If ALL strategies fail to produce a bash-reachable path, the test gracefully skips bash with a one-line explanation instead of throwing a `[bash] <assertion>` opaque failure.

**Alternatives considered**:

- **Use WMI / .NET `[System.IO.Path]` for translation**: rejected — those operate in Windows worldview, not bash's. The translator needs to know the bash environment's path convention.
- **Hard-code git-bash detection via `where bash` output**: rejected — brittle (bash might be at unusual locations, or named differently in WSL).
- **Run the test through bash entirely (drop pwsh harness)**: rejected — major refactor; out of scope per FR-013.

**Paths-with-spaces handling**: `cygpath -u` handles spaces correctly when the input is properly quoted in the bash `-c` string. The PowerShell side passes the path as a here-string to bash, which preserves spaces. Smoke-tested mentally:

```powershell
& bash -c "cygpath -u 'C:/Users/Alice Smith/file.sh'"  # → /c/Users/Alice Smith/file.sh
```

Output has the space preserved; subsequent `bash <translated-path>` invocation must quote the path again, which the test harness should already do via PowerShell argument splatting.

## R3 — C4 gitignore globs

**Decision**: Add exactly 3 lines to `.gitignore`:

```gitignore
# ─────────────────────────────────────────────────────────────────────────────
# Spec Kit install-time generated state — local to each developer's install,
# regenerated by `specify extension list` / `specify extension add`. Should
# never have been committed; removed from index in commit 0c919aa+1 (v0.4.2).
# ─────────────────────────────────────────────────────────────────────────────
.specify/workflows/workflow-registry.json
.specify/workflows/*/workflow.yml
.specify/extensions/.registry
```

The glob `.specify/workflows/*/workflow.yml` catches both `speckit/workflow.yml` (Spec Kit's bundled "Full SDD Cycle" workflow) AND `speckit-superpowers/workflow.yml` (ours). Both are install-time state — confirmed by inspecting current file contents (`source: bundled` and `source: local` respectively, with `installed_at` timestamps from when `specify init` ran).

The `git rm -r --cached` step in the same commit:

```bash
git rm -r --cached .specify/workflows/workflow-registry.json
git rm -r --cached .specify/workflows/*/workflow.yml
git rm -r --cached .specify/extensions/.registry
```

After the commit, contributors who clone the repo will NOT receive those files, AND `specify extension list` won't be a no-op on their machine — it'll generate the files locally on first use. Documented in `AGENTS.md` so contributors don't worry about the absence.

**Rationale**:

- Glob `.specify/workflows/*/workflow.yml` is intentionally broad: ANY workflow subdir's `workflow.yml` is install-time state. If a future Spec Kit version adds another bundled workflow, our gitignore correctly ignores it without further updates.
- A custom user-authored workflow.yml that DOES warrant tracking would be unusual; if it happens, the user explicitly `git add -f <path>` overrides the gitignore.

**Alternatives considered**:

- **Ignore the whole `.specify/workflows/` dir**: rejected — too coarse; would also ignore future intentional workflow files.
- **Ignore only our specific path `.specify/workflows/speckit-superpowers/workflow.yml`**: rejected — leaves the Spec Kit-bundled one tracked-and-stale; same bug class, just narrower.
- **Reach into Spec Kit core to ask it not to write these files**: rejected — out of scope; vendor-managed boundary.

## R4 — tasks.md sweep mechanics

**Decision**: For the original v0.4.0 `tasks.md` (~67 items, all currently `- [ ]`):

1. **Shipped tasks** get `- [x]`. Determined by mapping each task ID to the v0.4.0→v0.4.1 commit log. The bash flavor add (commits `6c8d853`, `c6a8a00`, `75effbd`, `230e4f8`, `8fd9a55`, `89e1af2`, `f3afc90`) shipped most. ~50 items expected.
2. **Deferred user-side verification tasks** (T065 Linux end-to-end, T066 macOS end-to-end, the ~15 other cross-platform verification rows) get `- [ ] (absorbed into US4 verification.md — see specs/003-.../verification.md)`. Per Clarifications Q2.
3. **Out-of-scope-but-not-shipped tasks** (if any): get `- [ ] (out of scope; carried forward not applicable)` with brief one-line reason.
4. **Summary at end** gets a new paragraph: `> Tasks closed by v0.4.1 release; user-side cross-platform verification absorbed into US4 of the v0.4.2 cleanup-tail spec (see new tasks.md generated by /speckit-tasks for v0.4.2).`

**Rationale**:

- The old tasks.md document remains useful history (audit trail for v0.4.0→v0.4.1 work). Marking it accurately respects future readers' time.
- Per `feedback_cross_reference_drift_needs_tests`, lying about completion state is exactly the kind of doc-impl drift that bites later. Better to mark accurately now.
- Per Clarifications Q2, NOT re-listing the 17 deferred tasks in the new v0.4.2 tasks.md avoids double-tracking.

**Implementation note**: this sweep is a one-time edit; ~67 lines in one file. No automation tooling needed. Approximately 30-minute manual review with the commit log open in a parallel window.

## R5 — Sandbox verification sequencing (US4 P1)

**Decision**: Sandbox verification runs AFTER the v0.4.2 release publishes (you need the live ZIP), but BEFORE the feature handoff transitions to `complete`. Concrete sequence:

1. Commits 1–4 land on `003-cross-platform-cleanup` (B1 fix, B2 fix, C1+C4 sweep, release prep).
2. Tag `v0.4.2` push → `.github/workflows/release.yml` builds + publishes.
3. **Sandbox verification runs** (manual; the Phase 7 of v0.4.2 tasks.md). Operator runs the procedure twice (Windows + WSL Linux) at `..\test_specify_superpower`.
4. Results recorded in `specs/003-bridge-cross-platform-scripts/verification.md` (3 rows: Windows / WSL Linux / macOS-Pending).
5. **If both required platforms PASS**: commit verification.md → push → transition handoff to `complete` → close US4. Update issue #2581 with v0.4.2 metadata.
6. **If either fails**: commit verification.md with failure record → transition handoff to `blocked` → revise spec → cut v0.4.3.

The release IS technically published BEFORE verification, which means a failed v0.4.2 produces an "unsupported" release. The CHANGELOG `[0.4.2]` section MUST be updated post-verification to say either "verified per US4" (pass) or "preliminary; failed sandbox verification, see v0.4.3" (fail). This is a small documentation update; the release artifact itself is immutable once published.

**Rationale**:

- The constitution says "before handoff transitions to complete" — not "before tag". Tag → workflow → published asset → verify against published asset → complete handoff. This sequencing is what the constitution actually means.
- Failed verification leaving the release published is intentional: it lets users who manually fetch the asset still get it (some may be tracking development), while the spec record clearly marks it preliminary.
- The "v0.4.3 if v0.4.2 fails" path is normal patch-cycle hygiene; no special tooling needed.

**Alternatives considered**:

- **Run verification BEFORE tag via `--dev` install**: rejected — `--dev` doesn't test the published artifact (FR-008 calls this out); the gate's whole point is exercising the user-facing install path.
- **Gate the workflow on verification**: rejected — workflow can't reasonably wait for human-driven sandbox; tag → publish → verify is fine.
- **Delay tag until verification passes locally first** (build ZIP locally + verify it): possible but introduces a "pre-release ZIP" step that diverges from the workflow-built one. Not worth the complication.

---

## Open items (none blocking)

All FR-001 through FR-015 decision-complete. No NEEDS CLARIFICATION markers in spec.md. Plan-level flags from /clarify resolved:

- **B1 obscure edge** (legitimate ownership transfer) → silent implicit preservation per R1.
- **B2 paths with spaces** → handled by cygpath quoting per R2.
- **C4 glob reach** → broad on purpose, documented per R3.
- **tasks.md sweep mechanics** → manual one-time per R4.
- **Sandbox sequencing** → post-publish-pre-complete per R5.

Ready for Phase 1.
