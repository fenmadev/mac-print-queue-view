# Phase 01 — report 08

- Start (UTC): 2026-11-16T21:48:01Z (clock, when rounds 1–3 were staged as the baseline after receiving report 07).
- End (UTC): 2026-11-16T21:56:32Z (clock).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor session (`claude-opus-5-5`, Claude Opus 5.5).
- Scope: round 4 — findings R1–R4 (all should fix) of [external review 07](07-external-gpt-6.1-sol.md), which followed the internal approval of round 3 (report 06). Requirements touched: RM-008 (test printer script), RM-006 (install script), JOB-001-AC11 and D17 (pausing several jobs). Optional points O1–O2 of review 06 stay open.
- Revision: git, baseline commit `55933af`; rounds 1–3 staged as the review baseline at 2026-11-16T21:48:01Z; this round's changes are unstaged (`git diff`), plus the untracked folder `evidence/E09/` and this report. Changed: `CUPSClient.swift`, `QueueLayout.swift`, `QueueStore.swift`, `Tools/test-printer.sh`, `Tools/install-release.sh`, README, JOB-001, evidence E01 (`main.swift`, results), evidence E09 (new: `run.sh`, results), evidence register, plan, model log.
- Verdict: READY FOR REVIEW.

## Changes per finding

| Finding | Change |
| --- | --- |
| R1 | `test-printer.sh remove` now calls the read-only `is_test_printer` before `sudo lpadmin -x`: the device URI (read with `lpstat -v`, the line for exactly `MPQV_Testprinter`) must equal the test address `socket://127.0.0.1:59100` or the earlier test address `ipp://127.0.0.1:9/ipp/print`; any other, empty or unreadable address is refused without an administrator command. The earlier address is accepted for removal because it was the documented test address and leads nowhere (discard port 9 on this Mac); it is not migrated first. `check_printer` uses the same exact URI reading. Usage text and README say so. |
| R2 | New `accepting` helper: reads `lpstat -a` (C locale), first line; `MPQV_Testprinter accepting requests…` → yes, `MPQV_Testprinter not accepting requests…` → no, anything else or a failing `lpstat` → failure. `check_printer` runs `cupsaccept` only for "no", then reads the state again and refuses unless it is now "yes"; an unreadable state is refused. |
| R3 | `install-release.sh` no longer uses `pgrep -f` with the path as a regular expression. `running_copies` reads `ps -axww -o pid= -o command=` and compares each command line with `"$TARGET/Contents/MacOS/"*` (quoted, so the path is literal text in the zsh pattern). A failing or empty `ps` stops the script before anything is replaced, also during the wait for the quit. While testing, a second defect of the earlier version showed up: `kill $PIDS` passed several process numbers as one argument (zsh does not split words), so several running copies were never quit; now `kill ${(f)PIDS}`. |
| R4 | New pure `BulkPause.run` (`QueueLayout.swift`): for each candidate in order, read its state, then hold it only if it is waiting; printing jobs are counted as started, other states skipped; a failing state query or hold is recorded (first error kept) and the next job is still handled. `QueueStore.pause(_:)` uses it with `CUPSClient.jobStatus(id:)` (new, `Get-Job-Attributes` through the existing `jobState`) and `holdJob`, so each job is re-checked immediately before its own Hold-Job. The started count now comes from these per-job checks. `JobStatus` gained an initializer from `ipp_jstate_t` (the mapping moved from `PrintJob.status`, unchanged). JOB-001 rule 9 (v4) describes the per-job check and keeps the honest limit that query and hold of one job are separate requests. |

## Checks

| Check | Result |
| --- | --- |
| E01 (pure logic, now with a fake client for `BulkPause`) | 68 checks, ALL PASS; the 63 earlier lines are identical. New: B turns printing while A is held → B is checked again and never held, C still held; the same when holding A fails; an unreadable state of B → B not held, C still held; printing/other states not held. Negative control: the earlier snapshot approach with the same fake client holds B while it prints. |
| E09 (new; both scripts, isolated) | 26 checks, ALL PASS. Stub commands only (no real `lpstat`/`sudo`/admin tool is reached; direct calls to `lpadmin`, `cupsaccept`, `cupsenable`, `cupsdisable`, `lp`, `ipptool`, `nc` would be logged and fail — none occurred). R1: 4 refusal cases, 2 removal cases, 1 absent printer. R2: accepting, not accepting (accept + re-check), accept without effect, unreadable, unknown text, other address. R3: dummy programs compiled by the harness running as the app executable from `…/install [x](y)+.v1/dest.v1` (two copies) and from `…/destXv1`; both destination copies quit, the similar one keeps running, the destination replaced; with a failing `ps` exit 1 and nothing replaced. Negative controls run the review-07 versions from the git index under the same stubs: `remove` removes a printer with another address; `create` takes "not accepting" for accepting; the install script selects the similar folder's dummy as well (then fails to quit either, see R3). |
| E02 | ALL PASS; identical to its results file apart from PNG byte sizes (re-run because `CUPSClient.swift` changed). |
| E06, E07, E08 | Compiled with the changed sources (Swift 6 mode for E06/E08); not run, as they need queued test jobs and do not exercise pausing pending jobs. |
| Debug and Release builds (fresh derived data in a temporary folder) | Both succeed; 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line. |
| String Catalog | Unchanged; no new app strings. |
| `zsh -n` on both scripts and on E09 `run.sh`; `git diff --check` | Pass. |

A first E09 run used copies of `/bin/sleep` as dummies; macOS killed those copies at once (exit 137), so that run showed false results for the "untouched" checks and its negative control was meaningless. It was discarded; the harness now compiles its own dummy and asserts that the dummies run before each install. Nothing printed; no print job, printer, installed app or process other than the harness's own dummies was touched; no administrator command ran.

## Open points

- Pausing several pending jobs against cupsd is still not run (a pending job with a document would print); R4 is covered by the pure logic with a fake client and by code review of the store's use of it.
- The E09 negative controls read the review-07 script versions from the git index; after a commit they would read the new versions. The results file records the run.
- Unchanged from earlier reports: practical checks 12–17 (including the administrator-driven test-printer commands and the real install); optional O1–O2 of review 06; implementation defaults in the plan open for the user.
