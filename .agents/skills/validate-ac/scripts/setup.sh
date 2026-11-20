#!/bin/bash
# Compile the two small helpers used by dh.sh into $DH_TOOLS (default $TMPDIR/dh-tools).
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${DH_TOOLS:-${TMPDIR:-/tmp}/dh-tools}"
mkdir -p "$OUT"
if [ -z "$DEVELOPER_DIR" ]; then
  X=$(ls -d /Applications/Xcode*.app 2>/dev/null | head -1)
  [ -n "$X" ] && export DEVELOPER_DIR="$X/Contents/Developer"
fi
swiftc -O "$DIR/hit.swift" -o "$OUT/hit"
swiftc -O "$DIR/tap.swift" -o "$OUT/tap"
echo "built helpers in $OUT"
