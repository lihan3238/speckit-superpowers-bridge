# Quickstart Validation: Spec Kit 0.10.x Alignment (v1.0.3)

How to prove this feature works end-to-end. Run from the repo root on WSL2
bash unless stated otherwise.

## Prerequisites

- Spec Kit CLI 0.10.2: `specify version` → `0.10.2`
- `jq`, `gh`, `git` available; WSL proxy exported for network steps
- Sandbox directory `../test_specify_superpower` exists (sibling of this repo)

## 1. Docs alignment (FR-001, FR-002, SC-001, SC-005)

```bash
# No stale version floors or removed flags outside CHANGELOG/specs history:
grep -n "0\.9\.1+\|verified_0\.9\.3\|--ai-skills\|--ai-commands-dir\|--no-git" \
  AGENTS.md README.md README.zh-CN.md
# EXPECTED: no output (CHANGELOG.md and specs/ are exempt)

# Bootstrap table names 0.10.x and the git extension add step:
grep -n "0\.10\." AGENTS.md | head
grep -n "specify extension add git" AGENTS.md
# EXPECTED: both present
```

## 2. Manifest metadata (FR-003, SC-002)

```bash
grep -n "category:\|effect:" .specify/extensions/speckit-superpowers-bridge/extension.yml
# EXPECTED: category: process / effect: read-write
jq -r '.category, .effect, .version' marketplace/catalog-entry.json
# EXPECTED: process / read-write / 1.0.3

# Round-trip through the 0.10.2 validator (scratch project):
T=$(mktemp -d) && cp -r .specify/extensions/speckit-superpowers-bridge "$T/" \
  && cd "$T" && specify init scratch --integration claude --script sh \
  && cd scratch && specify extension add --dev "$T/speckit-superpowers-bridge" \
  && specify extension info speckit-superpowers-bridge | grep -E "Category|Effect"
# EXPECTED: Category: process / Effect: read-write; then clean up "$T"
```

## 3. Evidence + release integrity (FR-004…FR-007, SC-003)

```bash
jq -r '.speckit_version // .verified.speckit // empty' \
  .specify/extensions/speckit-superpowers-bridge/verified-versions.json
# EXPECTED: a 0.10.2 evidence row present (exact key per file's existing shape)

bash tests/run-all.sh
# EXPECTED: "All 6 bash smoke tests passed."
```

## 4. End-user sandbox verification (SC-004; constitution release gate)

After v1.0.3 is published:

```bash
cd ../test_specify_superpower
mkdir v1-0-3-linux-$(date -u +%Y%m%dT%H%M%SZ) && cd $_
specify init --here --integration claude --script sh
specify extension add https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
specify extension list   # EXPECTED: bridge enabled, 3 commands / 5 hooks, v1.0.3
# Drive one bridge cycle: guard → handoff ready → executing → complete → archive
# Record outcomes in specs/014-speckit-0-10-x-alignment/verification.md
```

## Done When

- All four sections produce their EXPECTED outputs
- `verification.md` records the sandbox run with dates, versions, and outcomes
- Handoff transitions to `complete` only after section 4 is recorded
