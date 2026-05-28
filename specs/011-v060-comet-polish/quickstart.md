# Quickstart — release v0.6.0 in one sitting

For maintainers cutting the v0.6.0 release of `speckit-superpowers-bridge` after this spec lands. Total wall-clock time on a clean WSL bash session: **≈ 30 minutes** (README polish is the dominant chunk; everything else is sub-5-minute).

Steps map onto `docs/release-runbook.md`; the deltas this feature introduces are flagged **[NEW]** and **[CHANGED]**.

---

## Pre-flight (≤ 2 min)

1. Branch is `011-v060-comet-polish` (already created by `/speckit-specify`); `git status` is clean.
2. WSL proxy is reachable: `curl -sI --proxy http://10.88.0.6:10808 https://github.com | head -1` returns `HTTP/2 200`.
3. Required CLI tools: `git`, `bash`, `jq`, `gh` (for release publish), `specify` CLI ≥ 0.8.10 (maintainer is on 0.8.16, that's fine).
4. Open the spec + plan + research + data-model + contracts in a viewer for cross-reference: `code specs/011-v060-comet-polish/`.

---

## Step 1 — Bump bridge version

Edit [`.specify/extensions/speckit-superpowers-bridge/extension.yml`](../../.specify/extensions/speckit-superpowers-bridge/extension.yml):

```diff
 extension:
-  version: "0.5.0"
+  version: "0.6.0"
```

Leave `requires.speckit_version: ">=0.8.10"` UNCHANGED (per FR-006 + research / Clarifications).

**Verify**: `grep '^  version:' .specify/extensions/speckit-superpowers-bridge/extension.yml` shows `"0.6.0"`.

---

## Step 2 — Create verified-versions.json [NEW]

Create [`.specify/extensions/speckit-superpowers-bridge/verified-versions.json`](../../.specify/extensions/speckit-superpowers-bridge/verified-versions.json) per [contracts/verified-versions.schema.json](contracts/verified-versions.schema.json):

```json
{
  "verified_at": "<run: date -u +%Y-%m-%dT%H:%M:%SZ>",
  "spec_kit_version": "0.8.16",
  "superpowers_version": "5.1.0",
  "bridge_version": "0.6.0",
  "notes": "Superpowers v5.1.0 removed /brainstorm /execute-plan /write-plan slash commands and the superpowers:code-reviewer named agent; bridge surface grepped clean (no remediation). finishing-a-development-branch is now provenance-scoped to .worktrees/ — transparent. Spec Kit v0.8.16 changes transparent to bridge consumers."
}
```

**Verify**:

```bash
jq -e '.verified_at and .spec_kit_version and .superpowers_version and .bridge_version and .notes' \
  .specify/extensions/speckit-superpowers-bridge/verified-versions.json
wc -l .specify/extensions/speckit-superpowers-bridge/verified-versions.json  # MUST be ≤ 30
```

---

## Step 3 — Update CHANGELOG

In [`CHANGELOG.md`](../../CHANGELOG.md):

1. Move current `[Unreleased]` section content into a new `[0.6.0] - YYYY-MM-DD` section.
2. Populate the `[0.6.0]` section per [data-model.md Entity 5](data-model.md) (Added / Changed / Compatibility / Upstream notes).
3. Re-add an empty `[Unreleased]` skeleton at the top.
4. Update the link references at the bottom of the file (`[Unreleased]` and `[0.6.0]`).

**Verify**: `head -30 CHANGELOG.md` shows the new `[0.6.0]` heading with today's date and the four required sub-sections.

---

## Step 4 — Polish README + bilingual mirror

Implement per [contracts/readme-structure.md](contracts/readme-structure.md) — both [README.md](../../README.md) and [README.zh-CN.md](../../README.zh-CN.md):

1. Insert centered hero block (R1#1).
2. Insert centered badge row (R1#2 + R3 badge list — labels for Spec Kit + Superpowers verified-version reflect this release: `0.8.16` and `5.1.0`).
3. Insert H1 + language-toggle blockquote (R1#3 + R1#4).
4. Insert bold value-prop + division-of-labor paragraphs (R1#5 + R1#6).
5. Insert `## Why` section (R1#7).
6. Insert `## Quick Start` BEFORE `## Installation` (R1#8) with one `> [!TIP]` callout per research D7.
7. Insert `## Positioning` table (R1#9) per [research D2](research.md#d2--positioning--comparison-table-column--row-choices).
8. Wrap existing factual sections in `<details>` blocks (R1#10) per [research D3](research.md#d3--which-existing-readme-sections-collapse-to-details-vs-stay-open).
9. Preserve `## Contributing and License` at the bottom (R1#11).
10. Translate prose to natural Chinese in `README.zh-CN.md`; commands/paths/code blocks stay English.

**Verify**:

```bash
# Section counts identical
diff <(grep -c '^## ' README.md) <(grep -c '^## ' README.zh-CN.md)
# <details> counts identical
diff <(grep -c '<details>' README.md) <(grep -c '<details>' README.zh-CN.md)
# Quick Start before Installation
test "$(grep -n '^## ' README.md | head -2 | tail -1 | cut -d: -f1)" -lt "$(grep -n '^## Installation' README.md | cut -d: -f1)"
```

---

## Step 5 — Decouple catalog download_url [CHANGED]

Edit [`marketplace/catalog-entry.json`](../../marketplace/catalog-entry.json) per [contracts/catalog-entry-shape.md](contracts/catalog-entry-shape.md):

```diff
-  "version": "0.5.0",
+  "version": "0.6.0",
   ...
-  "download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.5.0/speckit-superpowers-bridge-v0.5.0.zip",
+  "download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip",
```

**Verify**: `jq -r '.version, .download_url' marketplace/catalog-entry.json` shows `0.6.0` and the `/releases/latest/` URL.

---

## Step 6 — Retire the download_url runbook step [CHANGED]

Edit [`docs/release-runbook.md`](../../docs/release-runbook.md):

- Remove or replace any step that says "edit `marketplace/catalog-entry.json.download_url` to v<X.Y.Z> URL".
- Replace with: "**`download_url` is permanently set to the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias as of v0.6.0. Do NOT edit per release.** Only update `version`."
- Add a "verify after publish" line at the appropriate step: `curl -fsLI https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip` and expect `200 OK` after redirect chain.

**Verify**: `grep -n 'download_url' docs/release-runbook.md` shows the new wording, not the old per-release edit instruction.

---

## Step 7 — Run smoke tests

```bash
bash tests/run-all.sh
```

**Verify**: every test ends `…-tests-ok`. Allowed delta: ≤ 5 lines across the test suite for version-string updates (e.g., a test that asserts catalog version equals bridge version). No new test files; SC-009 budget.

---

## Step 8 — Build the dist ZIP

Follow the existing runbook packaging step (no change in this feature):

```bash
# (example — actual command per release-runbook)
cd .specify/extensions/speckit-superpowers-bridge && zip -r ../../../dist/speckit-superpowers-bridge-v0.6.0.zip . && cp ../../../dist/speckit-superpowers-bridge-v0.6.0.zip ../../../dist/speckit-superpowers-bridge.zip
```

**Verify**: both `dist/speckit-superpowers-bridge-v0.6.0.zip` and `dist/speckit-superpowers-bridge.zip` exist with identical SHA256.

---

## Step 9 — Commit on `011-v060-comet-polish`, open PR

```bash
git add -A
git commit -m "feat(011): v0.6.0 — README polish + verified-versions + catalog URL decoupling"
git push -u origin 011-v060-comet-polish
gh pr create --title "v0.6.0 — Comet-style README polish + upstream alignment" --body "$(cat <<'EOF'
## Summary
- README + zh-CN polish to hero-led + badged + collapsed-details layout (Comet-style structural pattern)
- New verified-versions.json artifact (5-field schema locked, ≤ 30 lines)
- Bridge version 0.5.0 → 0.6.0 (extension.yml + catalog-entry.json + CHANGELOG)
- Catalog download_url DECOUPLED to /releases/latest/ stable-alias (one-shot freeze)
- Zero new script lines, zero new SKILL.md behavioral lines, zero new hooks/commands

## Constitution check
- Principle VI Native-First gate answers in plan.md: Q1+Q2 both "no" → 1 new file justified
- SC-010 lightness budget codified and met

## Test plan
- [ ] bash tests/run-all.sh green on WSL
- [ ] jq schema check on verified-versions.json passes
- [ ] README structural smoke (sections / badges / Quick Start order) passes
- [ ] End-User Verification Sandbox run on WSL bash (constitution §sandbox gate) recorded in verification.md
EOF
)"
```

---

## Step 10 — Tag and publish release

After PR merge to `main`:

```bash
git checkout main && git pull
git tag -a v0.6.0 -m "v0.6.0 — Comet-style README polish + upstream alignment"
git push origin v0.6.0
gh release create v0.6.0 \
  dist/speckit-superpowers-bridge-v0.6.0.zip \
  dist/speckit-superpowers-bridge.zip \
  --title "v0.6.0" --notes-file - <<'EOF'
See CHANGELOG.md `[0.6.0]` section for full details.

### Highlights

- README polished to hero-led + badged layout
- New `verified-versions.json` artifact tracks the Spec Kit + Superpowers verified pair (this release: Spec Kit 0.8.16 + Superpowers 5.1.0)
- Marketplace `download_url` decoupled to `/releases/latest/...` — never updated per release again
- Zero behavior changes; bridge scripts byte-identical to v0.5.0

### Upstream notes (informational only)

- Superpowers v5.1.0 removed `/brainstorm`, `/execute-plan`, `/write-plan` slash commands. Bridge unaffected — invocations use skill names.
- Superpowers v5.1.0 removed `superpowers:code-reviewer` named agent. Bridge unaffected — uses `superpowers:requesting-code-review` skill.
- Superpowers `finishing-a-development-branch` is now provenance-scoped to `.worktrees/`. Transparent to the bridge.
EOF
```

**Verify after publish**:

```bash
curl -fsLI https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip | head -3
# Expect 302 → 200 chain
```

---

## Step 11 — Sandbox verification (constitution §"End-User Verification Sandbox" gate)

Per constitution v1.2.0+:

1. `cd ../test_specify_superpower && specify init . --integration claude --script sh --here --force`
2. `specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`
3. Drive one complete cycle: `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → bridge handoff → `/speckit-superpowers-bridge` → complete.
4. Record outcome in `specs/011-v060-comet-polish/verification.md` (per FR-015): bridge SHA256, platform = WSL bash, pass/fail per acceptance scenario.

**Verify**: handoff transitions cleanly to `complete`; no guard rule fires unexpectedly; no script errors.

---

## Step 12 — Move handoff to `complete`

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status complete --actor claude
```

The bridge-state output should confirm `Pending tasks: 0` and no warnings about unchecked tasks remaining.

---

**Release wrap-up**: Mark the feature `[x]` done in `tasks.md`, close the PR, and you're done. Next release (v0.7.0+) only touches `extension.yml.version`, `catalog-entry.json.version`, `verified-versions.json`, and `CHANGELOG.md` — the README structural work landed in v0.6.0 carries forward unchanged.
