# Phase 0 Research — v0.6.0 polish + alignment decisions

Resolves the 9 open decisions surfaced by `spec.md` FR-001 (README structure), FR-004 (verified-versions schema), FR-005 (CHANGELOG content), and FR-007 (download_url decoupling), so the Phase 1 contracts can be concrete and the Phase 2 tasks can be mechanical.

---

## D1 — Concrete badge list for the centered badge row

**Decision**: 4 mandatory + 1 optional badge, left-to-right.

| # | Label | shields.io URL pattern | Link target | Notes |
|---|---|---|---|---|
| 1 | License: MIT | `https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square` | `./LICENSE` | Static badge — no API call |
| 2 | Bridge version | `https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge?style=flat-square&label=bridge` | `https://github.com/lihan3238/speckit-superpowers-bridge/releases` | Reflects the latest GitHub release tag automatically |
| 3 | Spec Kit verified | `https://img.shields.io/badge/Spec_Kit-verified_0.8.16-success?style=flat-square` | `https://github.com/github/spec-kit` | Static — updated per release alongside `verified-versions.json` |
| 4 | Superpowers verified | `https://img.shields.io/badge/Superpowers-verified_5.1.0-success?style=flat-square` | `https://github.com/obra/superpowers` | Static — updated per release alongside `verified-versions.json` |
| 5 | (Optional) Marketplace | `https://img.shields.io/badge/Spec_Kit_Marketplace-listed-blueviolet?style=flat-square` | catalog entry permalink | Drop if marketplace permalink unstable |

**Rationale**: Matches rpamis/comet's 6-badge density without copying its npm-specific badges (we're not an npm package). Each badge has a clear, stable target. Cosmetic update cadence: badges 3 + 4 change exactly once per bridge release, alongside `verified-versions.json` — same edit unit.

**Alternatives considered**:

- **CI status badge**: rejected for v0.6.0 — bridge has no CI pipeline yet (009 moved tests to bash-only manual). Adding a CI badge would either (a) lie, or (b) force CI build-out into this feature's scope. Either violates SC-010's lightness budget. Defer to a separate CI feature.
- **Download count badge**: rejected — GitHub doesn't expose release-asset download counts via shields.io; `releases/latest/download/` URL bypasses asset-level metrics anyway.
- **Star/fork badges**: rejected — superficial, increases visual noise, doesn't help the "first 30 seconds" comprehension goal (SC-001).

---

## D2 — Positioning / comparison table column + row choices

**Decision**: 4 columns × 4 rows.

Columns: **Owns design** / **Owns implementation** / **Cross-agent** / **Bridge-style overhead**

Rows:

| | Owns design | Owns implementation | Cross-agent | Bridge-style overhead |
|---|---|---|---|---|
| **Just `speckit.implement`** | Spec Kit | Spec Kit (one-shot LLM run) | partial (agent-aware via Spec Kit) | none |
| **Just Superpowers (no Spec Kit)** | Superpowers brainstorm + writing-plans | Superpowers TDD + subagents | yes (Claude Code + Codex via OS-level skills) | none |
| **rpamis/comet (OpenSpec + Superpowers)** | OpenSpec change/spec | Superpowers via comet's state machine | yes (multi-platform npm installer) | medium — comet has its own .yaml + guard scripts |
| **speckit-superpowers-bridge (this)** | Spec Kit (vendor-owned) | Superpowers (vendor-owned) | yes (Codex + Claude Code, identical contract) | extremely thin — 1 guard script, 1 handoff JSON, 0 new state machinery |

**Rationale**: Honest framing — names the bridge's competitor (`speckit.implement` alone, raw Superpowers, comet) and its differentiator (thinness). Sells the brand of "compatible with upstream growth + extremely lightweight" without disparaging peers.

**Alternatives considered**:

- **Feature checkmark grid (Native-First / TDD / Code-review / Worktrees / etc.)**: rejected — duplicates information available from upstream Superpowers' own marketing and creates the impression that the bridge implements those features (it does not — it delegates).
- **Pricing-table style "tier" comparison**: rejected — promotional rather than informational.

---

## D3 — Which existing README sections collapse to `<details>` vs. stay open

**Decision**: Aggressive collapse to match rpamis/comet's "Commands / Skills / Workflow / Supported Platforms" pattern.

**Always-open (above the first scroll fold)**:

- Hero block (centered title + tagline + badges + language toggle)
- Bold value-prop sentence + 1-3 short paragraphs
- `## Why speckit-superpowers-bridge` (the gap it fills, ~3 paragraphs)
- `## Quick Start` (5-line install + numbered "what just happened")
- `## Positioning` (the D2 comparison table)

**Collapsed via `<details><summary>`**:

- `## Installation` (the existing 5-flavor matrix: Codex only / Claude only / Both / Local dev / Version-pinned) — high-detail, only relevant when user has chosen to install.
- `## Prerequisites` — long checklist, only relevant on first install.
- `## Your First Feature in 10 Minutes` — tutorial, only relevant after install.
- `## Commands` — reference table, look-up rather than read-through.
- `## Configuration` (actor resolution) — operational detail, rare lookup.
- `## Troubleshooting` — only relevant when something breaks.
- `## Maintenance and Versioning` — operational detail.
- `## Architecture in 60 Seconds` (incl. "how the bridge differs from peer extensions") — interesting but not first-30-second material; merge with the positioning table summary above.

**Always-open at the bottom**:

- `## Contributing and License` (one-paragraph cordial close)

**Rationale**: SC-001 demands 30-second comprehension from the first viewport. Aggressive collapse reduces above-the-fold noise to just hero + value-prop + Quick Start + Positioning. The `<details>` approach is the same pattern rpamis/comet uses for its "Commands / Skills / Workflow / Supported Platforms" sections — proven to work on GitHub-rendered Markdown.

**Alternatives considered**:

- **Flat layout, no `<details>`**: rejected — leaves a 250+ line README with no skim path. Loses to comet on perceived quality.
- **Sidebar-style TOC at top**: rejected — GitHub's auto-TOC sidebar already handles this; manual TOC duplicates work.

---

## D4 — Logo / hero image

**Decision**: NO logo image in v0.6.0. Hero block is text-only (centered title + ≤80-char tagline).

**Rationale**: The bridge has no logo asset, no designer time budgeted, no design system. Inventing a logo here violates SC-010 (lightness budget) and is the kind of "heavy framework drift" the user explicitly warned against. Future feature MAY add a logo if one is contributed; v0.6.0 ships text-only.

**Alternatives considered**:

- **ASCII-art title (rpamis/comet uses one)**: rejected — feels gimmicky for an infrastructure-glue extension, and the rendered ASCII art breaks on narrow mobile widths.
- **shields.io-style banner image**: rejected — extra dependency, no benefit over text.

---

## D5 — Tagline (the ≤80-char hero-block second line)

**Decision**: **"The thinnest bridge between Spec Kit (design) and Superpowers (implementation) — cross-agent, lightweight, upstream-compatible."**

Character count: 122 — too long. Trim:

**Decision (final)**: **"Thin bridge: Spec Kit owns design, Superpowers owns implementation, this orchestrates the handoff."**

Character count: 100 — still over. Trim again:

**Decision (final, accepted)**: **"Thinnest possible bridge from Spec Kit (design) to Superpowers (implementation)."**

Character count: 80 — at limit. Acceptable.

Chinese mirror tagline: **「极薄」桥接：Spec Kit 负责「设计」，Superpowers 负责「实现」。**

**Rationale**: Communicates positioning (what + connects what), brand (thin), audience (people who already know both upstreams). Stays at FR-001 budget.

**Alternatives considered**:

- "Connecting Spec Kit to Superpowers since 2026" — too cute, low information.
- "Cross-agent design→implementation handoff for spec-driven development" — too jargony, loses first-30-second readers.

---

## D6 — Language-toggle blockquote placement and style

**Decision**: Single `>` blockquote line immediately after the H1 title (which is in turn immediately after the centered hero block).

```markdown
<p align="center">…hero…</p>
<p align="center">…badges…</p>

# speckit-superpowers-bridge

> 中文版：[README.zh-CN.md](README.zh-CN.md)
```

Chinese mirror has the inverse line:

```markdown
> English: [README.md](README.md)
```

**Rationale**: Exact mirror of rpamis/comet's pattern (verified via direct fetch). Cheapest possible bilingual signal — one line, no infrastructure, no flag emojis (which read inconsistently on different OS rendering).

---

## D7 — `> [!TIP]` / `> [!NOTE]` / `> [!WARNING]` placement

**Decision**: Use GitHub-flavored Markdown alerts at three specific spots:

| Spot | Alert type | Content |
|---|---|---|
| End of `## Quick Start` | `> [!TIP]` | "Going from a vague idea? Run `superpowers:brainstorming` first — see [Pre-spec brainstorming workflow] for the flow." (cross-ref to feature 010's deliverable) |
| Inside collapsed `## Maintenance and Versioning` | `> [!NOTE]` | "From v0.6.0 onwards, the marketplace `download_url` is decoupled — `releases/latest/download/...` always resolves to the latest tag." |
| Inside collapsed `## Troubleshooting` | `> [!WARNING]` | "Do NOT set `git config --global http.proxy` on WSL — use the env-var-per-call pattern from CLAUDE.md. A global proxy config breaks on machines where the proxy is unreachable." (cross-ref to user's global CLAUDE.md WSL section) |

**Rationale**: Three concrete user-facing tips that GFM alerts render distinctively. No alert-spam (each is load-bearing).

**Alternatives considered**:

- Use plain "> " blockquotes without `[!TIP]` syntax: rejected — GFM alerts give a visual icon + color cue on GitHub.
- More alerts (5-10): rejected — alert fatigue, dilutes signal.

---

## D8 — `verified-versions.json` schema details

**Decision**: 5 fields, all required, with these exact key names and value types:

```json
{
  "verified_at": "2026-05-17T12:34:56Z",
  "spec_kit_version": "0.8.16",
  "superpowers_version": "5.1.0",
  "bridge_version": "0.6.0",
  "notes": "Free-text string; upstream caveats relevant to this verified pair."
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `verified_at` | ISO-8601 UTC string ending in `Z` | yes | Generated at release time by runbook Step 3 |
| `spec_kit_version` | semver string (no leading `v`) | yes | The exact upstream version this release was tested against |
| `superpowers_version` | semver string (no leading `v`) | yes | Same |
| `bridge_version` | semver string (no leading `v`) | yes | MUST equal `extension.yml.extension.version` and `catalog-entry.json.version` |
| `notes` | string (multi-line allowed) | yes (may be `""` if no caveats) | Concise upstream-change summary; copy into CHANGELOG `[0.6.0]` |

**Schema extensibility rule**: Future bridge versions MAY add new keys (additive); MUST NOT remove or rename existing keys; MUST NOT change value types.

**Rationale**: Smallest set of fields that supports the runbook's stated use ("which exact upstreams this release was verified against"). All 5 fields are mandatory to prevent partial files. `notes` being a free-text string instead of structured upstream-changes-list keeps file under 30 lines (SC-010) while preserving the audit signal — CHANGELOG handles structured upstream change details.

**Alternatives considered**:

- **Add `dist_sha256` field**: rejected for v0.6.0 — SHA256 is already captured in the release-page asset metadata + `marketplace/extension-submission-body.md`. Duplicate sources of truth drift. Add later if a real need appears.
- **Add `bridge_commit_sha` field**: rejected — Git tag carries this.
- **Make `notes` an array of objects**: rejected — overfits the schema. v0.6.0 ships with 30-line budget; arrays bust it.

---

## D9 — Release-runbook retirement of the catalog `download_url` edit step

**Decision**: Update `docs/release-runbook.md` to:

1. **Keep** the step that edits `marketplace/catalog-entry.json.version` (still per-release).
2. **Retire** the implicit/explicit step that edits `marketplace/catalog-entry.json.download_url` — replaced by a one-line note: "`download_url` is permanently set to the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias as of v0.6.0. Do NOT edit per release."
3. **Add** a step that creates / refreshes `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` immediately after the version bump (slot between current Step 2 CHANGELOG update and Step 4 submission checklist; can collapse with Step 3 if a "Refresh verified versions" slot already exists per `docs/release-runbook.md` Step 3 preview seen earlier — which it does).
4. **Verify** that the published GitHub release continues to attach BOTH the versioned and the stable-aliased ZIP (already happens for v0.5.0; add a `Verify:` line confirming the dual upload).

**Rationale**: Codifies the decoupling as a permanent runbook change, not an ad-hoc one-time exception. Future maintainers get the right script-of-action without re-deriving the decision.

---

## Cross-cutting research outputs

**Output 1 — Confirmed-clean Superpowers v5.1.0 surface**: grep across bridge files for `code-reviewer`, `/brainstorm`, `/execute-plan`, `/write-plan` returned zero hits (verified in clarify session). No remediation needed beyond a CHANGELOG note for users coming from Superpowers v5.0.x.

**Output 2 — Stable-alias asset confirmed on v0.5.0 release**: GitHub API call confirmed both `speckit-superpowers-bridge-v0.5.0.zip` (44708 B) and `speckit-superpowers-bridge.zip` (44708 B, identical content) are attached to the v0.5.0 release. The decoupling change is zero-risk.

**Output 3 — `requires.speckit_version` floor stays at `>=0.8.10`**: spec FR-006 decision codified. v0.6.0 ships no behavioral change that requires a newer Spec Kit; bumping the floor would force user-side upgrade pressure for zero gain.

---

**Phase 0 complete** — all 9 decisions resolved, 0 remaining `NEEDS CLARIFICATION` markers, ready for Phase 1 contracts.
