# Phase 01 — report 01

- Start (UTC): 2026-11-16T18:10:08Z (clock, first sample after reading the roadmap and the phase 01 plan).
- End (UTC): 2026-11-16T20:15:18Z (clock).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor session (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the round.
- Scope: round 1 of phase 01, everything the user asked for in this phase until the user's signal to start the report: RM-001 thumbnail sizes (D38, D42), RM-003 several selected queue jobs with actions and a grid preview (D39), RM-004 reordering in the grid (D40) with order numbers (D41), RM-005 visible, thicker column divider (D43), RM-006 release install script, RM-007 deselecting a job that leaves the queue (D44), RM-008 test printer script. Criteria QUEUE-001-AC08–AC11, PREV-001-AC07–AC08, JOB-001-AC09–AC12. The user's decisions were taken in this session and are recorded in the inventory.
- Revision: git, baseline commit `55933af` (phase 00). Part of the round's changes was staged during the round, not by the executor; the rest is unstaged, and `git diff HEAD` plus `git status` (untracked: `Tools/install-release.sh`, `Tools/test-printer.sh`, evidence E06 and E07, this report) show the whole round. `Tools/install-release.command`, created in this round, was renamed to `Tools/install-release.sh` (the index still lists the old name as added). Changed or new: `ContentView.swift`, `JobRows.swift`, `Localizable.xcstrings`, `PDFPreview.swift`, `QueueLayout.swift` (new), `QueueStore.swift`, `README.md`, both tool scripts, the roadmap, the model log, the phase 01 plan and evidence E01–E07, QUEUE-001, PREV-001, JOB-001, inventory, scenarios, validation plan, architecture.
- Verdict: READY FOR REVIEW.

## Changes

**User decisions** ([inventory](../../../_specs/inventory.md)): D38 (thumbnail steps from 40 × 52 points, step *n* = *n* × step 1, toolbar buttons and ⌥⌘= / ⌥⌘-, not remembered; kept in the toolbar after the user tried the app), D39 (several queue jobs: selection rules, grid 2 / 2 × 2 / 3 × 3 / 4 × 4 with the first 16 shown, first page only, confirmation when canceling several, gathered move B D A C E), D40 (drag one grid block at a time; applied to the queue right away, confirmed by the user; a following block move keeps the grid order), D41 (order number bottom right of each block), D42 (seven steps; the job column and, if needed, the window widen), D43 (thicker, clearly visible divider before the preview), D44 (a selected job that leaves the queue is deselected, so its preview disappears). Roadmap: RM-001 and RM-003–RM-008 in progress.

**Code.**

- `QueueLayout.swift` (new): pure logic — `ThumbnailZoom` (seven steps, sizes, render size 728 pixels, job column widths), `PreviewGrid`, `QueueSelection.normalized` (selection rules) and `keptAfterRefresh` (D44), `QueueReorder.gatheredMove`, `gridMove`, `rearranged`.
- `QueueStore.swift`: selection as a set with the rules applied in the setter; set-based cancel (one immediately, several via `PendingAction.cancel` after confirmation), pause (one cupsd re-check; jobs that started printing are reported), resume and gathered move through the existing `apply` with its re-check; list drag moves only movable jobs; the selection after a refresh follows D44; grid blocks (`TileState`, `gridJobs`, `loadTiles`), `canDragInGrid`, `moveInGrid`; `thumbnailStep` (not stored); thumbnails rendered at 728 pixels.
- `ContentView.swift`: list bound to the selection; thumbnail size buttons and shortcuts; toolbar, context menu and ⌫ act on the selection; confirmation dialog for several jobs; grid preview with note, blocks (title, page count, status, first page, warning, order number, drag and drop); subtitle "n jobs selected"; job column width following the step; `ColumnSplitSupport`: thick dividers through the public `dividerStyle`, a separate `DividerMarkView` on top of the divider before the preview (line and grip, lets clicks through, follows `didResizeSubviewsNotification`), and widening the window when the columns no longer fit; `ContentView(store:)` for checks.
- `JobRows.swift`: thumbnail size parameter; the status label never shrinks and the time stays on one line.
- `PDFPreview.swift`: `FirstPageView` for the blocks.
- `Localizable.xcstrings`: 14 new keys, all translated into Dutch and Turkish.
- Tools: `install-release.sh` (Release build to `~/Applications` or a given folder, quits a copy running from there); `test-printer.sh` (`create`, `remove`, `jobs [x]`, `printing`, `complete`, `sample`; test printer at `socket://127.0.0.1:59100`, stopped except while one job is kept printing; `complete` lets one job finish into a one-connection receiver that discards the data).

**Crash found by the user and fixed in the round.** The first divider implementation replaced the class of AppKit's split view to draw the divider. AppKit's toolbar observes that split view; when the toolbar changed (clicking a row), removing that observation raised an Objective-C exception and the app crashed (the user's crash report). Fixed by leaving the split view's class alone and drawing the line in a separate view; E06 reproduces the crash with the first implementation and passes now. Earlier off-screen checks had no SwiftUI toolbar and did not show it.

**Specs and documentation.** QUEUE-001 v4 (AC08–AC11), PREV-001 v5 (AC07–AC08), JOB-001 v3 (AC09–AC12), scenarios, validation plan (phase 01 row, practical checks 12–15, test printer as the preferred safe check), architecture, inventory (D38–D44, feature versions), README (thumbnails, several jobs, divider, install script, "Testing without wasting paper" with both methods and the script).

## Checks

| Check | Result |
| --- | --- |
| E01 pure logic | 61 checks PASS (D39 and JOB-001-AC12 examples, seven steps, D44 selection rule) |
| E02 thumbnails and blocks | PASS: 728-pixel thumbnails; one-page block document with the job's page count; partial job marked |
| E03 row rendering | Rows at steps 1–7 inspected; layout issues found and fixed (status label cut off, time wrapping; title gone at steps 6–7 in a fixed column, which led to the widening job column) |
| E04 store against cupsd | PASS with held and empty test jobs: selection rules, grid blocks, resume of two jobs, a selected job leaving the queue (D44), ⌫ with two jobs asks and cancels both; no priority of the user's jobs changed; 0 test jobs left |
| E05 window content off screen | 18 checks PASS: 9-point dividers; visible job column 300 → 480 points over steps 1–7; at a 900-point window the window widens to 1,029 points at step 7 instead of cutting off the preview |
| E06 rows with the app's toolbar | PASS: no crash (the first implementation crashed, exit 133); divider line and grip drawn in the middle of the divider; clicks on them reach the split view |
| E07 moves applied to cupsd | PASS with held test jobs while the queue held no other job: B D A C E, down, grid drag, list drag of two rows |
| Final re-run | E01, E02 (apart from PNG byte sizes), E03, E05 identical to their results files at 2026-11-16T20:11:37Z; E06 and E07 at 20:13:38Z |
| Debug and Release builds | Both succeed; 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line (2026-11-16T20:14:40Z) |
| String Catalog | 101 keys, 100 translatable, 0 missing, 0 stale |
| Scripts | `install-release.sh` built and installed into a temporary folder (also replacing an earlier copy); `test-printer.sh`: usage, `sample`, invalid counts, `jobs 2` on the user's test printer (removed again), helpers; `create`, `remove`, `printing` and `complete` need an administrator password and were only checked to fail cleanly without one |

No check printed on paper. Test jobs were held or empty and were removed, including from the completed-job history (details and incidents in the [evidence register](evidence/README.md)). A previous internal review, started before the user had finished the phase, was stopped on the user's instruction before it wrote a report.

## Open points

- Practical checks 12–15 in the validation plan (real window: toolbar buttons and shortcuts, window widening, multiple selection, grid and order numbers, dialogs, dragging in the list, in the grid and of the divider, the divider's appearance).
- `test-printer.sh printing` and `complete` have not run with an administrator password; two assumptions are to be confirmed by the user's first run (macOS keeps retrying the empty port, so the job stays printing; stopping the printer after `complete` returns a just-started job to waiting).
- Pausing several pending jobs is not run (a pending job with a document would print).
- After select-all (⌘A) the list showed 16 selected rows while the store kept the 15 queued jobs (seen off screen); the list may show a completed row as selected until the next update. Not fixed.
- Implementation defaults in the [plan](plan.md) remain open for the user.
