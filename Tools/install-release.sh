#!/bin/zsh
# Builds the Release version of Mac Print Queue View and copies it to the Applications folder in
# the home folder (~/Applications, created if needed), replacing an earlier copy there.
# Usage, in Terminal: Tools/install-release.sh [destination folder]   (default: ~/Applications)
# The build output goes to a temporary folder outside the project. A copy of the app that is
# running from the destination folder is quit first; copies running from elsewhere are left alone.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$HOME/Applications}"
APP_NAME="Mac Print Queue View.app"
TEMP_ROOT="${TMPDIR:-/tmp}"
DERIVED="${TEMP_ROOT%/}/MacPrintQueueView-release"
LOG="$DERIVED/build.log"

finish() {
  exit "$1"
}

mkdir -p "$DERIVED" "$DEST" || { echo "Could not create the build or destination folder."; finish 1; }
# The absolute physical path (no trailing slash, relative part or symbolic link), so that a copy
# running from the destination is recognised by its executable path.
DEST="$(cd "$DEST" && pwd -P)" || { echo "Could not open the destination folder."; finish 1; }
echo "Building the Release version… (log: $LOG)"
if ! xcodebuild -project "$REPO/MacPrintQueueView.xcodeproj" -scheme MacPrintQueueView \
    -configuration Release -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$DERIVED" build > "$LOG" 2>&1; then
  echo "The build failed. Last lines of the log:"
  tail -n 30 "$LOG"
  finish 1
fi

BUILT="$DERIVED/Build/Products/Release/$APP_NAME"
if [ ! -d "$BUILT" ]; then
  echo "Build succeeded, but the app was not found at: $BUILT"
  finish 1
fi
codesign --verify --deep --strict "$BUILT" || { echo "The built app's signature is not valid."; finish 1; }

TARGET="$DEST/$APP_NAME"

# Process numbers of copies that run from the destination folder, one per line. The executable
# path is compared as plain text, not as a pattern, so a folder with a similar name never matches.
# Fails when the list of running programs cannot be read. The path is the one the copy was started
# with (Finder and the Dock use the real path); a copy started in Terminal through a symbolic link
# is not recognised.
running_copies() {
  local list pid cmdline
  list=$(ps -axww -o pid= -o command=) || return 1
  [[ -n "$list" ]] || return 1
  print -r -- "$list" | while read -r pid cmdline; do
    [[ "$cmdline" == "$TARGET/Contents/MacOS/"* ]] && print -r -- "$pid"
  done
  return 0
}

# Quit only a copy that runs from the destination folder; stop if that cannot be determined.
PIDS=$(running_copies) || { echo "Could not read the list of running programs; nothing was replaced."; finish 1; }
if [ -n "$PIDS" ]; then
  echo "Quitting the running copy in $DEST…"
  kill ${(f)PIDS}
  for _ in {1..40}; do
    PIDS=$(running_copies) || { echo "Could not read the list of running programs; nothing was replaced."; finish 1; }
    [ -z "$PIDS" ] && break
    sleep 0.25
  done
  if [ -n "$PIDS" ]; then
    echo "The running copy in $DEST did not quit; quit it and run this script again."
    finish 1
  fi
fi

echo "Copying to $TARGET…"
if [ -e "$TARGET" ]; then rm -rf "$TARGET" || { echo "Could not remove the earlier copy."; finish 1; }; fi
ditto "$BUILT" "$TARGET" || { echo "Copying failed."; finish 1; }

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$TARGET/Contents/Info.plist" 2>/dev/null)
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$TARGET/Contents/Info.plist" 2>/dev/null)
echo "Done: $TARGET (version $VERSION, build $BUILD)."
finish 0
