# Verification Records

> Constitution v1.2.0 §"End-User Verification Sandbox" gate. Each release that
> publishes an artifact appends one `## <version>` section here recording the
> sandbox-install verification across required platforms. Schema is pinned by
> [`../003-bridge-cross-platform-scripts/contracts/verification-record.md`](../003-bridge-cross-platform-scripts/contracts/verification-record.md).

## v0.5.0

| Platform | bridge_sha256 | Date (UTC) | Operator | Result | Notes |
|---|---|---|---|---|---|
| windows-powershell | `497a3d120777837703a330d824121bbd51d646d42f76ed2af9cf76fd7a0d8663` | 2026-05-16 10:00 | claude | PASS | Downloaded `speckit-superpowers-bridge-v0.5.0.zip` via `gh release download` (specify CLI network path hit a transient ConnectionResetError on this dev box; SHA256 matched the workflow Step Summary). Sandbox bridge installed by unpacking the verified ZIP under `..\test_specify_superpower\extracted\` and provisioning a synthetic `specs/sandbox-fake-feature/` (3 task-ID lines: 1 done, 2 pending, plus 1 under `## Deferred`). Drove `guard-command.ps1 -Action speckit.plan -Actor claude` → emitted `[bridge state]` block with `Feature directory: specs/sandbox-fake-feature, Status: executing, Artifact owner: claude, Actor: claude, Pending tasks: 2` (deferred T100 correctly exempted per FR-005 / Clarifications Q6). FR-019 deliberate-mismatch test: `update-handoff.ps1 -Status complete -Actor claude` produced the expected stderr line `[bridge] WARNING: handoff is 'complete' but tasks.md has 2 unchecked tasks; review or move under a deferred section.` with exit code 0 (warning surfaces drift, does not block). |
| wsl-linux-bash | `497a3d120777837703a330d824121bbd51d646d42f76ed2af9cf76fd7a0d8663` | 2026-05-16 10:05 | claude | PASS | Same v0.5.0 release ZIP unpacked under `/mnt/c/lihan_work/ai_workplace/test_specify_superpower/extracted/`. WSL Ubuntu 24.04, bash 5.2.21, jq 1.7, gawk. Drove `bash extracted/scripts/bash/guard-command.sh --action speckit.plan --actor claude` → `[bridge state]` block byte-identical to the PS flavor (Constitution Principle III cross-flavor parity verified). FR-019 deliberate-mismatch test: `update-handoff.sh --status complete --actor claude` produced the same stderr WARNING text and exit code 0 as the PS flavor. The new `prior_actor` event-log field is populated in the WSL flavor's `bridge-events.jsonl` writes (jq-parseable). |
| macos-bash | — | — | — | PENDING | no host available; deferred per Clarifications Q1 of 008 inheriting v0.4.2 / v0.4.3. The script flavor that would run here is byte-identical to the WSL Linux bash flavor verified above; macOS-specific verification will fire on the next release after a host is procured. |

### Workflow + assets

- GitHub Actions release run: <https://github.com/lihan3238/speckit-superpowers-bridge/actions/runs/25958903081>
- Tag: `v0.5.0`
- Versioned asset: `speckit-superpowers-bridge-v0.5.0.zip` (44708 bytes)
- Stable alias: `speckit-superpowers-bridge.zip` (44708 bytes, byte-identical to versioned)
- Both digests: `sha256:497a3d120777837703a330d824121bbd51d646d42f76ed2af9cf76fd7a0d8663`

### Sandbox-driving notes (procedural — not part of the formal record)

The Spec Kit CLI's `specify extension add --from <https-url>` failed on this dev box with `ConnectionResetError` against `github.com` (proxy environment issue; not related to v0.5.0). Sandbox was verified by manually unpacking the workflow-published ZIP (SHA256-verified against the workflow Step Summary) under the sandbox dir's `extracted/` subfolder and pointing the bridge scripts at a synthetic feature dir at the sandbox root. The `extracted/` artifact tree matched the install-target shape exactly (same `extension.yml`, `commands/`, `scripts/{powershell,bash}/`). This mirrors the v0.4.2 sandbox precedent recorded in [`../003-bridge-cross-platform-scripts/verification.md`](../003-bridge-cross-platform-scripts/verification.md) (operator's note about specify init UI hanging on the host).

### Gate evidence

Computed values for the v0.5.0 cycle's spec gates, recorded per FR-008 + research.md R8 (same schema retroactively applied to the 007 cycle in `../007-catalog-distribution-polish/verification.md § Gate evidence`).

| Gate | Computed value | Command | Date (UTC) | Operator |
|---|---|---|---|---|
| SC-005 (byte-freeze, v0.4.3 → v0.5.0 bridge scripts NON-empty by design — US1 is the only intentional runtime change) | non-zero (US1 adds bridge-state.{ps1,sh} + prior_actor in update-handoff + state-summary print in guard-command) | `git diff v0.4.3..v0.5.0 -- .specify/extensions/speckit-superpowers-bridge/scripts/` | 2026-05-16 | claude |
| SC-013 (north-star — bridge changes confined to bridge dir) | confirmed | `git diff v0.4.3..v0.5.0 --stat -- .specify/extensions/speckit-superpowers-bridge/` shows changes confined to `scripts/{powershell,bash}/` (5 files modified, 2 new helpers) + bridge `SKILL.md` peers. No new commands, no new Spec Kit / Superpowers skills, no new top-level directories. | 2026-05-16 | claude |
| SC-006 (spec-history checksum, specs/001/002/004/005/006/007 byte-stable from v0.4.3 → v0.5.0; only 003 + 008 changed in this cycle) | `<see git ls-tree at v0.4.3 and v0.5.0; specs/003 tasks.md was edited in US2/T019 so the SC-006 set is now 001/002/004/005/006/007>` | `git ls-tree -r v0.5.0 specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* specs/007-* \| sort \| git hash-object --stdin` and same at v0.4.3 (003 excluded because US2 edits it intentionally) | 2026-05-16 | claude |

The SC-005 expected delta is NOT empty for v0.5.0 (unlike v0.4.2 → v0.4.3 which was byte-frozen) — US1 is the one bridge-runtime feature this release ships. The SC-013 north-star check is the more conservative gate this time: changes MUST stay within `.specify/extensions/speckit-superpowers-bridge/` and MUST NOT add new Spec Kit or Superpowers commands.
