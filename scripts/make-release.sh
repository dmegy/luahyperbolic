#!/usr/bin/env bash
set -euo pipefail

PKG="luahyperbolic"
VERSION=$(date +%Y-%m-%d)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

ROOT="$(dirname "$SCRIPT_DIR")"

OUTDIR="$ROOT/releases"
mkdir -p "$OUTDIR"

TMPDIR=$(mktemp -d)

(
  cd "$ROOT"
  git archive --format=tar --prefix="${PKG}/" HEAD | tar -x -C "$TMPDIR"
)

cd "$TMPDIR/$PKG"

rm -rf scripts
rm -f .gitignore

find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
xattr -rc . 2>/dev/null || true

ZIP="${PKG}-${VERSION}.zip"

cd "$TMPDIR"
zip -qr -X "$ZIP" "$PKG"

mv "$ZIP" "$OUTDIR/"

rm -rf "$TMPDIR"

echo "Release created: $OUTDIR/$ZIP"