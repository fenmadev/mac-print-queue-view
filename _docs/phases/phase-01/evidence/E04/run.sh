#!/bin/sh
# Phase 01 evidence E04. Creates the test jobs, runs the harness and removes the test jobs again,
# including from the completed-job history. Nothing is printed: A and B are held (lp -H hold),
# C and D have no document. Usage, from the project root: run.sh <printer> <temporary folder>
set -u
PRINTER="$1"; TMP="$2"
URI="ipp://localhost/printers/$PRINTER"
HERE="$(dirname "$0")"
mkdir -p "$TMP"
cat > "$TMP/create-job.test" <<'IPP'
{
  OPERATION Create-Job
  GROUP operation-attributes-tag
  ATTR charset attributes-charset utf-8
  ATTR naturalLanguage attributes-natural-language en
  ATTR uri printer-uri $uri
  ATTR name requesting-user-name $user
  ATTR name job-name $job_name
  STATUS successful-ok
  DISPLAY job-id
}
IPP
cat > "$TMP/jobs.test" <<'IPP'
{
  OPERATION Get-Jobs
  GROUP operation-attributes-tag
  ATTR charset attributes-charset utf-8
  ATTR naturalLanguage attributes-natural-language en
  ATTR uri printer-uri $uri
  ATTR name requesting-user-name $user
  ATTR boolean my-jobs true
  ATTR keyword which-jobs not-completed
  ATTR keyword requested-attributes job-id,job-state,job-priority
  STATUS successful-ok
  DISPLAY job-id
  DISPLAY job-state
  DISPLAY job-priority
}
IPP
# The user's jobs: job ID and priority (what a reorder would change). Their states are listed
# separately, as the user's own printing may change them during the run.
snapshot() { ipptool -t -v "$URI" "$TMP/jobs.test" | grep -E "job-(id|state|priority) " | paste - - - | sort; }
priorities() { sed -E 's/.*job-priority \(integer\) = ([0-9]+).*job-id \(integer\) = ([0-9]+).*/\2 \1/' "$1" | sort; }
snapshot > "$TMP/before.txt"
printf 'MPQV E04 test page A\n' > "$TMP/a.txt"; printf 'MPQV E04 test page B\n' > "$TMP/b.txt"
IDS=""
for N in A B; do
  ID=$(lp -d "$PRINTER" -H hold -t "MPQV E04 $N" "$TMP/$(echo $N | tr AB ab).txt" | sed -E 's/.*-([0-9]+) .*/\1/')
  IDS="$IDS $ID"
done
for N in C D; do
  ID=$(ipptool -t -v -d job_name="MPQV E04 empty $N" "$URI" "$TMP/create-job.test" | sed -nE 's/.*job-id \(integer\) = ([0-9]+).*/\1/p' | head -1)
  IDS="$IDS $ID"
done
echo "test jobs:$IDS"
swiftc -O -module-cache-path "$TMP/cache" MacPrintQueueView/CUPSClient.swift "$HERE/purge/main.swift" -o "$TMP/purge" || exit 1
cleanup() {
  for ID in $IDS; do cancel "$ID" 2>/dev/null; done
  sleep 1
  "$TMP/purge" "$PRINTER" $IDS
}
trap cleanup EXIT
swiftc -O -module-cache-path "$TMP/cache" MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
  MacPrintQueueView/QueueLayout.swift MacPrintQueueView/QueueStore.swift "$HERE/main.swift" -o "$TMP/e04" && "$TMP/e04" "$PRINTER"
cleanup; trap - EXIT
sleep 1
snapshot > "$TMP/after.txt"
# Every job present before and after must have the same priority.
priorities "$TMP/before.txt" > "$TMP/prio-before.txt"; priorities "$TMP/after.txt" > "$TMP/prio-after.txt"
CHANGED=$(join "$TMP/prio-before.txt" "$TMP/prio-after.txt" | awk '$2 != $3' | wc -l | tr -d ' ')
if [ "$CHANGED" = "0" ]; then echo "PASS other jobs: no priority changed ($(join "$TMP/prio-before.txt" "$TMP/prio-after.txt" | wc -l | tr -d ' ') jobs present before and after)"; else echo "FAIL other jobs: $CHANGED priorities changed"; fi
if ! cmp -s "$TMP/before.txt" "$TMP/after.txt"; then echo "note: states of other jobs changed during the run (the user's own printing):"; diff "$TMP/before.txt" "$TMP/after.txt" | grep -E "^[<>]" | sed -E 's/[[:space:]]+/ /g'; fi
LEFT=$(for ID in $IDS; do lpstat -W all -o "$PRINTER" | grep -c -- "-$ID " ; done | paste -sd+ - | bc)
echo "test jobs left in queue or history: $LEFT"
