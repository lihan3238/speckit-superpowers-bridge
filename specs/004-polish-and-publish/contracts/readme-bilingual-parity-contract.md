# Bilingual README Parity Contract

**Feature**: 004-polish-and-publish
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1`

## Purpose

Verify that `README.md` (English) and `README.zh-CN.md` (Simplified Chinese) cover the same structural ground. This is a *structural* parity check — anchor lists, section count, and code-fence count — not a content translation check. Humans own translation quality; the script catches drift.

## What is compared

| Comparison | Pass criterion | Failure → severity |
|---|---|---|
| Set of H1/H2/H3 headings (after lowercase + dash normalization) | Identical sets | P1 |
| Total H1 + H2 count | Identical | P2 |
| Number of fenced code blocks | Identical | P2 |
| First-line language toggle | Each file's first non-empty line links to the other | P1 |
| Image link count | Identical | P3 |

## What is NOT compared

- Word count, sentence count, line count (translations have different prose density)
- Text content within sections (humans verify)
- Comments or HTML annotations

## Inputs

- `README.md`
- `README.zh-CN.md`

## Output (default, human-readable on stderr)

```
README parity: passed
```
or
```
README parity: failed
  - heading set diff:
      only in README.md: introduction, faq
      only in README.zh-CN.md: 简介, 常见问题
  - heading count: EN=12 zh-CN=11
```

When invoked with `-Json`, single JSON object:
```json
{
  "passed": false,
  "checks": [{"name": "heading_set", "passed": false, "diff": {...}}, ...]
}
```

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Parity passes. |
| `2` | One or more P1 findings. |
| `3` | One or more P2 findings (and `-Strict`). |

## Heading normalization

For comparison purposes, headings are normalized as:
1. Strip leading `#` characters and whitespace.
2. Lowercase (best-effort; Chinese characters unchanged).
3. Replace whitespace with `-`.
4. Strip punctuation `[`,`]`,`(`,`)`,`?`,`!`,`：`,`，`.

So `## What is it?` and `## what-is-it` normalize the same. Chinese headings are compared by structural position (Nth heading EN ↔ Nth heading zh-CN) rather than character equality, because the same concept has different chars.

**NOTE**: A simpler positional rule (Nth heading must exist on both sides) is used in practice; cross-language exact match is infeasible without a translation dictionary. The script's heading-set comparison applies only when language-agnostic anchor IDs (e.g. `## installation`, kept in English in both files for cross-link stability) are present.

## Implementation note

The script uses ONLY language-agnostic positional comparison + count comparison. Anchor-set equality applies when the user has explicitly kept English anchors (recommended for marketplace linking). The plan's recommendation: keep H2 anchors as English slugs in both files; put translated text below.

## Testing

`tests/test-readme-bilingual-parity.ps1` covers:
- Happy path: both READMEs aligned → exit 0.
- Missing zh-CN heading: temporarily remove a section from zh-CN → expect P1 finding.
- Code-block count mismatch: temporarily add an extra fenced block to EN → expect P2 finding.
