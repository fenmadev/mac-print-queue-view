#!/bin/sh
# Generates all macOS app icon sizes from a 1024×1024 PNG into the asset catalog.
# Usage: Tools/update-app-icon.sh icon_1024.png
set -e
SRC="$1"
OUT="$(dirname "$0")/../MacPrintQueueView/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT"
for s in 16 32 64 128 256 512 1024; do
  sips -z $s $s "$SRC" --out "$OUT/icon_$s.png" >/dev/null
done
echo "Updated $OUT"
