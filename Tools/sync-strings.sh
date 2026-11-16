#!/bin/sh
# Adds new or changed user-facing strings from the Swift code to Localizable.xcstrings.
# Xcode does this automatically when building in the IDE; run this after building with
# xcodebuild or VS Code. New strings are added untranslated; fill in Dutch (nl) and Turkish (tr)
# in Xcode's String Catalog editor (open Localizable.xcstrings).
# Usage: Tools/sync-strings.sh [derived-data-path]
# The derived data path is the folder given to xcodebuild with -derivedDataPath (default: build).
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${1:-$REPO/build}"
DATA="$(find "$DERIVED/Build/Intermediates.noindex" -name '*.stringsdata' -path '*/Debug/*' 2>/dev/null || true)"
if [ -z "$DATA" ]; then
  echo "No build output found in $DERIVED; build the app first (xcodebuild ... -derivedDataPath <path>)." >&2
  exit 1
fi
# shellcheck disable=SC2086
xcrun xcstringstool sync "$REPO/MacPrintQueueView/Localizable.xcstrings" --stringsdata $DATA
echo "Updated MacPrintQueueView/Localizable.xcstrings"
