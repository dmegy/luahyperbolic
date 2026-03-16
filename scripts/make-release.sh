#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# Config
# --------------------------
PKG="luahyperbolic"
VERSION=$(date +%Y-%m-%d)

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Project root is parent of scripts/ folder
ROOT="$(dirname "$SCRIPT_DIR")"

# Directory for releases
OUTDIR="$ROOT/releases"
mkdir -p "$OUTDIR"

# Temporary directory for building archive
TMPDIR=$(mktemp -d)

# --------------------------
# Export tracked files from Git (run from project root)
# --------------------------
(
  cd "$ROOT"
  git archive --format=tar --prefix="${PKG}/" HEAD | tar -x -C "$TMPDIR"
)

# Go to package folder inside temp
cd "$TMPDIR/$PKG"

# Remove scripts folder from release (keep it in repo)
rm -rf scripts
rm -f .gitignore

# --------------------------
# Fix permissions for CTAN
# --------------------------
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# Remove macOS extended attributes
xattr -rc . 2>/dev/null || true

# --------------------------
# Create zip archive
# --------------------------
ZIP="${PKG}-${VERSION}.zip"

cd "$TMPDIR"
zip -qr -X "$ZIP" "$PKG"

# Move the zip to releases folder in project root
mv "$ZIP" "$OUTDIR/"

# --------------------------
# Clean up
# --------------------------
rm -rf "$TMPDIR"

echo "Release created: $OUTDIR/$ZIP"