# Quickstart: New WSL Developer Walkthrough

**Feature**: `009-wsl-dev-env-alignment` | **Plan**: [plan.md](./plan.md)

This is the walkthrough a new developer follows on a fresh WSL2 Ubuntu host after this feature lands. Time budget: under 5 minutes from `git clone` to "I can run the smoke tests".

---

## Prerequisites (one-time, per WSL host)

```bash
# 1. Verify base tools
git --version
bash --version | head -1
gh --version | head -1
jq --version

# 2. Install specify CLI if missing
pipx install specify-cli || pip install --user specify-cli
specify --version  # expect: specify 0.8.10+
```

If `gh` or `jq` is missing, install via apt: `sudo apt install -y gh jq`.

---

## Clone and bootstrap

```bash
# 1. Clone
git clone https://github.com/lihan3238/speckit-superpowers-bridge.git
cd speckit-superpowers-bridge

# 2. Sanity-check the clean state (this verifies the FR-002 + FR-005 outcome)
git status
# Expected: "nothing to commit, working tree clean"

# 3. Regenerate the gitignored install-state for your chosen flavor
specify init --here --script sh --force
# Replace `sh` with `ps` if you prefer the PowerShell flavor on WSL with pwsh installed.

# 4. Verify the bootstrap regenerated the expected paths
ls .specify/scripts/bash/                            # should list >= 5 .sh files
cat .claude/skills/speckit-plan/SKILL.md | head -20  # should reference .specify/scripts/bash/...

# 5. Confirm `git status` is still clean (regenerated files are gitignored)
git status
# Expected: "nothing to commit, working tree clean"
```

If step 5 shows any tracked file as modified, see `specs/009-wsl-dev-env-alignment/contracts/bootstrap-contract.md` "Forbidden effects" — Phase A's contract guarantees `specify init` only touches gitignored paths.

---

## Run the smoke tests

```bash
# Single entrypoint (added by 009)
bash tests/run-all.sh

# Or one at a time
bash tests/test-handoff-shape.sh
bash tests/test-guard-hardcoded-rules.sh
bash tests/test-bridge-state-summary.sh
bash tests/test-claude-codex-skill-parity.sh
```

Expected: each test prints a `*-ok (bash)` final line. Total runtime under 60s on a typical WSL host (per plan.md Performance Goals).

---

## Drive one full bridge cycle from WSL bash (FR-013 reproduction)

```bash
# 1. Start a probe feature (or work an existing one)
# In your Claude Code or Codex session:
/speckit-specify "probe — verify WSL bridge cycle"

# 2. Plan and tasks
/speckit-plan
/speckit-tasks

# 3. Execute via the bridge (the after_tasks hook handed off to superpowers)
/speckit-superpowers-bridge

# 4. Mark complete
.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh \
    --status complete --actor claude --reason "probe complete"
```

Every step prints a `[bridge state]` summary block, confirming the bridge runtime is intact on WSL bash. This is the same cycle 009 used as its own FR-013 verification (recorded in `specs/009-wsl-dev-env-alignment/verification.md`).

---

## Switching between WSL bash and Windows PowerShell on the same checkout

The repo's `.gitattributes` already declares `*.sh text eol=lf` and `*.ps1 text eol=crlf`. The `git rm -r --cached` of install-state paths means flipping your flavor is one command:

```bash
# From WSL bash → switch to ps for a Windows session
sed -i 's/"script": "sh"/"script": "ps"/' .specify/init-options.json   # if you want to also switch the project default
specify init --here --script ps --force

# From Windows PowerShell → switch to sh for WSL session
(Get-Content .specify/init-options.json) -replace '"script": "ps"', '"script": "sh"' | Set-Content .specify/init-options.json
specify init --here --script sh --force
```

Both directions: `git status` MUST remain clean after the flavor switch (only `.specify/init-options.json` changes, by one line). The regenerated install-state files land in gitignored paths.

---

## Where to read more

- **Full host-environment specifics**: `AGENTS.md` → `## Supported Host Environments` (added by 009).
- **Why these install-state files are gitignored**: `specs/009-wsl-dev-env-alignment/spec.md` → `## Clarifications` (Q1 + Q2 + Policy).
- **What exactly `specify init` regenerates**: `specs/009-wsl-dev-env-alignment/contracts/bootstrap-contract.md`.
- **Verification evidence** that the WSL flow actually works: `specs/009-wsl-dev-env-alignment/verification.md` (committed at the end of this feature).
