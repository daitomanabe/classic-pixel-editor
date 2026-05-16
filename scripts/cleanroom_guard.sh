#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(pwd)}"
cd "$root"

fail() {
  printf 'clean-room guard failed: %s\n' "$1" >&2
  exit 1
}

while IFS= read -r path; do
  base="$(basename "$path")"
  case "$base" in
    *photoshop*|*Photoshop*|*adobe*|*Adobe*)
      fail "prohibited brand/source-like filename: $path"
      ;;
  esac
done < <(find . -path './.git' -prune -o -path './.build' -prune -o -path './DerivedData' -prune -o -print)

scan_roots=()
[ -d Sources ] && scan_roots+=(Sources)
[ -d Tests ] && scan_roots+=(Tests)
source_hits=""
if [ "${#scan_roots[@]}" -gt 0 ]; then
  source_hits="$(find "${scan_roots[@]}" -type f -name '*.swift' -print0 | xargs -0 grep -Ein 'photoshop|adobe|agdm|decompil|source mirror|source zip|computerhistory.org/.+source-code|raw.githubusercontent.com/.+photo' || true)"
fi
if [ -n "$source_hits" ]; then
  printf '%s\n' "$source_hits" >&2
  fail "prohibited clean-room terms found in source or tests"
fi

mirror_hits="$(find . -path './.git' -prune -o -path './.build' -prune -o -path './SPEC.md' -prune -o -path './CLEANROOM.md' -prune -o -path './README.md' -prune -o -path './docs/feature-research.md' -prune -o -path './.github/pull_request_template.md' -prune -o -type f -print0 | xargs -0 grep -Ein 'github\.com/.+(photoshop|photo-shop)|raw\.githubusercontent\.com/.+(photoshop|photo-shop)|agdm/.+1\.0\.1' || true)"
if [ -n "$mirror_hits" ]; then
  printf '%s\n' "$mirror_hits" >&2
  fail "source mirror reference found"
fi

large_binary_hits="$(find . -path './.git' -prune -o -path './.build' -prune -o -type f \( -iname '*.icns' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.tif' -o -iname '*.tiff' \) -size +0 -print)"
if [ -n "$large_binary_hits" ]; then
  printf '%s\n' "$large_binary_hits" >&2
  fail "binary image assets are not part of the clean scaffold"
fi

printf 'clean-room guard passed\n'
