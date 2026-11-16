#!/bin/sh
# Build phase "Increase Build Number" of the app target: every build (Debug, Release, archive,
# Tools/install-release.sh) increases the build number by one and writes it into the built app's
# Info.plist as CFBundleVersion, shown in the About window as "(Build n)".
# The last build number is kept in BUILD_NUMBER in the repository root.
# Runs from Xcode/xcodebuild only (needs SRCROOT, TARGET_BUILD_DIR and INFOPLIST_PATH).
set -e
COUNTER="$SRCROOT/BUILD_NUMBER"
PLIST="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
# Spaces and line ends around the number are ignored; anything else makes the build fail.
LAST="$(cat "$COUNTER" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)"
case "$LAST" in
  ''|*[!0-9]*) echo "error: $COUNTER must hold the last build number (a whole number)" >&2; exit 1 ;;
esac
# Leading zeros are dropped ("08" would otherwise be read as an octal number).
LAST="$(printf '%s' "$LAST" | sed 's/^0*//')"
NEXT=$((${LAST:-0} + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEXT" "$PLIST"
echo "$NEXT" > "$COUNTER"
echo "Build number $NEXT"
