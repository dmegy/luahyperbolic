#!/usr/bin/env bash
set -euo pipefail

PKG="luahyperbolic"
VERSION=$(date +%Y/%m/%d)
VERSION_FILE=$(date +%Y-%m-%d)

TMPDIR=$(mktemp -d)
OUTDIR="releases"

mkdir -p "$OUTDIR"

git archive --format=tar --prefix="${PKG}/" HEAD | tar -x -C "$TMPDIR"

cd "$TMPDIR/$PKG"

rm -rf scripts 2>/dev/null || true
rm -rf "$OUTDIR" 2>/dev/null || true
rm -f .gitignore 2>/dev/null || true

find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

ZIP="${PKG}-${VERSION_FILE}.zip"

cd "$TMPDIR"
zip -qr -X "$ZIP" "$PKG"

mv "$ZIP" "$OLDPWD/$OUTDIR/"

rm -rf "$TMPDIR"
