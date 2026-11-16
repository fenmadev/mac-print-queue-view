#!/bin/sh
# E04 — runs Tools/increase-build-number.sh in a temporary folder with several BUILD_NUMBER contents
# and a minimal Info.plist; prints the resulting CFBundleVersion, the counter file and the script output.
# Usage (from the repository root): sh _docs/phases/phase-02/evidence/E04/run.sh
# Touches nothing in the project: SRCROOT and TARGET_BUILD_DIR point to the temporary folder.
set -u
SCRIPT="$(cd "$(dirname "$0")/../../../../.." && pwd)/Tools/increase-build-number.sh"
T="$(mktemp -d)"
mkdir "$T/b"
check() { # $1 label, $2 "missing" or the counter content
  if [ "$2" = missing ]; then rm -f "$T/BUILD_NUMBER"; else printf '%s\n' "$2" > "$T/BUILD_NUMBER"; fi
  printf '<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleVersion</key><string>1</string></dict></plist>' > "$T/b/Info.plist"
  OUT="$(SRCROOT="$T" TARGET_BUILD_DIR="$T/b" INFOPLIST_PATH=Info.plist sh "$SCRIPT" 2>&1 | sed "s#$T#<tmp>#g" | tr '\n' ' ')"
  printf '%-22s CFBundleVersion=%s counter=%s | %s\n' "$1" \
    "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$T/b/Info.plist")" \
    "$(tr '\n' '/' 2>/dev/null < "$T/BUILD_NUMBER")" "$OUT"
}
check "41" "41"
check "' 41 ' (spaces)" " 41 "
check "08 (leading zero)" "08"
check "0" "0"
check "empty" ""
check "abc" "abc"
check "'1 2'" "1 2"
check "two lines 3/4" "3
4"
check "file missing" missing
rm -f "$T/BUILD_NUMBER" "$T/b/Info.plist"
rmdir "$T/b" "$T"
