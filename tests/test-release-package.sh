#!/usr/bin/env bash
# tests/test-release-package.sh — release package/readiness smoke checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BRIDGE_DIR="$REPO_ROOT/.specify/extensions/speckit-superpowers-bridge"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file() {
    [ -f "$REPO_ROOT/$1" ] || fail "missing required file: $1"
}

assert_dir() {
    [ -d "$REPO_ROOT/$1" ] || fail "missing required directory: $1"
}

printf 'release-package: checking source package inventory\n'

assert_file ".specify/extensions/speckit-superpowers-bridge/extension.yml"
assert_file ".specify/extensions/speckit-superpowers-bridge/verified-versions.json"
assert_dir ".specify/extensions/speckit-superpowers-bridge/commands"
assert_dir ".specify/extensions/speckit-superpowers-bridge/scripts/bash"
assert_dir ".specify/extensions/speckit-superpowers-bridge/scripts/powershell"
assert_file "README.md"
assert_file "README.zh-CN.md"
assert_file "CHANGELOG.md"
assert_file "LICENSE"
assert_file ".gitattributes"

command -v jq >/dev/null 2>&1 || fail "jq is required for package smoke checks"
command -v python3 >/dev/null 2>&1 || fail "python3 is required for package smoke checks"

cmd_count="$(find "$BRIDGE_DIR/commands" -maxdepth 1 -type f -name '*.md' | wc -l)"
[ "$cmd_count" -eq 3 ] || fail "expected exactly 3 bridge command files, got $cmd_count"
for cmd in execute guard handoff; do
    assert_file ".specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.$cmd.md"
done

bash_count="$(find "$BRIDGE_DIR/scripts/bash" -maxdepth 1 -type f -name '*.sh' | wc -l)"
ps_count="$(find "$BRIDGE_DIR/scripts/powershell" -maxdepth 1 -type f -name '*.ps1' | wc -l)"
[ "$bash_count" -eq "$ps_count" ] || fail "bash/PowerShell script count mismatch: $bash_count vs $ps_count"
for ps_file in "$BRIDGE_DIR/scripts/powershell"/*.ps1; do
    stem="$(basename "$ps_file" .ps1)"
    [ -f "$BRIDGE_DIR/scripts/bash/$stem.sh" ] || fail "missing bash script flavor for $stem.ps1"
done
for sh_file in "$BRIDGE_DIR/scripts/bash"/*.sh; do
    stem="$(basename "$sh_file" .sh)"
    [ -f "$BRIDGE_DIR/scripts/powershell/$stem.ps1" ] || fail "missing PowerShell script flavor for $stem.sh"
done

grep -Eq '^\*\.sh[[:space:]]+text[[:space:]]+eol=lf\b' "$REPO_ROOT/.gitattributes" || fail ".gitattributes missing '*.sh text eol=lf'"
grep -Eq '^\*\.ps1[[:space:]]+text[[:space:]]+eol=crlf\b' "$REPO_ROOT/.gitattributes" || fail ".gitattributes missing '*.ps1 text eol=crlf'"

version="$(
    python3 - "$BRIDGE_DIR/extension.yml" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"(?m)^\s{2,}version:\s*['\"]?([^'\"\s#]+)", text)
if not match:
    raise SystemExit("extension.yml version not found")
print(match.group(1))
PY
)"
if [ -x "$REPO_ROOT/scripts/release/build-extension-zip.sh" ]; then
    bash "$REPO_ROOT/scripts/release/build-extension-zip.sh" --version "$version" >/tmp/speckit-bridge-build-a.out
    sha_a="$(sha256sum "$REPO_ROOT/dist/speckit-superpowers-bridge-v$version.zip" | awk '{print $1}')"
    sleep 2
    bash "$REPO_ROOT/scripts/release/build-extension-zip.sh" --version "$version" >/tmp/speckit-bridge-build-b.out
    sha_b="$(sha256sum "$REPO_ROOT/dist/speckit-superpowers-bridge-v$version.zip" | awk '{print $1}')"
    [ "$sha_a" = "$sha_b" ] || fail "bash release ZIP build is not deterministic: $sha_a vs $sha_b"
else
    fail "scripts/release/build-extension-zip.sh must exist and be executable"
fi

readiness_output="$(bash "$BRIDGE_DIR/scripts/bash/bridge-status.sh" --readiness --actor codex)"
printf '%s\n' "$readiness_output" | grep -Fq '[bridge readiness]' || fail "readiness output missing header"
for label in "Script flavor:" "Required tools:" "Namespace:" "Package files:" "Bridge state:" "Agents:" "Next:"; do
    printf '%s\n' "$readiness_output" | grep -Fq "$label" || fail "readiness output missing $label"
done
readiness_json="$(bash "$BRIDGE_DIR/scripts/bash/bridge-status.sh" --readiness --json --actor codex)"
printf '%s\n' "$readiness_json" | jq -e '
  .script_flavor == "sh" and
  (.required_tools.status | IN("ready","warning","failed")) and
  (.namespace.status | IN("ready","failed")) and
  (.package_files.status | IN("ready","failed")) and
  (.bridge_state.status | type == "string") and
  (.agents.status | IN("ready","warning","not checked","failed")) and
  (.next | type == "string")
' >/dev/null || fail "readiness JSON missing expected fields"

for file in README.md README.zh-CN.md; do
    for needle in "1.0.0" "Windows" "Linux" "readiness" "Codex" "Claude" "Superspec" "SuperB" "Comet"; do
        grep -Fq "$needle" "$REPO_ROOT/$file" || fail "$file missing README parity term: $needle"
    done
done

for file in docs/demo/README.md docs/demo/hero.tape docs/demo/full-cycle.tape; do
    assert_file "$file"
    grep -Fq "Truth label:" "$REPO_ROOT/$file" || fail "$file missing demo truth label"
    grep -Fq "illustrative" "$REPO_ROOT/$file" || fail "$file must label synthetic demo output as illustrative"
done

for heavy in package.json package-lock.json pnpm-lock.yaml yarn.lock node_modules Dockerfile docker-compose.yml requirements.txt pyproject.toml go.mod Cargo.toml Gemfile; do
    [ ! -e "$BRIDGE_DIR/$heavy" ] || fail "bridge package unexpectedly contains heavy runtime marker: $heavy"
done
if grep -RInE 'daemon|database|sqlite|postgres|redis|node_modules|docker-compose' "$BRIDGE_DIR" >/dev/null 2>&1; then
    fail "bridge package contains heavy-runtime wording or dependency markers"
fi

tracked_generated="$(
    git -C "$REPO_ROOT" ls-files '.agents/skills/speckit-*' '.claude/skills/speckit-*' |
        grep -vE '^(\.agents|\.claude)/skills/speckit-superpowers-bridge/SKILL\.md$' || true
)"
[ -z "$tracked_generated" ] || fail "vendor-managed generated skills are tracked: $tracked_generated"

changed_generated="$(
    git -C "$REPO_ROOT" diff --name-only -- .agents/skills .claude/skills |
        grep -vE '^(\.agents|\.claude)/skills/speckit-superpowers-bridge/SKILL\.md$' || true
)"
[ -z "$changed_generated" ] || fail "vendor-managed generated skills have local diffs: $changed_generated"

zip_path="$REPO_ROOT/dist/speckit-superpowers-bridge-v1.0.0.zip"
if [ -f "$zip_path" ]; then
    printf 'release-package: checking ZIP %s\n' "$zip_path"
    python3 - "$zip_path" <<'PY'
import sys, zipfile
zip_path = sys.argv[1]
required = [
    "extension.yml",
    "verified-versions.json",
    "README.md",
    "README.zh-CN.md",
    "CHANGELOG.md",
    "LICENSE",
    ".gitattributes",
]
required += [
    "commands/speckit.speckit-superpowers-bridge.execute.md",
    "commands/speckit.speckit-superpowers-bridge.guard.md",
    "commands/speckit.speckit-superpowers-bridge.handoff.md",
]
required_prefixes = [
    "commands/",
    "scripts/bash/",
    "scripts/powershell/",
]
heavy_markers = {
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "node_modules/",
    "Dockerfile",
    "docker-compose.yml",
    "requirements.txt",
    "pyproject.toml",
    "go.mod",
    "Cargo.toml",
    "Gemfile",
}
with zipfile.ZipFile(zip_path) as zf:
    names = zf.namelist()
    missing = [name for name in required if name not in names]
    missing += [prefix for prefix in required_prefixes if not any(n.startswith(prefix) for n in names)]
    bad = [name for name in names if "\\" in name]
    heavy = [name for name in names if name in heavy_markers or any(name.startswith(marker) for marker in heavy_markers if marker.endswith("/"))]
    bad_modes = []
    for name in names:
        mode = (zf.getinfo(name).external_attr >> 16) & 0o777
        expected = 0o755 if name.startswith("scripts/bash/") and name.endswith(".sh") else 0o644
        if mode != expected:
            bad_modes.append(f"{name} has {oct(mode)}, expected {oct(expected)}")
if missing:
    raise SystemExit("missing ZIP entries: " + ", ".join(missing))
if bad:
    raise SystemExit("non-portable ZIP entries: " + ", ".join(bad))
if heavy:
    raise SystemExit("heavy runtime markers in ZIP: " + ", ".join(heavy))
if bad_modes:
    raise SystemExit("non-normalized ZIP modes: " + "; ".join(bad_modes))
PY
else
    printf 'release-package: ZIP not present yet; package ZIP checks deferred until build task\n'
fi

printf 'release-package-tests-ok\n'
