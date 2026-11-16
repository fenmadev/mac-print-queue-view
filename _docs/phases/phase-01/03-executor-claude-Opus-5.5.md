# Phase 01 — report 03

- Start (UTC): 2026-11-16T20:25:34Z (clock, when the round-1 baseline was staged after receiving report 02).
- End (UTC): 2026-11-16T20:35:44Z (clock).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor session (`claude-opus-5-5`, Claude Opus 5.5).
- Scope: round 2 — the findings of [internal review 02](02-internal-claude-Opus-5.5.md) (CHANGES REQUESTED): S1 and S2 (should fix), M1–M6 (minor) and O1–O4 (optional). Criteria touched: QUEUE-001-AC09, JOB-001-AC09–AC11, and the scripts of RM-006 and RM-008.
- Revision: git, baseline commit `55933af`; round 1 staged as the review baseline at 2026-11-16T20:25:34Z; this round's changes are unstaged (`git diff`), plus the untracked evidence folder E08 and this report. Changed: `ContentView.swift`, `QueueStore.swift`, `QueueLayout.swift`, `Localizable.xcstrings`, `README.md`, `Tools/install-release.sh`, `Tools/test-printer.sh`, evidence E01, E04, E06, E07 (and their results), the evidence register, the plan, the model log, QUEUE-001, JOB-001, scenarios, validation plan.
- Verdict: READY FOR REVIEW.

## Changes per finding

| Finding | Change |
| --- | --- |
| S1 | `QueueStore.selection` counts corrections (`selectionCorrections`) whenever the rules change what the list asked for; the job list reads it, so it redraws and the table drops the rows it highlighted itself, also when the selection kept by the rules does not change. New check E08 (built like E06): ⌘A, ⌘A again, a ⇧-range from the queue into "Completed", a ⇧-range within "Completed" — the highlighted job rows equal the store's selection. With the round-1 sources, E08 shows the deviation (second ⌘A: 9 rows highlighted, 5 kept). Remaining: in the ⇧-range into "Completed", the "Completed" section header stays highlighted when rows are selected programmatically; whether a real ⇧-click can do that is added to practical check 13. |
| S2 | README: the behaviour of `test-printer.sh printing` and `complete` is marked as not yet confirmed (they need an administrator password and have not run). Validation plan: phase-01 row lists RM-006–RM-008; new practical checks 16 (test printer: `create`, `jobs`, `printing`, `complete`, `remove`, nothing printed) and 17 (install script into `~/Applications`, also while the installed copy runs). |
| M1 | `QueueSelection.normalized`: a ⇧-click range of completed jobs keeps the clicked job — the end of the range farthest from the previous selection (below → lowest job number, above → highest); QUEUE-001 wording updated. E01 has cases for both directions; E08 confirms it in the list. |
| M2 | Tooltips for several selected jobs (move as one block, pause the waiting ones, resume the paused ones, cancel after confirmation), 5 new strings translated into Dutch and Turkish. The cancel button and menu item say "Cancel Jobs…" only when more than one of the selected jobs can be canceled (the user's own), matching when the dialog appears; JOB-001 rule 9 states this. |
| M3 | `install-release.sh` resolves the destination to its absolute physical path (no trailing slash, relative part or symbolic link) before looking for a running copy, and stops if that copy does not quit within 10 seconds. Tested with a relative path with a trailing slash and with a symbolic-link path (`/tmp/…`) while the installed copy was running: it was found and quit, then replaced. |
| M4 | E06 selects the last row of the list for its "completed row" step and asserts for every step that the intended kind of job (queued or completed) is selected. |
| M5 | Pausing several jobs goes on after a failure and reports the first error (as canceling does). JOB-001 rule 9 states that the jobs are paused one after another and that the time between the state check and each pause grows with the number of jobs. |
| M6 | `scenarios.md`: a grid drag is described as an insertion (the dragged job takes the target's place, the blocks in between shift), not a swap. |
| O1 | README: if macOS Accessibility Zoom keyboard shortcuts are on, macOS takes ⌥⌘= / ⌥⌘-; use the toolbar buttons. D38 unchanged. |
| O2 | `test-printer.sh` creates the printer with `printer-is-shared=false` and makes an existing one not shared; the README notes that a program listening on port 59100 after `printing` started would receive the job data. |
| O3 | JOB-001 edge case: grid drag with another user's waiting job between the blocks (not listed in practice, D6). |
| O4 | The divider line is also re-placed when the split view's own frame changes (`frameDidChangeNotification`); practical check 15 now covers a hidden printer column, full screen and moving between screens. |

## Checks

| Check | Result |
| --- | --- |
| E01 | 63 checks PASS (round 1 reported 61; the actual count then was 62 — corrected in the register) |
| E04 (live, held and empty test jobs #1105–#1108) | ALL PASS after the store changes; queue held no other job; 0 test jobs left |
| E06, E07, E08 (live through `E07/run.sh`, five held and three canceled test jobs #1097–#1104) | E06 PASS (each step asserted), E07 ALL PASS (moves applied to cupsd), E08 ALL PASS; E08 with the round-1 sources fails as expected; 0 test jobs left |
| E02, E03, E05 | Output identical to their results files |
| Debug and Release builds | Both succeed; 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line (2026-11-16T20:34:34Z) |
| String Catalog | 106 keys, 105 translatable, 0 missing, 0 stale (5 new keys this round) |
| Scripts | `install-release.sh` into temporary folders (relative path with trailing slash; symbolic-link path with the installed copy running); `test-printer.sh` syntax; nothing needing an administrator password was run |

Nothing printed; all test jobs were removed, including from the completed-job history. To provide "Completed" rows for E06 and E08, `E07/run.sh` now also submits three held test jobs and cancels them at once (removed afterwards with the others).

## Open points

- Practical checks 12–17 (real window, test printer commands with an administrator password, install into `~/Applications`).
- Whether a real ⇧-click range into "Completed" can leave the section header highlighted (E08 shows it only for a programmatic selection).
- Pausing several pending jobs is still not run (a pending job with a document would print).
- Implementation defaults in the [plan](plan.md) remain open for the user.
