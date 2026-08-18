#!/usr/bin/env bash
# Regression for GitHub issue #13: update-handoff.sh must work without GNU
# `realpath -m` and must preserve canonicalize-missing + symlink semantics.

set -euo pipefail

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail "git is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

REPO_ROOT="$(git rev-parse --show-toplevel)"
BRIDGE_SOURCE="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge"
UPDATE_SOURCE="$BRIDGE_SOURCE/scripts/bash/update-handoff.sh"

[ -f "$UPDATE_SOURCE" ] || fail "missing update-handoff.sh"

if grep -R -n --include='*.sh' 'realpath[[:space:]]\+-m' "$BRIDGE_SOURCE/scripts/bash" >/dev/null; then
    fail "GNU-only realpath -m remains in shipped bash scripts"
fi

TEMP_ROOT="$(mktemp -d /tmp/bridge-path-portability-XXXXXX)"
cleanup() {
    rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT INT TERM

PROJECT="$TEMP_ROOT/project"
OUTSIDE="$TEMP_ROOT/outside-feature"
FAKE_BIN="$TEMP_ROOT/fake-bin"
mkdir -p "$PROJECT/.specify/extensions" "$PROJECT/.specify/memory" \
    "$PROJECT/specs/001-normal" "$OUTSIDE" "$FAKE_BIN"
OUTSIDE_CANONICAL="$(cd "$OUTSIDE" && pwd -P)"
cp -a "$BRIDGE_SOURCE" "$PROJECT/.specify/extensions/"
git -C "$PROJECT" init -q

printf '# Constitution\n' > "$PROJECT/.specify/memory/constitution.md"
for artifact in spec.md plan.md tasks.md; do
    printf '# %s\n' "$artifact" > "$PROJECT/specs/001-normal/$artifact"
    printf '# %s\n' "$artifact" > "$OUTSIDE/$artifact"
done

cat > "$FAKE_BIN/realpath" <<'SHIM'
#!/usr/bin/env bash
if [ "${1:-}" = "-m" ]; then
    printf 'realpath: illegal option -- m\n' >&2
    exit 64
fi
printf 'unexpected realpath invocation: %s\n' "$*" >&2
exit 65
SHIM
chmod +x "$FAKE_BIN/realpath"

UPDATE="$PROJECT/.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh"
HANDOFF="$PROJECT/.specify/superpowers-handoff.json"

run_update() {
    (cd "$PROJECT" && PATH="$FAKE_BIN:$PATH" bash "$UPDATE" "$@") >/dev/null
}

# Existing in-repository feature stays project-relative.
run_update --status ready --feature-directory './specs/001-normal/../001-normal' --actor codex
[ "$(jq -r '.feature_directory' "$HANDOFF")" = 'specs/001-normal' ] \
    || fail "existing feature was not normalized to a project-relative path"

# Missing suffix components are normalized and reported, not rejected by the
# path resolver. The state becomes blocked only because artifacts are absent.
run_update --status executing --feature-directory 'specs/001-normal/../missing/./nested' --actor codex
[ "$(jq -r '.feature_directory' "$HANDOFF")" = 'specs/missing/nested' ] \
    || fail "missing feature suffix was not canonicalized"
[ "$(jq -r '.status' "$HANDOFF")" = 'blocked' ] \
    || fail "missing artifacts should produce blocked state"
[ "$(jq -r '.source_of_truth.spec' "$HANDOFF")" = 'specs/missing/nested/spec.md' ] \
    || fail "missing spec path was not rendered project-relative"

# A symlink inside the repository that targets outside must remain absolute in
# the handoff; a lexical-only normalizer would incorrectly call it in-repo.
ln -s "$OUTSIDE" "$PROJECT/specs/002-outside-link"
run_update --status ready --feature-directory 'specs/002-outside-link' --actor codex
[ "$(jq -r '.feature_directory' "$HANDOFF")" = "$OUTSIDE_CANONICAL" ] \
    || fail "outside symlink target was incorrectly classified as in-repository"
[ "$(jq -r '.source_of_truth.tasks' "$HANDOFF")" = "$OUTSIDE_CANONICAL/tasks.md" ] \
    || fail "outside symlink artifact path was not preserved as absolute"

printf 'update-handoff-portability-tests-ok (bash)\n'
