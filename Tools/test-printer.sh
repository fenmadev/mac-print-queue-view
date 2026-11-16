#!/bin/zsh
# Test printer for Mac Print Queue View: MPQV_Testprinter accepts jobs but never prints them on
# paper. Its address is a port on this Mac where normally nothing listens, so the jobs wait. The
# printer is stopped, except while the `printing` command keeps one job "printing" (it keeps trying
# to reach that port). `complete` lets the printing job finish: for that one job a temporary
# receiver on this Mac takes the data and throws it away (/dev/null). Creating, removing, starting
# and stopping the printer need an administrator password.
#
# Usage:
#   Tools/test-printer.sh create        create MPQV_Testprinter if it does not exist
#   Tools/test-printer.sh remove        remove MPQV_Testprinter and all its jobs (only if it has
#                                       the test printer's address)
#   Tools/test-printer.sh jobs [count]  submit count test jobs (default 5) with random text, each
#                                       starting with the current date and time; creates the test
#                                       printer first if it does not exist
#   Tools/test-printer.sh printing      put the next waiting job in the "printing" state (paused
#                                       jobs are skipped, as by macOS)
#   Tools/test-printer.sh complete      let the job that is "printing" finish as completed; the
#                                       other jobs keep waiting
#   Tools/test-printer.sh sample        show the text of one test job without submitting it
set -u

PRINTER=MPQV_Testprinter
DESCRIPTION="MPQV Testprinter (prints nothing)"
PORT=59100
URI="socket://127.0.0.1:$PORT"
# Address used by earlier versions of this script and the README; switched to URI automatically.
OLD_URI=ipp://127.0.0.1:9/ipp/print
PPD=/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/Generic.ppd
WORDS_FILE=/usr/share/dict/words

# lpstat output in English, whatever the user's language.
lpstat_c() { LC_ALL=C LANG=C lpstat "$@" }

exists() { lpstat_c -p "$PRINTER" > /dev/null 2>&1 }
is_stopped() { lpstat_c -p "$PRINTER" | grep -q " disabled" }

# Number of the job the test printer is "printing", if any.
printing_job() { lpstat_c -p "$PRINTER" | sed -nE "s/.*now printing $PRINTER-([0-9]+).*/\1/p" | head -n 1 }

# Is something listening on the test printer's port? Then data could go somewhere unknown.
port_in_use() { lsof -nP -iTCP:$PORT -sTCP:LISTEN > /dev/null 2>&1 }

# State of a job (3 pending, 4 held, 5 printing, 6 stopped, 7 canceled, 8 aborted, 9 completed).
job_state() {
  local test
  test=$(mktemp -t mpqv-ipp) || return 1
  cat > "$test" <<'IPP'
{
  OPERATION Get-Job-Attributes
  GROUP operation-attributes-tag
  ATTR charset attributes-charset utf-8
  ATTR naturalLanguage attributes-natural-language en
  ATTR uri job-uri $uri
  ATTR name requesting-user-name $user
  ATTR keyword requested-attributes job-state
  STATUS successful-ok
  DISPLAY job-state
}
IPP
  ipptool -t -v "ipp://localhost/jobs/$1" "$test" 2> /dev/null | sed -nE 's/.*job-state \(enum\) = ([a-z-]+).*/\1/p' | head -n 1
  rm -f "$test"
}

# The test printer's address (device URI); empty when it cannot be read.
device_uri() { lpstat_c -v "$PRINTER" 2> /dev/null | sed -nE "s/^device for $PRINTER: //p" | head -n 1 }

# Does the test printer accept jobs? Prints "yes" or "no"; fails when the state cannot be read.
accepting() {
  local line
  line=$(lpstat_c -a "$PRINTER" 2> /dev/null) || return 1
  case "${line%%$'\n'*}" in
    "$PRINTER accepting requests"*) echo yes ;;
    "$PRINTER not accepting requests"*) echo no ;;
    *) return 1 ;;
  esac
}

# Is MPQV_Testprinter really this script's test printer? Read only: its address must be the test
# address or the earlier test address; any other address may belong to a real printer.
is_test_printer() {
  local uri
  uri=$(device_uri)
  [[ -n "$uri" && ( "$uri" == "$URI" || "$uri" == "$OLD_URI" ) ]] && return 0
  echo "Refusing: $PRINTER uses the address '${uri:-unknown}' instead of $URI; it may be a real printer." >&2
  return 1
}

# Makes sure the test printer uses its own address (switching from the old one) and accepts jobs;
# refuses when anything else listens on its port.
check_printer() {
  local uri
  uri=$(device_uri)
  if [[ "$uri" == "$OLD_URI" ]]; then
    echo "Switching $PRINTER to the address $URI (administrator password needed)…"
    sudo lpadmin -p "$PRINTER" -v "$URI" || return 1
    uri=$URI
  fi
  if [[ "$uri" != "$URI" ]]; then
    echo "Refusing: $PRINTER uses the address '$uri' instead of $URI." >&2
    return 1
  fi
  if port_in_use; then
    echo "Refusing: another program listens on port $PORT of this Mac; the test printer must not reach it." >&2
    lsof -nP -iTCP:$PORT -sTCP:LISTEN >&2
    return 1
  fi
  case "$(accepting)" in
    yes) ;;
    no)
      echo "Letting $PRINTER accept jobs (administrator password needed)…"
      sudo cupsaccept "$PRINTER" || return 1
      if [[ "$(accepting)" != yes ]]; then
        echo "Refusing: $PRINTER still does not accept jobs." >&2
        return 1
      fi
      ;;
    *)
      echo "Refusing: could not read whether $PRINTER accepts jobs." >&2
      return 1
      ;;
  esac
  # Never shared with other computers, also when printer sharing is on.
  if lpoptions -p "$PRINTER" 2> /dev/null | grep -q "printer-is-shared=true"; then
    echo "Making $PRINTER not shared (administrator password needed)…"
    sudo lpadmin -p "$PRINTER" -o printer-is-shared=false || return 1
  fi
}

stop_printer() {
  is_stopped || sudo cupsdisable "$PRINTER"
}

create() {
  if exists; then
    echo "$PRINTER already exists."
  else
    echo "Creating $PRINTER (administrator password needed)…"
    sudo lpadmin -p "$PRINTER" -D "$DESCRIPTION" -v "$URI" -P "$PPD" -o printer-is-shared=false || return 1
    # A new printer is stopped and rejects jobs; only let it accept jobs.
    sudo cupsaccept "$PRINTER" || return 1
    echo "Created $PRINTER: it accepts jobs and stays stopped."
  fi
  check_printer || return 1
  # Stopped unless a job is being kept "printing".
  [[ -n "$(printing_job)" ]] || stop_printer
}

remove() {
  if exists; then
    # Never remove a printer with another address, even if it has the test printer's name.
    is_test_printer || return 1
    echo "Removing $PRINTER and its jobs (administrator password needed)…"
    sudo lpadmin -x "$PRINTER" && echo "Removed $PRINTER."
  else
    echo "$PRINTER does not exist."
  fi
}

# Starts the printer so that macOS takes the next waiting job; that job keeps trying to reach the
# port where nothing listens, and so stays "printing".
printing() {
  local job i
  exists || { echo "$PRINTER does not exist; create it with: $0 create" >&2; return 1; }
  check_printer || return 1
  job=$(printing_job)
  if [[ -n "$job" ]]; then
    echo "Job $job is already printing (one job at a time)."
    return 0
  fi
  echo "Starting $PRINTER so that it takes the next waiting job (administrator password needed)…"
  sudo cupsenable "$PRINTER" || return 1
  for (( i = 0; i < 30; i++ )); do
    job=$(printing_job)
    [[ -n "$job" ]] && break
    sleep 0.5
  done
  if [[ -z "$job" ]]; then
    echo "No waiting job was taken (paused jobs are skipped). Stopping $PRINTER again."
    stop_printer
    return 1
  fi
  echo "Job $job is now printing. It stays so until: $0 complete"
}

# Lets the printing job finish: a temporary receiver on this Mac accepts exactly one connection and
# throws the data away; then the printer is stopped again, so the other jobs keep waiting.
complete() {
  local job state listener i
  exists || { echo "$PRINTER does not exist." >&2; return 1; }
  check_printer || return 1
  job=$(printing_job)
  if [[ -z "$job" ]]; then
    echo "No job is printing on $PRINTER. Start one with: $0 printing"
    return 1
  fi
  echo "Letting job $job finish (its data goes to /dev/null)…"
  nc -l 127.0.0.1 $PORT > /dev/null &
  listener=$!
  # macOS retries the connection every few seconds; wait up to two minutes.
  for (( i = 0; i < 240; i++ )); do
    state=$(job_state "$job")
    [[ "$state" == completed || "$state" == canceled || "$state" == aborted ]] && break
    sleep 0.5
  done
  kill $listener 2> /dev/null
  wait $listener 2> /dev/null
  stop_printer
  if [[ "$state" == completed ]]; then
    echo "Job $job is completed. $PRINTER is stopped again; the other jobs keep waiting."
  else
    echo "Job $job did not complete (state: ${state:-unknown}). $PRINTER is stopped." >&2
    return 1
  fi
}

# Random words, loaded once.
typeset -a WORDS
load_words() {
  if [[ -r "$WORDS_FILE" ]]; then
    WORDS=( ${(f)"$(< "$WORDS_FILE")"} )
  else
    WORDS=( lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua enim minim veniam quis nostrud )
  fi
}

# Text of one test job: the current date and time, a heading and a few paragraphs of random words.
job_text() {
  local number=$1 count=$2 paragraphs line words p w
  date '+%Y-%m-%d %H:%M:%S'
  echo
  echo "MPQV test job $number of $count"
  paragraphs=$(( RANDOM % 6 + 3 ))
  for (( p = 1; p <= paragraphs; p++ )); do
    echo
    words=$(( RANDOM % 30 + 15 ))
    line=""
    for (( w = 1; w <= words; w++ )); do
      # Two RANDOM values (each 0–32767) together reach every word of the list.
      line+="${WORDS[(RANDOM * 32768 + RANDOM) % ${#WORDS} + 1]} "
      if (( ${#line} > 70 )); then echo "${line% }"; line=""; fi
    done
    [[ -n "$line" ]] && echo "${line% }."
  done
}

submit_jobs() {
  local count=${1:-5} i file stamp result
  if [[ ! "$count" =~ '^[0-9]+$' ]] || (( count < 1 || count > 100 )); then
    echo "The number of jobs must be between 1 and 100 (got '$count')." >&2
    return 1
  fi
  exists || create || return 1
  check_printer || return 1
  # New jobs wait: the printer stays stopped unless a job is being kept "printing".
  [[ -n "$(printing_job)" ]] || stop_printer || return 1
  load_words
  file=$(mktemp -t mpqv-test) || return 1
  for (( i = 1; i <= count; i++ )); do
    job_text "$i" "$count" > "$file"
    stamp=$(head -n 1 "$file")
    result=$(lp -d "$PRINTER" -t "MPQV test $i – $stamp" "$file") || { rm -f "$file"; return 1; }
    echo "$result"
  done
  rm -f "$file"
  echo "Submitted $count test jobs to $PRINTER (they wait and are never printed on paper)."
}

case "${1:-}" in
  create) create ;;
  remove) remove ;;
  jobs) submit_jobs "${2:-5}" ;;
  printing) printing ;;
  complete) complete ;;
  sample) load_words; job_text 1 1 ;;
  *)
    sed -n '9,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
