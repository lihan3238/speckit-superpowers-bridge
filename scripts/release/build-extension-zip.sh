#!/usr/bin/env bash
# Build the release ZIP using Linux/bash semantics. This is the preferred CI path.

set -euo pipefail

version=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --version)
            version="${2:-}"
            shift 2
            ;;
        -Version)
            version="${2:-}"
            shift 2
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

if [ -z "$version" ]; then
    printf 'Usage: %s --version X.Y.Z\n' "$0" >&2
    exit 2
fi
case "$version" in
    *[!0-9A-Za-z.-]* | "" | *..* | .* | *.)
        printf "Version '%s' is not semver-like. Expected: X.Y.Z or X.Y.Z-prerelease\n" "$version" >&2
        exit 2
        ;;
esac
if ! printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$'; then
    printf "Version '%s' is not semver. Expected: X.Y.Z or X.Y.Z-prerelease\n" "$version" >&2
    exit 2
fi

command -v git >/dev/null 2>&1 || { printf 'git is required\n' >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { printf 'python3 is required\n' >&2; exit 2; }

repo_root="$(git rev-parse --show-toplevel)"
bridge_dir="$repo_root/.specify/extensions/speckit-superpowers-bridge"
stage_root="${TMPDIR:-/tmp}/speckit-superpowers-bridge-build-$version"
dist_dir="$repo_root/dist"
out_zip="$dist_dir/speckit-superpowers-bridge-v$version.zip"
latest_zip="$dist_dir/speckit-superpowers-bridge.zip"

rm -rf "$stage_root"
mkdir -p "$stage_root/scripts" "$dist_dir"

cp "$bridge_dir/extension.yml" "$stage_root/"
[ -f "$bridge_dir/verified-versions.json" ] && cp "$bridge_dir/verified-versions.json" "$stage_root/"
cp -R "$bridge_dir/commands" "$stage_root/"
cp -R "$bridge_dir/scripts/powershell" "$stage_root/scripts/"
cp -R "$bridge_dir/scripts/bash" "$stage_root/scripts/"

for name in README.md README.zh-CN.md LICENSE CHANGELOG.md .gitignore .gitattributes; do
    [ -f "$repo_root/$name" ] && cp "$repo_root/$name" "$stage_root/"
done

declared_version="$(python3 - "$stage_root/extension.yml" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"(?m)^\s{2,}version:\s*['\"]?([^'\"\s#]+)", text)
print(match.group(1) if match else "")
PY
)"
if [ "$declared_version" != "$version" ]; then
    printf "extension.yml does not declare version '%s'. Bump it first.\n" "$version" >&2
    exit 1
fi

rm -f "$out_zip" "$latest_zip"
python3 - "$stage_root" "$out_zip" <<'PY'
from pathlib import Path
import sys
import zipfile

stage = Path(sys.argv[1]).resolve()
out_zip = Path(sys.argv[2]).resolve()

fixed_time = (1980, 1, 1, 0, 0, 0)
with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(p for p in stage.rglob("*") if p.is_file()):
        rel = path.relative_to(stage).as_posix()
        mode = 0o755 if rel.startswith("scripts/bash/") and rel.endswith(".sh") else 0o644
        info = zipfile.ZipInfo(rel, fixed_time)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.create_system = 3
        info.external_attr = mode << 16
        zf.writestr(info, path.read_bytes())

with zipfile.ZipFile(out_zip) as zf:
    names = zf.namelist()
    if "extension.yml" not in names:
        raise SystemExit("Built ZIP does not contain extension.yml at archive root.")
    bad = [name for name in names if "\\" in name]
    if bad:
        raise SystemExit("Built ZIP contains non-portable backslash entry names: " + ", ".join(bad))
PY

cp "$out_zip" "$latest_zip"
sha="$(python3 - "$out_zip" <<'PY'
from pathlib import Path
import hashlib
import sys

digest = hashlib.sha256()
with Path(sys.argv[1]).open("rb") as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
)"
size="$(python3 - "$out_zip" <<'PY'
from pathlib import Path
import sys
print(round(Path(sys.argv[1]).stat().st_size / 1024, 1))
PY
)"

printf 'Built: %s\n' "$out_zip"
printf 'Alias: %s\n' "$latest_zip"
printf 'Size:  %s KB\n' "$size"
printf 'SHA256: %s\n' "$sha"

rm -rf "$stage_root"
