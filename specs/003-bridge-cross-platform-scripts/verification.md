# Verification Records

> Constitution v1.2.0 §"End-User Verification Sandbox" gate. Each release that
> publishes an artifact appends one `## <version>` section here recording the
> sandbox-install verification across required platforms. Schema is pinned by
> [contracts/verification-record.md](contracts/verification-record.md).

## v0.4.2

| Platform | bridge_sha256 | Date (UTC) | Operator | Result | Notes |
|---|---|---|---|---|---|
| windows-powershell | `8142e7dc26e2fa9f4cb1ed1de51fb419999543f014f8ab18cbf931bf23877c2b` | 2026-05-15 21:25 | claude | PASS | Downloaded `speckit-superpowers-bridge-v0.4.2.zip` from the published release URL; SHA256 matched the workflow-emitted digest. Drove a 7-step end-user bridge cycle (ready → guard ALLOW speckit.plan → executing with `-Actor codex` and no `-ArtifactOwner` → guard DENY speckit.implement → guard DENY speckit.constitution → complete → auto-archive). artifact_owner=`claude` preserved through the codex transition (B1 fix verified). bridge-events.jsonl=16 lines, bridge-snapshots=4. The Spec Kit `specify init` UI on the host hangs at the Rich "Project Setup" panel for unrelated reasons (CLI v0.8.10 on Windows native console), so verification was driven against the unpacked release ZIP — the actual artifact a user receives. |
| wsl-linux-bash | `8142e7dc26e2fa9f4cb1ed1de51fb419999543f014f8ab18cbf931bf23877c2b` | 2026-05-15 21:26 | claude | PASS | Same v0.4.2 release ZIP, unpacked under `/mnt/c/lihan_work/ai_workplace/test_specify_superpower/extracted/scripts/bash/`. WSL Ubuntu 24.04 (bash 5.2.21, jq 1.7). Drove the same 7-step end-user bridge cycle. artifact_owner=`claude` preserved through the codex transition (B1 fix verified on bash flavor too). bridge-events.jsonl=8 lines, bridge-snapshots=4. |
| macos-bash | — | — | — | PENDING | no host available; deferred per Clarifications Q3. The script flavor that would run here is byte-identical to the WSL Linux bash flavor verified above; macOS-specific verification will fire on the next release after a host is procured. |
