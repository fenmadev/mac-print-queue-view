# Phase 01 — report 02

- Start (UTC): 2026-11-16T20:16:13Z (clock, first command of the review).
- End (UTC): 2026-11-16T20:24:21Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (model Claude Opus 5.5, ID `claude-opus-5-5`), read at the start of the review; new agent with fresh context, started with only the review brief.
- Scope: independent internal review of phase 01 round 1 ([executor report 01](01-executor-claude-Opus-5.5.md)): RM-001 (D38, D42), RM-003 (D39), RM-004 (D40, D41), RM-005 (D43), RM-006, RM-007 (D44), RM-008; criteria QUEUE-001-AC08–AC11, PREV-001-AC07–AC08, JOB-001-AC09–AC12; the working agreements (read directly), specs, README, plan, evidence E01–E07 and both scripts.
- Revision: git, baseline commit `55933af`; part of the round staged during the round, the rest unstaged; reviewed as `git diff HEAD` plus the untracked files (`Tools/install-release.sh`, `Tools/test-printer.sh`, evidence E06 and E07, executor report 01). `Tools/install-release.command` is staged as added and deleted in the working tree (renamed to `.sh`). Changed: `ContentView.swift`, `JobRows.swift`, `Localizable.xcstrings`, `PDFPreview.swift`, `QueueLayout.swift` (new), `QueueStore.swift`, README, both scripts, roadmap, model log, plan, evidence, QUEUE-001, PREV-001, JOB-001, inventory, scenarios, validation plan, architecture.
- Verdict: CHANGES REQUESTED.

I did not implement or fix anything; the only file I wrote is this report.

## Findings

### S1 — should fix: the list can show a completed row as selected that the app does not treat as selected

`QueueStore.selection` normalizes what the list asks for (D39) and returns early when the normalized set equals the current selection (`guard normalized != selectedJobIDs else { return }`). Nothing then tells the list to drop the rows it selected itself, so the table keeps them highlighted. The executor saw this with ⌘A (the list showed 16 selected rows; the store kept the 15 queued jobs) and lists it as an open point. The same happens whenever the normalized result equals the current selection, for example ⌘A when all queued jobs are already selected, or a ⇧-click range that runs into "Completed" while the queued part does not change. The highlighted completed row then gets the unselected row styling (`isSelected` comes from the store). The toolbar, ⌫ and the dialog act only on the queued jobs, so nothing unsafe happens. But QUEUE-001 rule 9 and AC09 say the completed job is dropped, and the window shows otherwise. The spec does not record this deviation. Either make the list follow the normalized selection, with a check that shows it, or get a user decision and record the deviation in QUEUE-001.

### S2 — should fix: unconfirmed test-printer behaviour presented as fact; no practical check for it

The README says that after `printing` "the job stays 'printing' and the others keep waiting", and that after `complete` "the printer is stopped again so the next job does not start". The plan and the executor report call these two assumptions that the user's first run must confirm, because they need an administrator password. Reading the script, the logic is plausible: the CUPS socket backend keeps retrying a refused connection, and stopping the printer should return a just-started job to waiting. Still, the README presents it as verified. Neither the validation plan nor the specs contain a practical check for it. The validation plan's phase-01 row also names only RM-001 and RM-003–RM-005, although RM-006–RM-008 are in this phase. Mark the two behaviours as unconfirmed in the README, or confirm them first. Add a practical check for `printing` and `complete` (and for RM-006 into the real Applications folder), and complete the phase row.

### M1 — minor: a ⇧-click range of completed jobs does not select "the top one of the range"

`QueueSelection.normalized` picks the highest job number among the newly added completed jobs. Suppose completed job 12 (the top row) is selected and the user ⇧-clicks job 10 below it. The result is job 11: neither the clicked job nor the top of the range (12), which is what QUEUE-001's "Observed, yet to be confirmed" says. This review's own harness confirmed it. Align the code or the wording.

### M2 — minor: toolbar texts for several jobs

The Cancel button's tooltip still says "Cancel the selected job right away (⌫)", but with several jobs it asks first. The Print Earlier/Later tooltips are singular. The "Cancel Jobs…" label (with an ellipsis) cancels at once without a dialog when only one of the selected jobs is the user's own, because `requestCancel` counts own jobs. JOB-001 rule 9 ("canceling several always asks first") does not mention this case.

### M3 — minor: `install-release.sh` does not normalize the destination folder

The pattern that finds a running copy is built from the destination as typed: `pgrep -f "^$TARGET/Contents/MacOS/"`. A trailing slash (verified: the script printed `…/install//Mac Print Queue View.app`), a relative path or a symlinked path (`/tmp` → `/private/tmp`) does not match the running process. The script then removes and replaces the bundle of a running copy. It also goes ahead after 5 seconds if the copy has not quit. The `rm -rf` target is always `<destination>/Mac Print Queue View.app`, so the removal itself is limited to that bundle. Resolve the destination to an absolute physical path, and stop if the copy is still running.

### M4 — minor: E06 does not check that its "completed row" step selects a completed job

E06 selects row `numberOfRows - 3` as the completed row. In this review's re-run there was one completed job in the history, so that row was a queue row ("select completed row → selected: queued"), and E06 still passed. The evidence register's "the toolbar changes between 13, 6 and 11 items" therefore depends on the job history. Choose the row by section or assert that a completed job is selected.

### M5 — minor: pausing several jobs stops at the first failure

`pause(_:)` holds the jobs in one loop that stops at the first error. The remaining jobs are not paused and the message does not say which ones. Cancel goes on after a failure and reports the first error. JOB-001 rule 9 says "the others are paused". Also, the state is checked once for all jobs (as the rule says), so the gap between that check and a job's hold grows with the number of jobs. Rule 8 states this kind of gap for removal; rule 9 does not.

### M6 — minor: wording in the scenarios

`scenarios.md` says a grid drag makes the jobs "swap places". It is an insertion: E onto B in B D E gives E B D (JOB-001 behaviour 11).

### O1 — optional: ⌥⌘= and ⌥⌘- are also the macOS Accessibility Zoom shortcuts

When "Use keyboard shortcuts to zoom" is on, the system takes these keys before the app. D38 stays as decided; the limitation could be mentioned to the user or in the README.

### O2 — optional: test printer hardening

`create` could add `-o printer-is-shared=false`, so the test printer is never shared on the network when printer sharing is on. The README could also say that while `printing` keeps the printer started, a program that starts listening on port 59100 later would receive job data (the port check runs only when a command starts).

### O3 — optional: grid drag with another user's waiting job in the selection

`moveInGrid` arranges only the movable blocks. When a non-movable waiting block (another user's job) lies between the dragged block and the target, the result differs from "the blocks in between shift one place" (JOB-001 behaviour 11). This is an edge case: record it, or accept it as is.

### O4 — optional: robustness of the divider line

`DividerMarkView` is added to the split view's superview, a container managed by SwiftUI and AppKit. It is put back only after a thumbnail step change or when the window changes, and it is positioned only on `didResizeSubviewsNotification`. If the framework removes or covers it, or the split view moves without resizing its subviews, the line is missing or misplaced until the next step change. Nothing crashes: the split view's class is untouched and E06 passes. With the job column collapsed or in full screen, the line's position has not been checked. Add these cases to practical check 15.

## Checks performed

| Check | Result |
| --- | --- |
| Code review of `QueueLayout.swift`, `QueueStore.swift`, `ContentView.swift`, `JobRows.swift`, `PDFPreview.swift` against D38–D44 and the specs | Selection rules, D44 refresh rule, gathered move, grid move and rearrangement, the cupsd re-check in `apply` (moved jobs must still be waiting, current priorities used, only own jobs changed), the pause re-check, the cancel confirmation, toolbar and context menu consistency: correct apart from S1, M1, M2, M5 and O3 |
| AppKit integration (`ColumnSplitSupport`, `DividerMarkView`, window widening) | The split view's class is untouched (only the public `dividerStyle`); the line view returns nil from `hitTest`; the observer is selector-based; the window widens only on overflow and stays within the screen's visible frame. Robustness notes in O4 |
| Debug and Release clean builds, temporary derived data under /private/tmp | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line |
| String Catalog (script over `Localizable.xcstrings`) | 101 keys; every translatable key has `translated` Dutch and Turkish values; placeholders match (Turkish uses positional `%1$lld`/`%2$lld` correctly); 0 stale; the 14 new keys match the new strings in the code |
| E01 re-run (compiled with `QueueLayout.swift`) | Output identical to `E01/results.txt` |
| E02 and E05 re-run (E05: off-screen window, only reads the queue) | Output identical to their results files |
| Own randomized harness: `gatheredMove` (up and down) against an independent reference model, `rearranged` invariants (permutation, other jobs fixed, members in the arranged order), `gridMove`, 20,000 random cases; selection and refresh rules by example | All pass; the ⇧-range case behind M1 found |
| E07/run.sh (with E06) on `Brother_MFC_J6520DW` after checking that its queue was empty (`lpstat -o`: 0 jobs) | Five held test jobs #1071–#1075; E06 survived all selections, 9-point divider, line and grip bright, clicks reach the split view; E07 all PASS (B D A C E, A B D C E, grid D onto B → A D B C E, list drag → C E A D B); all five purged, 0 left in queue or history; nothing printed |
| Harness source hashes | All ten SHA-256 values in the evidence register match the files |
| Source times against evidence runs | `QueueStore.swift` last changed 19:38:39Z, before the last E04 run (19:39:49Z); `ContentView.swift` changed 19:25:28Z, before the last E06 run |
| `install-release.sh` with a temporary destination under /private/tmp, twice (the second time with a trailing slash) | Built, verified the signature and copied; replaced the earlier copy; the trailing slash gives a double-slash path (M3) |
| `test-printer.sh`: usage, `sample`, `jobs 0`, `jobs abc`, `jobs 101`, `jobs -3`, `zsh -n` on both scripts | Usage shown; sample text starts with date and time; invalid counts refused before any action; syntax OK. `create`, `remove`, `printing` and `complete` not run (they need administrator rights, which this review does not use) |
| `test-printer.sh` logic, read | Acts only on `MPQV_Testprinter`; `sudo` is used only for `lpadmin`, `cupsaccept`, `cupsenable` and `cupsdisable` on that printer; it refuses another address and a listener on port 59100; `complete` accepts one connection to `/dev/null`; test jobs are submitted only with `-d MPQV_Testprinter`; nothing can reach a real printer. Assumptions as in S2 |
| README, specs, inventory, roadmap, plan, evidence register, model log | Consistent with the code apart from S2, M1, M2 and M6; D38–D44 recorded; no unverified result claimed as tested apart from S2 |

## Criteria

| Criterion | Assessment |
| --- | --- |
| QUEUE-001-AC08 | PASS (software): seven steps, limits, not stored, column and window widening (E01, E05 re-run). Buttons and shortcuts in the real window are a practical check |
| QUEUE-001-AC09 | PASS for the store's rules (E01, own harness, E04); the window can show a different selection (S1). ⌘-click in the real list not exercised |
| QUEUE-001-AC10 | PASS (software): 9-point dividers, line and grip drawn, clicks reach the split view (E05, E06 re-run). Appearance and an actual drag are a practical check |
| QUEUE-001-AC11 | PASS: D44 rule in code and E01; E04 against cupsd. A really printed job not used (paper) |
| PREV-001-AC07 | PASS (software): grid layout (E01), first-page blocks and page count (E02 re-run), print order and controls hidden (code). The grid in the real window is a practical check |
| PREV-001-AC08 | NOT TESTED: order number badge correct in code (index + 1, row by row); visual check pending |
| JOB-001-AC09 | PASS: confirmation for several jobs and immediate cancel for one (code, E04); dialog not seen. Edge case in M2 |
| JOB-001-AC10 | PASS: E07 re-run against cupsd with held test jobs (B D A C E, down mirror, list drag) and own reference model |
| JOB-001-AC11 | PASS for resume (E04) and for the pause logic by code review; pausing several pending jobs NOT TESTED (it would print without the test printer); M5 |
| JOB-001-AC12 | PASS: E01 (the AC12 example) and E07 re-run (grid drag applied to cupsd) |

## Pending practical checks

- Validation plan items 12–15 in the real window: thumbnail buttons and shortcuts, window widening, ⌘-click/⇧-click/⌘A (S1), the grid with order numbers in light and dark mode, both cancel dialog buttons, dragging rows and grid blocks (including dragging a block by its page image, which is a PDFKit view with hit testing off), the divider's appearance and dragging (also with a collapsed column and in full screen, O4).
- `test-printer.sh create`, `printing` and `complete` with an administrator password (S2); pausing several pending jobs on the test printer.
- `install-release.sh` into the real Applications folder, including quitting a running copy.
