#!/bin/zsh
# Phase 01 evidence E09: safety checks of Tools/test-printer.sh (RM-008) and
# Tools/install-release.sh (RM-006), isolated from the system. Usage, from the project root:
#   _docs/phases/phase-01/evidence/E09/run.sh <empty temporary folder>
#
# Part 1 runs the actual test-printer script with stub commands placed first on PATH: lpstat,
# lsof and lpoptions only print the state written in files of the temporary folder; sudo only
# appends its arguments to a log (and records a cupsaccept in the state files). The printer and
# administration commands the script could call directly (lpadmin, cupsaccept, cupsenable,
# cupsdisable, lp, ipptool, nc) are stubs that log and fail. No real printer, job or
# administrator command is touched.
#
# The negative controls run the versions of both scripts reviewed in external review 07, kept
# unchanged in review-07/ (the run refuses when their SHA-256 differs), under the same stubs.
#
# Part 2 runs the actual install script with stubs for xcodebuild (writes a fake app into the
# temporary build folder) and codesign. Two dummy programs (a small program compiled here that
# only waits; a copy of /bin/sleep would be stopped by macOS outside its system location) run as
# "<folder>/Mac Print Queue View.app/Contents/MacOS/Mac Print Queue View" from the destination
# folder and from a folder whose name differs in one character; both folder names contain
# characters that have a meaning in regular expressions. Only these dummies can be signaled; the
# destination is inside the temporary folder. No app is built or installed.
set -u
ROOT="$(pwd)"
HERE="$ROOT/$(dirname "$0")"
# The script versions reviewed in external review 07, kept in review-07/ for the negative controls.
OLD_PRINTER_SHA=16a7ded80030c9ae41821ce4a61f56b68c6eeab2bd3c832869a45afb7181c2ef
OLD_INSTALL_SHA=b6d74a8d2a9d6b6db918235c1af3ee6a2714261f76d9ac1e75c8cc010616263c
sha() { shasum -a 256 "$1" | cut -d ' ' -f 1 }
[[ "$(sha "$HERE/review-07/test-printer.sh")" == "$OLD_PRINTER_SHA" && \
   "$(sha "$HERE/review-07/install-release.sh")" == "$OLD_INSTALL_SHA" ]] || {
  echo "Refusing: the review-07 copies in $HERE/review-07 are missing or changed."; exit 1; }
TMP="${1:?usage: run.sh <empty temporary folder>}"
mkdir -p "$TMP" || exit 1
TMP="$(cd "$TMP" && pwd -P)"
[[ -z "$(ls -A "$TMP")" ]] || { echo "Refusing: $TMP is not empty."; exit 1; }
failures=0
check() { # label actual expected
  if [[ "$2" == "$3" ]]; then echo "PASS $1: $2"; else echo "FAIL $1: $2 (expected $3)"; (( failures++ )); fi
}

# ---------------------------------------------------------------- part 1: test-printer.sh
STUBS="$TMP/printer-stubs"; STATE="$TMP/printer-state"
mkdir -p "$STUBS" "$STATE"
cat > "$STUBS/lpstat" <<'EOF'
#!/bin/zsh
S="$STUB_STATE"
case "$1" in
  -p) [[ -f "$S/exists" ]] || exit 1; echo "printer MPQV_Testprinter disabled since now -"; echo "	Stub." ;;
  -v) [[ -f "$S/uri-error" ]] && exit 1; [[ -f "$S/exists" ]] || exit 1; echo "device for MPQV_Testprinter: $(< "$S/uri")" ;;
  -a) [[ -f "$S/accept-error" ]] && exit 1; [[ -f "$S/exists" ]] || exit 1; cat "$S/accept" ;;
  *) exit 1 ;;
esac
EOF
cat > "$STUBS/sudo" <<'EOF'
#!/bin/zsh
echo "$*" >> "$STUB_STATE/sudo.log"
if [[ "$1" == cupsaccept && ! -f "$STUB_STATE/accept-sticky" ]]; then
  echo "MPQV_Testprinter accepting requests since now" > "$STUB_STATE/accept"
fi
exit 0
EOF
cat > "$STUBS/lsof" <<'EOF'
#!/bin/zsh
exit 1
EOF
cat > "$STUBS/lpoptions" <<'EOF'
#!/bin/zsh
echo "printer-is-shared=false"
EOF
for tool in lpadmin cupsaccept cupsenable cupsdisable lp ipptool nc; do
  printf '#!/bin/zsh\necho "%s $*" >> "$STUB_STATE/direct.log"\nexit 1\n' "$tool" > "$STUBS/$tool"
done
chmod +x "$STUBS"/*

# setup <exists yes|no> <uri> <accept text> [flags: uri-error accept-error accept-sticky]
setup() {
  find "$STATE" -type f -delete
  [[ "$1" == yes ]] && touch "$STATE/exists"
  echo "$2" > "$STATE/uri"
  echo "$3" > "$STATE/accept"
  shift 3
  for flag in "$@"; do touch "$STATE/$flag"; done
}
# run_printer <command>: prints "exit <n>; sudo <log>; direct <log>"
run_printer() {
  STUB_STATE="$STATE" PATH="$STUBS:/usr/bin:/bin" zsh "$ROOT/Tools/test-printer.sh" "$@" > "$STATE/out" 2>&1
  local code=$?
  echo "exit $code; sudo [$(paste -sd ';' "$STATE/sudo.log" 2> /dev/null)]; direct [$(paste -sd ';' "$STATE/direct.log" 2> /dev/null)]"
}
URI="socket://127.0.0.1:59100"; OLD_URI="ipp://127.0.0.1:9/ipp/print"
ACCEPTING="MPQV_Testprinter accepting requests since now"
REJECTING="MPQV_Testprinter not accepting requests since now"

echo "== test-printer.sh remove (R1)"
setup yes "socket://192.0.2.10:9100" "$ACCEPTING"
check "remove: other address, nothing removed" "$(run_printer remove)" "exit 1; sudo []; direct []"
setup yes "" "$ACCEPTING"
check "remove: empty address, nothing removed" "$(run_printer remove)" "exit 1; sudo []; direct []"
setup yes "$URI" "$ACCEPTING" uri-error
check "remove: address cannot be read, nothing removed" "$(run_printer remove)" "exit 1; sudo []; direct []"
setup yes "$URI/extra" "$ACCEPTING"
check "remove: address that only starts with the test address, nothing removed" "$(run_printer remove)" "exit 1; sudo []; direct []"
setup yes "$URI" "$ACCEPTING"
check "remove: test address, removed" "$(run_printer remove)" "exit 0; sudo [lpadmin -x MPQV_Testprinter]; direct []"
setup yes "$OLD_URI" "$ACCEPTING"
check "remove: earlier test address, removed" "$(run_printer remove)" "exit 0; sudo [lpadmin -x MPQV_Testprinter]; direct []"
setup no "$URI" "$ACCEPTING"
check "remove: no test printer, nothing done" "$(run_printer remove)" "exit 0; sudo []; direct []"

echo "== test-printer.sh create on an existing test printer (R2)"
setup yes "$URI" "$ACCEPTING"
check "accepting: no cupsaccept" "$(run_printer create)" "exit 0; sudo []; direct []"
setup yes "$URI" "$REJECTING"
check "not accepting: cupsaccept, then accepting" "$(run_printer create)" "exit 0; sudo [cupsaccept MPQV_Testprinter]; direct []"
setup yes "$URI" "$REJECTING" accept-sticky
check "not accepting, cupsaccept has no effect: refused" "$(run_printer create)" "exit 1; sudo [cupsaccept MPQV_Testprinter]; direct []"
setup yes "$URI" "$ACCEPTING" accept-error
check "acceptance cannot be read: refused, no cupsaccept" "$(run_printer create)" "exit 1; sudo []; direct []"
setup yes "$URI" "MPQV_Testprinter something unexpected"
check "unknown acceptance text: refused, no cupsaccept" "$(run_printer create)" "exit 1; sudo []; direct []"
setup yes "socket://192.0.2.10:9100" "$REJECTING"
check "other address: refused before anything changes" "$(run_printer create)" "exit 1; sudo []; direct []"

# Negative control: the version of the test-printer script reviewed in external review 07 (the
# fixed copy in review-07/, checked by its SHA-256) removes a printer with another address and leaves a
# test printer that rejects jobs as it is (under the same stubs: only logged, nothing changed).
echo "== negative control: test-printer script of review 07 (R1, R2)"
mkdir -p "$TMP/old-printer-tools"
cp "$HERE/review-07/test-printer.sh" "$TMP/old-printer-tools/test-printer.sh" || exit 1
run_old_printer() {
  STUB_STATE="$STATE" PATH="$STUBS:/usr/bin:/bin" zsh "$TMP/old-printer-tools/test-printer.sh" "$@" > "$STATE/out" 2>&1
  local code=$?
  echo "exit $code; sudo [$(paste -sd ';' "$STATE/sudo.log" 2> /dev/null)]; direct [$(paste -sd ';' "$STATE/direct.log" 2> /dev/null)]"
}
setup yes "socket://192.0.2.10:9100" "$ACCEPTING"
check "negative control: earlier version removes a printer with another address" "$(run_old_printer remove)" \
  "exit 0; sudo [lpadmin -x MPQV_Testprinter]; direct []"
setup yes "$URI" "$REJECTING"
check "negative control: earlier version takes 'not accepting' for accepting" "$(run_old_printer create)" \
  "exit 0; sudo []; direct []"

# ---------------------------------------------------------------- part 2: install-release.sh
echo "== install-release.sh process selection (R3)"
BASE="$TMP/install [x](y)+.v1"
DEST="$BASE/dest.v1"
SIMILAR="$BASE/destXv1"
APP="Mac Print Queue View.app"
EXE="Contents/MacOS/Mac Print Queue View"
ISTUBS="$TMP/install-stubs"
mkdir -p "$DEST/$APP/Contents/MacOS" "$SIMILAR/$APP/Contents/MacOS" "$ISTUBS" "$TMP/build-tmp"
printf '#include <unistd.h>\nint main(void) { sleep(300); return 0; }\n' > "$TMP/dummy.c"
cc -o "$TMP/dummy" "$TMP/dummy.c" || exit 1
cp "$TMP/dummy" "$DEST/$APP/$EXE"
cp "$TMP/dummy" "$SIMILAR/$APP/$EXE"
echo old > "$DEST/$APP/Contents/marker"
cat > "$ISTUBS/xcodebuild" <<'EOF'
#!/bin/zsh
while (( $# )); do
  if [[ "$1" == -derivedDataPath ]]; then DERIVED="$2"; fi
  shift
done
mkdir -p "$DERIVED/Build/Products/Release/Mac Print Queue View.app/Contents" || exit 1
echo new > "$DERIVED/Build/Products/Release/Mac Print Queue View.app/Contents/marker"
rm -f "$DERIVED/Build/Products/Release/Mac Print Queue View.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string stub" -c "Add :CFBundleVersion string 0" \
  "$DERIVED/Build/Products/Release/Mac Print Queue View.app/Contents/Info.plist" > /dev/null
EOF
printf '#!/bin/zsh\nexit 0\n' > "$ISTUBS/codesign"
chmod +x "$ISTUBS"/*
alive() { kill -0 "$1" 2> /dev/null && echo alive || echo gone }

# Two copies in the destination, so that quitting several processes is covered too.
"$DEST/$APP/$EXE" 300 &
IN_DEST=$!
"$DEST/$APP/$EXE" 301 &
IN_DEST2=$!
"$SIMILAR/$APP/$EXE" 300 &
IN_SIMILAR=$!
sleep 0.5
check "dummies running before the install" "$(alive $IN_DEST) $(alive $IN_DEST2) $(alive $IN_SIMILAR)" "alive alive alive"
TMPDIR="$TMP/build-tmp" PATH="$ISTUBS:$PATH" zsh "$ROOT/Tools/install-release.sh" "$DEST" > "$TMP/install.out" 2>&1
check "install: exit code" "$?" "0"
check "install: both dummies in the destination quit" "$(alive $IN_DEST) $(alive $IN_DEST2)" "gone gone"
check "install: dummy in the similarly named folder untouched" "$(alive $IN_SIMILAR)" "alive"
check "install: destination copy replaced" "$(< "$DEST/$APP/Contents/marker")" "new"
check "install: similarly named folder unchanged" "$(ls "$SIMILAR/$APP/Contents")" "MacOS"

echo "== install-release.sh when the process list cannot be read (R3)"
FAILPS="$TMP/failing-ps"
mkdir -p "$FAILPS"
printf '#!/bin/zsh\nexit 1\n' > "$FAILPS/ps"
chmod +x "$FAILPS/ps"
echo old > "$DEST/$APP/Contents/marker"
TMPDIR="$TMP/build-tmp" PATH="$FAILPS:$ISTUBS:$PATH" zsh "$ROOT/Tools/install-release.sh" "$DEST" > "$TMP/install-fail.out" 2>&1
check "install, ps fails: exit code" "$?" "1"
check "install, ps fails: destination not replaced" "$(< "$DEST/$APP/Contents/marker")" "old"
check "install, ps fails: dummy in the similarly named folder untouched" "$(alive $IN_SIMILAR)" "alive"

kill $IN_SIMILAR 2> /dev/null

# Negative control: the version of the install script reviewed in external review 07 (the fixed
# copy in review-07/, checked by its SHA-256), with folder names that differ only where the regular
# expression has a ".". It selects the dummy in the similarly named folder as well; it then tries
# to quit both with one "kill" argument, which zsh does not split, so it quits neither and stops.
echo "== negative control: install script of review 07 (R3)"
mkdir -p "$TMP/old-tools"
cp "$HERE/review-07/install-release.sh" "$TMP/old-tools/install-release.sh" || exit 1
BASE2="$TMP/plain.v1"
DEST2="$BASE2/dest.v1"; SIMILAR2="$BASE2/destXv1"
mkdir -p "$DEST2/$APP/Contents/MacOS" "$SIMILAR2/$APP/Contents/MacOS"
cp "$TMP/dummy" "$DEST2/$APP/$EXE"; cp "$TMP/dummy" "$SIMILAR2/$APP/$EXE"
"$DEST2/$APP/$EXE" 300 &
OLD_DEST=$!
"$SIMILAR2/$APP/$EXE" 300 &
OLD_SIMILAR=$!
sleep 0.5
check "negative control: dummies running before the install" "$(alive $OLD_DEST) $(alive $OLD_SIMILAR)" "alive alive"
TMPDIR="$TMP/build-tmp" PATH="$ISTUBS:$PATH" zsh "$TMP/old-tools/install-release.sh" "$DEST2" > "$TMP/install-old.out" 2>&1
check "negative control: the earlier version selects the dummy in the similarly named folder" \
  "$(grep -cF "illegal pid: $OLD_DEST\\n$OLD_SIMILAR" "$TMP/install-old.out")" "1"
kill $OLD_DEST $OLD_SIMILAR 2> /dev/null
wait 2> /dev/null
echo
echo "Install script output (first run):"; sed 's/^/  /' "$TMP/install.out" | sed "s|$TMP|<tmp>|g"
echo "Install script output (ps fails):"; sed 's/^/  /' "$TMP/install-fail.out" | sed "s|$TMP|<tmp>|g"
echo
if (( failures == 0 )); then echo "ALL PASS"; else echo "FAILURES: $failures"; exit 1; fi
