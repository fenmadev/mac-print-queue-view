# Phase 01 — report 04

- Start (UTC): 2026-11-16T20:36:29Z (clock, first command of the review).
- End (UTC): 2026-11-16T20:42:10Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (model Claude Opus 5.5, ID `claude-opus-5-5`), read at the start of the review; new agent with fresh context, started with only the review brief.
- Scope: independent internal re-review of phase 01 round 2 ([executor report 03](03-executor-claude-Opus-5.5.md)), answering [internal review 02](02-internal-claude-Opus-5.5.md) (S1, S2, M1–M6, O1–O4); re-assessment of QUEUE-001-AC09 and JOB-001-AC09–AC11 and of the parts of the phase that round 2 touched (selection setter and redraw counter, `QueueSelection.normalized`, pause loop, cancel labels and tooltips with their Dutch and Turkish texts, divider observers, both scripts, README, validation plan, JOB-001, QUEUE-001, scenarios, evidence register, E01, E04, E06, E07/run.sh, E08). The working agreements were read directly.
- Revision: git, baseline commit `55933af`; round 1 staged (the baseline of review 02, `git diff --cached`); round 2 unstaged (`git diff`): `ContentView.swift`, `QueueStore.swift`, `QueueLayout.swift`, `Localizable.xcstrings`, README, `Tools/install-release.sh`, `Tools/test-printer.sh`, model log, plan, QUEUE-001, JOB-001, scenarios, validation plan, evidence register, E01 (harness and results), E04 results, E06 harness, E07 results and `run.sh`; untracked: evidence folder E08 and executor report 03.
- Verdict: APPROVED.

I did not implement or fix anything; the only file I wrote is this report.

## Resolution of the findings of review 02

| Finding | Status | Verified in |
| --- | --- | --- |
| S1 — list shows a completed row as selected | Resolved | `QueueStore.selection` increments `selectionCorrections` whenever the rules change what the list asked for; `JobList.body` reads it, so the list is redrawn with the corrected selection even when the kept selection is unchanged. No feedback loop: the corrected value normalizes to itself. My own E08 re-run: ALL PASS with the current sources; built with the staged round-1 sources the second ⌘A left 9 rows highlighted while 5 were kept (FAIL). The "Completed" header row stays highlighted after a programmatic range selection; that a real ⇧-click can do this is recorded as unknown in QUEUE-001's traceability and added to practical check 13 |
| S2 — unconfirmed test-printer behaviour presented as fact | Resolved | README marks `printing`/`complete` behaviour as "Not yet confirmed" and uses "should"; validation plan phase-01 row lists RM-006–RM-008; new practical checks 16 (test printer) and 17 (install script) |
| M1 — ⇧-range of completed jobs | Resolved | `normalized` returns the lowest added job for a range below the previous selection and the highest otherwise; E01 has both directions (63 PASS, re-run identical to its results file); QUEUE-001, plan and comment agree. See N2 for E08's check of it |
| M2 — toolbar texts for several jobs | Resolved | Tooltips for several jobs on Print Earlier/Later, Pause, Resume and Cancel; label "Cancel Jobs…" / "Cancel Job" and the cancel tooltip follow `cancelableCount`, the same count `requestCancel` uses, in the toolbar and the context menu; JOB-001 rule 9 states it. 5 new keys, extracted by the compiler, translated into Dutch and Turkish in the existing terminology |
| M3 — install destination not normalized | Resolved | Destination resolved with `pwd -P` after `mkdir -p`; stops when the copy has not quit after 10 seconds. Run by me: relative path with trailing slash (installed to the physical path); `/tmp/…/` symbolic-link path with trailing slash while a copy started from the physical path ran (found, quit, replaced, no process left); a stand-in process under the destination that ignores SIGTERM (script stopped with the "did not quit" message, exit 1, nothing copied) |
| M4 — E06 completed-row step | Resolved | E06 selects the last row and asserts the kind of job selected at every step; my re-run selected a completed job and passed |
| M5 — pause stops at first failure | Resolved for pause | Pause loop continues and reports the first error; JOB-001 rule 9 states the sequential pausing and the growing check-to-pause gap. Resume still stops at the first failure: see N1 |
| M6 — scenarios wording | Resolved | Grid drag described as an insertion |
| O1 — Accessibility Zoom shortcuts | Done | README note; D38 unchanged |
| O2 — test printer hardening | Done | `create` adds `printer-is-shared=false`; `check_printer` makes an existing shared test printer not shared (`lpoptions -p` was confirmed read-only to print `printer-is-shared=…`); README notes the port-59100 risk while `printing` keeps the printer started |
| O3 — grid drag around another user's job | Done | Recorded as a JOB-001 edge case (does not occur in practice, D6) |
| O4 — divider line robustness | Done | Also re-placed on the split view's `frameDidChangeNotification`; observers removed and re-added together; practical check 15 extended. Setting `postsFrameChangedNotifications` is a no-op in practice (the default is `true` for `NSView` and `NSSplitView`, checked), so the split view is effectively still changed only through `dividerStyle` |

## New findings

### N1 — minor: resuming several jobs still stops at the first failure

`resume(_:)` releases the jobs in `for id in held { try CUPSClient.releaseJob(id: id) }`, so a CUPS error on one job leaves the remaining selected paused jobs paused, without saying which. Round 2 changed pause and cancel to go on and report the first error; JOB-001-AC11 says "Resume resumes every selected paused job". Only an error case; nothing unsafe. Make resume behave like pause, or state the difference in JOB-001 rule 9.

### N2 — minor: E08's ⇧-range check does not distinguish the M1 fix

E08 asserts only that the kept job is lower than the anchor (`clicked.first! < anchor.first!`). The round-1 code also satisfies this (it keeps the highest added job, which is still below the anchor): in both runs with the round-1 sources this step passed (executor: `1095 → [1094]`; this review: `1115 → [1114]`, while the current code gave `1115 → [1070]`, the last row). The executor report's "E08 confirms it in the list" therefore rests on the printed value, not on the assertion. E01 covers M1 correctly at the logic level. Assert that the kept job is the job of the clicked (last) row, or reword the claim.

### N3 — optional: validation item 15 also carries an AC11 check

Round 2 appended "a job leaving the queue deselects it (QUEUE-001-AC11)" to practical check 15, which is about the column divider. It would read better as its own item or with item 13.

## Checks performed

| Check | Result |
| --- | --- |
| Code review of the round-2 diff (`QueueStore.swift`, `ContentView.swift`, `QueueLayout.swift`) and the surrounding code | Selection setter, counter and redraw; normalization cases (range down/up, from nothing, single added, queued kept); cancel label, tooltip and `requestCancel` use the same count; pause loop; divider observers. Correct apart from N1 |
| Clean Debug build, temporary derived data under /private/tmp | `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line |
| Release builds (through `install-release.sh`, temporary build folder under /private/tmp, three runs) | `BUILD SUCCEEDED`, signature verified; no compiler warnings |
| String Catalog against the compiler's extracted strings (`.stringsdata` of the Debug build) | 106 extracted keys = 106 catalog keys; all 5 new tooltips extracted as localizable (so the ternaries resolve to `LocalizedStringKey`); 0 missing Dutch or Turkish, 0 stale |
| E01 re-run (compiled with `QueueLayout.swift`) | 63 PASS, output identical to `E01/results.txt`; the round-1 results file has 62 PASS lines, as the register now says |
| `E07/run.sh` with E06, E08, E08 built with the staged round-1 sources, and E07, on `Brother_MFC_J6520DW` after checking that its queue was empty (`lpstat -o`: 0 jobs) | Held test jobs #1109–#1113 and three canceled at once #1114–#1116. E06 PASS (each step asserted; toolbar 13/6/11 items; 9-point divider; line and grip bright; clicks reach the split view). E08 ALL PASS. E08 with round-1 sources: 1 FAIL (second ⌘A: 9 highlighted, 5 kept); its ⇧-range-in-Completed step passed (N2). E07 ALL PASS (B D A C E, A B D C E, grid D onto B → A D B C E, list drag → C E A D B). All eight purged; 0 left in queue or completed history; nothing printed |
| `install-release.sh` into temporary folders under /private/tmp (three cases, see M3) | As described under M3; the started copy was quit by the script and no copy was left running |
| `test-printer.sh`: `zsh -n`, usage, `jobs 0`; logic of the round-2 change read | Syntax OK; usage shown; invalid count refused. `create`, `printing`, `complete`, `remove` not run (administrator rights) |
| Harness hashes | All eleven SHA-256 values in the evidence register match the files |
| Source and evidence times | Round-2 source changes 20:26:13Z–20:27:46Z; E01 results 20:28:32Z, E04 results 20:33:52Z, E07/E08 results 20:33:43Z: evidence produced after the last code change |
| README, specs, plan, model log, evidence register, executor report 03 | Consistent with the code and with my runs apart from N2 (claim in report 03) and N3; no unverified behaviour presented as verified |
| Project files and the local environment | No working-agreement file names, editor settings or local build folder named in the round-2 changes; `~/Applications` appears only as the install script's documented default destination |

## Criteria touched by round 2

| Criterion | Assessment |
| --- | --- |
| QUEUE-001-AC09 | PASS (software): store rules (E01, E04) and the list now highlights what the store keeps (E08, re-run here; round-1 code fails). ⌘-click/⇧-click in the real window and the section-header highlight are practical check 13 |
| JOB-001-AC09 | PASS: confirmation for several, immediate cancel for one (E04); label and tooltip now match when the dialog appears. Dialog not seen (practical check 14) |
| JOB-001-AC10 | PASS: E07 re-run against cupsd with held test jobs |
| JOB-001-AC11 | PASS for resume of several (E04) and the pause logic by code review; pausing several pending jobs NOT TESTED (would print without the test printer); resume after a failure: N1 |

The other criteria of the phase were not changed by round 2; their assessment in review 02 stands (QUEUE-001-AC08, AC10, AC11, PREV-001-AC07 PASS for the software part; PREV-001-AC08 NOT TESTED, visual; JOB-001-AC12 PASS).

## Overall phase assessment

Both should-fix findings of review 02 are resolved and verified in the files and by re-running the checks; the minor and optional findings are handled. Round 2 introduced no regression found by code review, builds, the string check or the live re-runs. N1 and N2 are minor and do not block; if they are addressed, the changes need a new internal review. Software approval does not cover the practical checks below.

## Pending practical checks

- Validation plan items 12–15 in the real window, including ⌘A and ⇧-click ranges into and within "Completed" (no completed row or section header may stay highlighted) and the divider with a hidden printer column, in full screen and across screens.
- Item 16: `test-printer.sh create`, `printing`, `complete`, `remove` with an administrator password (the README marks their behaviour as not yet confirmed); pausing several pending jobs on the test printer.
- Item 17: `install-release.sh` into the real Applications folder, also while the installed copy runs.
