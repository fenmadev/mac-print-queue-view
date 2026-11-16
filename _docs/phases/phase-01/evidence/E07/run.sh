#!/bin/zsh
# Phase 01 evidence E07 (and the E06 and E08 runs that need queued jobs). Submits five held test
# jobs "MPQV E07 A" … "E" (lp -H hold: never printed) and three more that are canceled at once
# ("MPQV E08 X" … "Z", so that "Completed" has rows), runs E06, E08 and E07 against them, and
# removes them again, including from the completed-job history. Run only when the printer's queue
# holds no other job: E07 checks this and then refuses to move anything.
# Usage, from the project root: run.sh <printer> <temporary folder> [folder with older sources]
# With a third argument, E08 is also built with the ContentView.swift, QueueStore.swift and
# QueueLayout.swift found there (to show what it finds in an earlier version).
set -u
PRINTER="$1"; TMP="$2"; OLD="${3:-}"
HERE="$(dirname "$0")"
APP=MacPrintQueueView
mkdir -p "$TMP"
OTHER=$(lpstat -o "$PRINTER" | wc -l | tr -d ' ')
if [ "$OTHER" != "0" ]; then echo "Refusing: $PRINTER has $OTHER job(s) in its queue."; exit 1; fi
swiftc -O -module-cache-path "$TMP/cache" $APP/CUPSClient.swift "$HERE/../E04/purge/main.swift" -o "$TMP/purge" || exit 1
swiftc -O -module-cache-path "$TMP/cache" $APP/CUPSClient.swift $APP/PreviewBuilder.swift $APP/QueueLayout.swift \
  $APP/QueueStore.swift "$HERE/main.swift" -o "$TMP/e07" || exit 1
swiftc -swift-version 6 -Onone -parse-as-library -module-cache-path "$TMP/cache" $APP/CUPSClient.swift \
  $APP/PreviewBuilder.swift $APP/QueueLayout.swift $APP/QueueStore.swift $APP/JobRows.swift $APP/PDFPreview.swift \
  $APP/ContentView.swift "$HERE/../E06/main.swift" -o "$TMP/e06" || exit 1
swiftc -swift-version 6 -Onone -parse-as-library -module-cache-path "$TMP/cache" $APP/CUPSClient.swift \
  $APP/PreviewBuilder.swift $APP/QueueLayout.swift $APP/QueueStore.swift $APP/JobRows.swift $APP/PDFPreview.swift \
  $APP/ContentView.swift "$HERE/../E08/main.swift" -o "$TMP/e08" || exit 1
if [ -n "$OLD" ]; then
  swiftc -swift-version 6 -Onone -parse-as-library -module-cache-path "$TMP/cache" $APP/CUPSClient.swift \
    $APP/PreviewBuilder.swift "$OLD/QueueLayout.swift" "$OLD/QueueStore.swift" $APP/JobRows.swift $APP/PDFPreview.swift \
    "$OLD/ContentView.swift" "$HERE/../E08/main.swift" -o "$TMP/e08-old" || exit 1
fi
IDS=""
cleanup() {
  for ID in ${=IDS}; do cancel "$ID" 2> /dev/null; done
  sleep 1
  "$TMP/purge" "$PRINTER" ${=IDS}
}
trap cleanup EXIT
for N in A B C D E; do
  printf 'MPQV E07 test page %s\n' "$N" > "$TMP/$N.txt"
  ID=$(lp -d "$PRINTER" -H hold -t "MPQV E07 $N" "$TMP/$N.txt" | sed -E 's/.*-([0-9]+) .*/\1/')
  IDS="$IDS $ID"
done
# Three more test jobs, canceled at once, so that "Completed" has rows for E06 and E08.
for N in X Y Z; do
  printf 'MPQV E08 test page %s\n' "$N" > "$TMP/$N.txt"
  ID=$(lp -d "$PRINTER" -H hold -t "MPQV E08 $N" "$TMP/$N.txt" | sed -E 's/.*-([0-9]+) .*/\1/')
  IDS="$IDS $ID"
  cancel "$ID"
done
sleep 1
echo "test jobs:$IDS"
echo "== E06"; "$TMP/e06"; echo "E06 exit $?"
echo "== E08"; "$TMP/e08"; echo "E08 exit $?"
if [ -n "$OLD" ]; then echo "== E08 with the older sources"; "$TMP/e08-old"; echo "E08 (older sources) exit $?"; fi
echo "== E07"; "$TMP/e07" "$PRINTER"; echo "E07 exit $?"
cleanup; trap - EXIT
LEFT=$(for ID in ${=IDS}; do lpstat -W all -o "$PRINTER" | grep -c -- "-$ID " ; done | paste -sd+ - | bc)
echo "test jobs left in queue or history: $LEFT"
