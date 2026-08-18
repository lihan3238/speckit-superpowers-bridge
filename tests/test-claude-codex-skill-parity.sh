#!/usr/bin/env bash
# tests/test-claude-codex-skill-parity.sh
#
# Bash port of tests/test-claude-codex-skill-parity.ps1 (T021 from feature 002).
#
# Verifies bidirectional skill-id directory parity: every `.agents/skills/<id>/`
# directory must have a peer at `.claude/skills/<id>/` and vice versa. This is
# a structural invariant ensuring cross-agent feature coverage.
#
# Source: tests/test-claude-codex-skill-parity.ps1 (per spec 009 FR-007 port).
# Note: the original Port 4 contract in
#   specs/009-wsl-dev-env-alignment/contracts/tests-bash-port-contract.md
# specified file-content parity for the speckit-superpowers-bridge SKILL.md
# files — but the actual .ps1 source does bidirectional directory parity,
# which is the documented behavior since feature 002 T021. This port follows
# the .ps1 source (the authoritative reference per FR-007).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() { printf '%s\n' "$*" >&2; exit 1; }

CODEX_DIR="$REPO_ROOT/.agents/skills"
CLAUDE_DIR="$REPO_ROOT/.claude/skills"

[ -d "$CODEX_DIR" ]  || fail "Missing directory: $CODEX_DIR"
[ -d "$CLAUDE_DIR" ] || fail "Missing directory: $CLAUDE_DIR"

list_skill_ids() {
    local root="$1" path
    for path in "$root"/*/; do
        [ -d "$path" ] || continue
        basename "${path%/}"
    done | sort
}

mapfile -t codex_ids  < <(list_skill_ids "$CODEX_DIR")
mapfile -t claude_ids < <(list_skill_ids "$CLAUDE_DIR")

[ "${#codex_ids[@]}" -gt 0 ] || fail "No Codex skill directories discovered"
[ "${#claude_ids[@]}" -gt 0 ] || fail "No Claude skill directories discovered"

declare -A codex_set claude_set
for s in "${codex_ids[@]}";  do codex_set[$s]=1;  done
for s in "${claude_ids[@]}"; do claude_set[$s]=1; done

missing_on_claude=()
missing_on_codex=()

for s in "${codex_ids[@]}";  do [ -z "${claude_set[$s]+x}" ] && missing_on_claude+=("$s"); done
for s in "${claude_ids[@]}"; do [ -z "${codex_set[$s]+x}"  ] && missing_on_codex+=("$s");  done

if [ "${#missing_on_claude[@]}" -gt 0 ]; then
    for s in "${missing_on_claude[@]}"; do
        printf '  cp -r .agents/skills/%s .claude/skills/%s\n' "$s" "$s"
    done
    fail "Missing Claude peers: $(IFS=,; printf '%s' "${missing_on_claude[*]}")"
fi
if [ "${#missing_on_codex[@]}" -gt 0 ]; then
    for s in "${missing_on_codex[@]}"; do
        printf '  cp -r .claude/skills/%s .agents/skills/%s\n' "$s" "$s"
    done
    fail "Missing Codex peers: $(IFS=,; printf '%s' "${missing_on_codex[*]}")"
fi

printf '%s\n' "claude-codex-skill-parity-tests-ok (bash)"
