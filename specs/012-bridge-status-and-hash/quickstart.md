# Quickstart — v0.7.0 Implementation Walkthrough

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Contracts**: [contracts/](./contracts/) | **Date**: 2026-05-28

This is the maintainer's step-by-step walkthrough for implementing and verifying feature 012 on WSL bash. It complements `/speckit-tasks` (which will generate the dependency-ordered task list) by showing the human-paced order in which the engineer working the branch should approach the work. Each step lists what to touch, the contract it satisfies, and the verification command.

## Pre-flight

1. Branch `012-bridge-status-and-hash` checked out, `git status` clean (only the specs/012-* artifacts from /speckit-specify and /speckit-plan tracked).
2. WSL bash with `jq` ≥ 1.6 and `sha256sum` from GNU coreutils 8+ available. Verify:
   ```bash
   command -v jq && command -v sha256sum && jq --version && sha256sum --version | head -1
   ```
3. WSL HTTPS proxy reachable per CLAUDE.md (needed for the sandbox install in Step 12):
   ```bash
   curl -sI --proxy http://10.88.0.6:10808 https://github.com | head -1
   # Expect: HTTP/2 200
   ```
4. Open all design artifacts side-by-side: `code specs/012-bridge-status-and-hash/`.

## Step 1 — Schema delta first (FR-009)

Edit [specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json](../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json) to add the `artifacts_sha256` property and the conditional `required` rule per [contracts/handoff-v1.1.delta.md](./contracts/handoff-v1.1.delta.md). Keep `schema_version` integer range and `additionalProperties: true` unchanged.

Verify:

```bash
jq -e '.properties.artifacts_sha256.properties["tasks.md"].pattern == "^[0-9a-f]{64}$"' \
  specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json
```

## Step 2 — Shared print helper extension

Edit `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh` to expose the existing `[bridge state]` formatter with an optional `--with-recommendation` flag that toggles the `Drift:` and `Next:` lines. Mirror in `.../powershell/bridge-state.ps1`.

This satisfies [research D4](./research.md#d4--print-contract-who-emits-the-new-drift-and-next-lines): only callers that pass the flag get the new lines. Existing callers (`update-handoff`, `guard-command`) DO NOT pass it, preserving SC-008.

Verify: run the existing 008 smoke tests (whatever portion of `tests/test-*.sh` exercises `update-handoff` and `guard-command`); their output must remain byte-identical to v0.6.0.

```bash
bash tests/run-all.sh 2>&1 | tee /tmp/preimpl-tests.log
# All existing tests still green.
```

## Step 3 — `update-handoff` hash logic (FR-005 / FR-006 / FR-008)

Edit `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh` to:

1. On any `executing` or `complete` write, compute the SHA256 of `<feature_dir>/spec.md`, `<feature_dir>/plan.md`, `<feature_dir>/tasks.md`. Use `sha256sum <file> | awk '{print $1}'` for each; emit `null` (JSON) when the file does not exist.
2. Merge the result into the handoff JSON as `artifacts_sha256: {...}` via `jq --argjson … '. + {artifacts_sha256: $h}'`.
3. On `complete` writes only, read the prior handoff (before merging the fresh hashes), compare per-file, and on any mismatch:
   - Write the stderr warning line per [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md) R-EVT-5.
   - Append the `artifact_drift_detected` event to `.specify/bridge-events.jsonl` per [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md).
4. Preserve exit code 0.

Mirror in `.../powershell/update-handoff.ps1` using `Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash | ForEach-Object { $_.ToLower() }`.

Track line counts: each delta must stay ≤ 60 added lines (SC-010 c/d). Use `git diff --stat` to track:

```bash
git diff --stat .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh
```

## Step 4 — `bridge-status` helper (FR-001 / FR-002 / FR-003 / FR-004 / FR-007)

Create `.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh`. Implementation order inside the script:

1. Argument parsing (`--json`, `--actor`, `--no-drift-check`). Borrow the case-loop pattern from `guard-command.sh`.
2. Repo-root resolution + actor resolution via the existing helpers.
3. Read `.specify/superpowers-handoff.json` — handle the three cases: missing (FR-004 exit 0 + S-OUT-3 output), present-and-parseable (normal path), present-but-malformed (FR-004 exit 3 + S-OUT-4 output).
4. Compute pending-tasks count using the same regex as `update-handoff`'s existing logic (extract it into `bridge-state.sh` to avoid duplication).
5. If `artifacts_sha256` present in handoff AND `--no-drift-check` not set, compute drift by re-hashing the live files and comparing. Build the `Drift:` line.
6. Evaluate the decision table from [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md) — inline case/if chain in rule order 1..12. Build the `Next:` line.
7. Call `bridge-state.sh --with-recommendation` (or assemble the block locally if cleaner) and print. If `--json`, format the JSON object instead.

Mirror in `.../powershell/bridge-status.ps1`. Total per flavor: ≤ 200 lines (SC-010 a/b).

Smoke-verify manually:

```bash
# Should work even before tests/test-bridge-status.sh exists
.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
# Expect 7-line block (or 6-line if no artifacts_sha256 yet) ending in Next: <recommendation>

.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --json | jq .
# Expect JSON object with 8 keys
```

## Step 5 — SKILL.md mentions (FR-011)

Edit `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md`. Add exactly ONE line in each — under any existing "useful commands" / playbook section, or appended as a one-line note. Suggested wording:

```
- `bridge-status.{sh,ps1}` (v0.7.0+) — read-only state introspection + recommended-next-command + drift detection.
```

Diff hard-cap: 1 line per file. Verify:

```bash
git diff --stat .claude/skills/speckit-superpowers-bridge/SKILL.md \
                .agents/skills/speckit-superpowers-bridge/SKILL.md
# Each file shows " | 1 +" (or similar; never 2+)
```

## Step 6 — README polish (FR-014)

Append a short bullet to the existing collapsed "Skills" or "Commands" section of [README.md](../../README.md) and the mirror in [README.zh-CN.md](../../README.zh-CN.md). Cap: ≤ 13 + ≤ 12 = ≤ 25 lines combined.

Suggested EN wording (1 line):

> - `bridge-status` (v0.7.0+) — `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` prints the current bridge state, drift, and recommended next command in under a second.

Mirror in zh-CN.

## Step 7 — Version bumps (FR-014)

1. `.specify/extensions/speckit-superpowers-bridge/extension.yml`: `version: 0.6.0 → 0.7.0`.
2. `marketplace/catalog-entry.json`: `version: 0.6.0 → 0.7.0`. **Do NOT touch `download_url`** (permanently decoupled per v0.6.0 — see [011 research D6](../011-v060-comet-polish/research.md)).
3. `CHANGELOG.md`: prepend a `## [0.7.0] — 2026-MM-DD` section with `### Added` (bridge-status, artifacts_sha256, artifact_drift_detected event) and `### Compatibility` (pre-0.7.0 handoffs tolerated; schema_version stays 1).

## Step 8 — Smoke-test file (FR-012)

Create `tests/test-bridge-status.sh` covering:

- **A-OUT-1..5** from [contracts/bridge-status-output.md](./contracts/bridge-status-output.md) acceptance scenarios.
- **S-EVT-1..6** from [contracts/artifact-drift-event.md](./contracts/artifact-drift-event.md).
- **V1..V14** decision-table vectors from [contracts/next-command-decision-table.md](./contracts/next-command-decision-table.md).
- Pre-0.7.0 fixture test (SC-009) — load `tests/fixtures/pre-070-handoff.json`, assert no crash + no false-positive drift.
- Performance assertion: `time bash tests/test-bridge-status.sh` total ≤ 2s (slack against the 10s suite ceiling).

Also create `tests/fixtures/pre-070-handoff.json` — a literal v0.5.0-shaped handoff with `status: executing`, no `artifacts_sha256` field. Use one of the existing 008 fixtures as a template if available; otherwise hand-author it.

Verify the new test stays green and the existing 12 tests still pass:

```bash
time bash tests/run-all.sh
# Expect: all green, total wall time < 10s
```

## Step 9 — Commit on `012-bridge-status-and-hash`, open PR

```bash
git add -A specs/012-bridge-status-and-hash/ \
            specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json \
            .specify/extensions/speckit-superpowers-bridge/scripts/ \
            .specify/extensions/speckit-superpowers-bridge/extension.yml \
            marketplace/catalog-entry.json \
            CHANGELOG.md \
            README.md README.zh-CN.md \
            .claude/skills/speckit-superpowers-bridge/SKILL.md \
            .agents/skills/speckit-superpowers-bridge/SKILL.md \
            tests/test-bridge-status.sh tests/fixtures/pre-070-handoff.json
git commit -m "$(cat <<'EOF'
feat(012): v0.7.0 — bridge-status command + SHA256 handoff artifact hash

- New read-only bridge-status.{sh,ps1} helper: prints [bridge state] block
  + Drift + Next recommendation, derived from a 12-cell decision table.
- update-handoff.{sh,ps1} snapshots SHA256 of spec/plan/tasks.md on
  executing/complete writes; complete-write drift fires stderr warning +
  artifact_drift_detected event.
- v1 schema gains optional artifacts_sha256 field (additive; schema_version
  stays 1; pre-0.7.0 handoffs tolerated read-side).
- Bridge version 0.6.0 -> 0.7.0; catalog download_url unchanged (v0.6.0
  stable-alias decoupling holds).
- Lightness budget per SC-010: 2 new helpers (each <= 200 LoC), <= 60 added
  LoC per flavor in update-handoff, 1 new test file + 1 fixture, 0 new
  state files, 0 edits to vendor-managed speckit-* skills.

Constitution VI gate: Q1 ("does upstream do this?") = no for both pillars;
Q2 ("is upstream the right place?") = no for both. See plan.md.
EOF
)"
git push -u origin 012-bridge-status-and-hash
gh pr create --title "v0.7.0 — bridge-status command + SHA256 handoff artifact hash" \
  --body "$(cat <<'EOF'
## Summary

- New read-only `bridge-status.{sh,ps1}` helper — on-demand bridge state introspection with `Drift:` and `Next:` recommendation lines.
- New optional `artifacts_sha256` field on the handoff (additive on v1 schema) — SHA256 snapshots of spec/plan/tasks.md taken on executing/complete writes.
- New `artifact_drift_detected` event in `bridge-events.jsonl` + stderr warning when complete-write detects drift from the executing snapshot.

## Test plan

- [ ] `bash tests/run-all.sh` — all 13 tests green, total < 10s (SC-006).
- [ ] `bridge-status` invocations match the 14 V1..V14 vectors in `contracts/next-command-decision-table.md` (SC-004).
- [ ] Drift injection (modify tasks.md mid-execution) → stderr warning + event log entry on complete write (SC-002).
- [ ] Two consecutive `bridge-status` invocations produce byte-identical output (SC-003).
- [ ] Pre-0.7.0 fixture (`tests/fixtures/pre-070-handoff.json`) → bridge-status exits 0, no false-positive drift, no crash (SC-009).
- [ ] Constitution VI gate Q1+Q2 answers both "no" for both pillars (recorded in plan.md).
- [ ] End-user sandbox verification in `..\test_specify_superpower` on WSL bash (Step 12 below) — outcome recorded in `specs/012-bridge-status-and-hash/verification.md` (SC-007, FR-015).
EOF
)"
```

## Step 10 — Cut the v0.7.0 release tag

```bash
git fetch origin
git checkout main && git pull --ff-only
git tag -a v0.7.0 -m "v0.7.0 — bridge-status command + SHA256 handoff artifact hash"
git push origin v0.7.0
```

Then build + upload the release ZIP per the existing `docs/release-runbook.md` flow. The catalog `download_url` is permanently aliased to `releases/latest/download/speckit-superpowers-bridge.zip` per v0.6.0 — no per-release edit needed.

## Step 11 — End-User Verification Sandbox (FR-015 + SC-007 + Constitution §"End-User Verification Sandbox")

In `..\test_specify_superpower` on WSL bash:

```bash
cd ../test_specify_superpower
# Fresh reset
git checkout . && git clean -fdx
specify init . --integration claude --script sh --here --force
specify extension add speckit-superpowers-bridge --from \
  https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
# Cycle 1: full bridge flow
/speckit-specify "trivial feature to exercise bridge-status"
# (run /speckit-clarify if NEEDS CLARIFICATION markers appear; skip otherwise)
/speckit-plan
/speckit-tasks
# Hand off, then exercise bridge-status before and during executing
.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh \
  --status executing --actor claude --reason "sandbox cycle"
.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
# Inject drift: append a line to tasks.md
printf '\n- [ ] T999 injected drift\n' >> specs/<feature>/tasks.md
.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
# Expect: Drift: tasks.md
# Now complete the handoff — drift should fire
.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh \
  --status complete --actor claude --reason "sandbox cycle complete"
# Expect: stderr warning line + new artifact_drift_detected event in .specify/bridge-events.jsonl
```

Record outcome in [verification.md](./verification.md):

- Bridge SHA256 (`sha256sum <downloaded ZIP>`).
- Platform: WSL bash.
- Pass/fail per scenario:
  - US1 — S-OUT-1, S-OUT-3, S-OUT-5 (3 of 5 acceptance scenarios chosen for fast end-to-end coverage).
  - US2 — S-EVT-1, S-EVT-5, S-EVT-6 (3 of 5 covering: drift fires; no drift = no event; pre-0.7.0 tolerated).
- Resulting `bridge-events.jsonl` snippet (last 5 lines).
- Resulting stderr warning text.

Per FR-015, the verification record MUST exist before this feature's handoff transitions to `complete`.

## Step 12 — Update CLAUDE.md SPECKIT marker (auto)

`/speckit-plan` updates the `<!-- SPECKIT START -->` / `<!-- SPECKIT END -->` block in CLAUDE.md to point at this plan. Nothing to do manually; verify via:

```bash
sed -n '/<!-- SPECKIT START -->/,/<!-- SPECKIT END -->/p' CLAUDE.md
```

## Verification matrix at PR-merge time

| Gate | Source | Pass condition |
|---|---|---|
| All FRs implemented | spec.md FR-001..FR-015 | git grep for each FR's named artifact returns the expected files |
| Lightness budget | spec.md SC-010 (a..i) | line-count checks pass; no files outside the allow list changed |
| Sandbox verified | Constitution §"End-User Verification Sandbox" | `verification.md` records pass on WSL bash |
| 008 print contract intact | SC-008 | existing tests 008/* green |
| Pre-0.7.0 handoffs OK | SC-009 | fixture test green |
| Tests pass | SC-006 | `time bash tests/run-all.sh` < 10s and all green |
| Constitution VI gate | plan.md §Native-First gate | Q1+Q2 both "no" for both pillars — documented in plan.md |
| Schema delta merged | FR-009 | `jq -e` query in Step 1 passes against the schema file |
| Decision-table exhaustive | SC-004 | all 14 V vectors in the new test pass |
