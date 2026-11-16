---
id: QUEUE-001
title: Printers, queue and completed jobs
type: feature
status: draft
version: 4
---

# QUEUE-001 — Printers, queue and completed jobs

## Purpose

Show the user the printers set up on this Mac and, per printer, the existing macOS print queue with its jobs, so the user can select a job and see what is being printed (D1).

## Behaviour for the user

1. The window has three columns: printers, jobs of the selected printer, and the preview ([PREV-001](PREV-001-print-preview.md)).
2. The printer column lists the printers configured in macOS by their description (`printer-info`, or the queue name if empty), sorted alphabetically; each shows the number of the user's jobs in its queue, and its tooltip shows the queue name, with "(default printer)" for the default. At start the default printer is selected, or the first printer if there is no default; if the selected printer disappears, the same rule picks another.
3. The job column has two sections: **In Queue** (active jobs, in the order in which they will print) and **Completed** (the 50 finished jobs with the highest job numbers, highest first; the section is hidden when there are none). Each section header shows the number of jobs listed. Switching to another printer clears the job selection.
4. Queue rows show a thumbnail of the first page, the title, a coloured status label and the time; a job that is printing shows a small spinner (D14). The thumbnails have seven sizes (D38, D42): **Smaller Thumbnails** and **Larger Thumbnails** in the toolbar of the job column, or ⌥⌘- and ⌥⌘=, step through them. Step 1 is 40 × 52 points; step *n* is *n* times that size (step 7 is 280 × 364 points). The sheet keeps its proportion, the row grows, and title, status and time stay beside the thumbnail; the job column widens with the thumbnails, and the window widens if the columns no longer fit. Every start begins at step 1.
5. Completed rows are compact: a status icon (✓ completed, ✕ canceled, ! aborted), the title, the state and the date (D14). The tooltip of every row shows the title and the document format.
6. The lists update automatically when jobs appear, change state or disappear.
7. Several jobs in "In Queue" can be selected together with ⌘-click, and a range with ⇧-click (D39). The actions on several jobs are in [JOB-001](JOB-001-job-actions.md), the preview of several jobs in [PREV-001](PREV-001-print-preview.md).

## Functional rules

1. Only the user's own jobs are requested and shown; other users' jobs are not listed (D6).
2. The queue shows jobs in the order in which macOS will print them: jobs that are not waiting (printing or stopped) first, then by priority (highest first), then by job number.
3. Thumbnails are shown only for jobs in the queue, never for completed jobs (D14).
4. Temporary printers (`printer-is-temporary`) are not listed.
5. The lists refresh about every 2 seconds (implementation default).
6. The "Completed" list is limited to 50 jobs per printer, ordered by job number, highest first (implementation default). This is not the completion time: a job that was held, reordered or restarted can finish later than a job with a higher number, and then appears below it.
7. When a selected job disappears from both lists, the selection and preview are cleared. A selected job that leaves the queue — printed, canceled or aborted — is deselected right away, so its preview disappears (D44); a completed job selected in "Completed" keeps its preview while it is listed.
8. Thumbnail size (D38, D42): seven steps; step 1 is the default and the smallest, step 7 the largest; "Smaller Thumbnails" is disabled at step 1 and "Larger Thumbnails" at step 7. The step is not stored. Only queue rows have thumbnails, so the completed rows do not change. The job column keeps at least the thumbnail width plus 200 points (240 points at step 1, 480 at step 7); when zooming in makes the columns wider than the window, the window widens by that amount, never beyond the screen, and it is not narrowed again when zooming out.
9. Selection (D39): several jobs can only be selected in "In Queue". A completed job is always selected on its own: clicking or ⌘-clicking it replaces a selection of queued jobs; ⌘-clicking a queued job while a completed job is selected selects only queued jobs; selecting everything (⌘A) keeps only the queued jobs. When several jobs are selected and some leave the queue (for example because they were canceled together), only those still in the queue stay selected.
10. Column dividers (D43): the dividers between the columns are 9 points wide, so they are easy to grab; the divider between the job list and the preview shows a line over the full height with a grip in the middle.

## User interface

Three-column window, minimum 900 × 560 points. The toolbar of the job column has the two thumbnail size buttons (arrows inward and outward). The divider before the preview is drawn in system colours (secondary label colour for the line, label colour for the grip), so it follows light and dark mode. Status labels: Pending (grey), Paused (orange), Printing (blue), Stopped (red); completed icons: green ✓, grey ✕, red !. Selected rows use white labels and icons. An empty queue shows a tray icon with "No jobs in the queue". Exact layout may change.

## Permissions

None beyond the App Sandbox printing entitlement ([APP-001](APP-001-app-identity-and-distribution.md)). No administrator password.

## Edge cases

- No printers configured: the printer column says "No Printers".
- The printing service cannot be reached: the printer column shows "No connection to the printing service" with the error.
- A job without a title is shown as "Job <number>".
- A thumbnail cannot be made (no document yet, unsupported format): a document icon is shown and the app retries after about 5 seconds while the job is in the queue.
- Times of today show only the time; older dates show date and time, in the app's language.

## Error handling

Connection errors are shown in the printer column and the app keeps retrying on the next refresh. Thumbnail failures are silent (placeholder icon).

## Acceptance criteria

### QUEUE-001-AC01

- **Given** printers are configured in macOS.
- **When** the app starts.
- **Then** it lists those printers (excluding temporary ones), selects the default printer and shows the number of the user's queued jobs per printer.

### QUEUE-001-AC02

- **Given** the user has jobs in the queue and finished jobs for the selected printer.
- **When** the user views the job column.
- **Then** "In Queue" lists the active jobs in print order and "Completed" lists at most the 50 finished jobs with the highest job numbers, highest first, each section with its count.

### QUEUE-001-AC03

- **Given** jobs of other users exist on this Mac.
- **When** the app requests the queue and the completed jobs.
- **Then** only the user's own jobs are requested and shown.

### QUEUE-001-AC04

- **Given** the app is open.
- **When** a job is added, changes state or disappears.
- **Then** the lists reflect that within about 2 seconds without user action.

### QUEUE-001-AC05

- **Given** a job is in the queue and its document can be rendered.
- **When** the queue is shown.
- **Then** the row shows a thumbnail of the first page; completed rows never show a thumbnail.

### QUEUE-001-AC06

- **Given** no printers are configured, or the printing service cannot be reached.
- **When** the app refreshes.
- **Then** the printer column says so instead of showing an empty list without explanation.

### QUEUE-001-AC07

- **Given** a printer is selected.
- **When** that printer disappears from macOS (for example it is deleted in System Settings).
- **Then** the app selects the default printer, or the first printer if there is no default, and shows its jobs without a connection error.

### QUEUE-001-AC08

- **Given** jobs with thumbnails in "In Queue".
- **When** the user chooses Larger Thumbnails or Smaller Thumbnails (toolbar, ⌥⌘= or ⌥⌘-).
- **Then** the thumbnails change by one step between step 1 (40 × 52 points, the size at start) and step 7 (280 × 364 points), step *n* being *n* times step 1; the button that would go beyond step 1 or 7 is disabled; title, status and time stay beside the thumbnail, the job column widening as needed and the window widening if the columns no longer fit, so the preview is not cut off; after a restart the size is step 1 again.

### QUEUE-001-AC09

- **Given** several jobs in "In Queue" and at least one completed job.
- **When** the user ⌘-clicks queued jobs, then ⌘-clicks a completed job.
- **Then** the queued jobs are selected together; clicking the completed job selects only that job; a completed job is never selected together with other jobs.

### QUEUE-001-AC10

- **Given** the main window with its three columns.
- **When** the user looks at and drags the divider between the job list and the preview.
- **Then** the divider is clearly visible (a line with a grip) and is 9 points wide, so it is easy to grab; dragging it resizes the columns.

### QUEUE-001-AC11

- **Given** a job in "In Queue" is selected and its preview is shown.
- **When** the job leaves the queue (it is printed, canceled or aborted).
- **Then** the job is deselected and the preview disappears at the next refresh (about 2 seconds), also when the job then appears under "Completed"; a completed job that the user selects in "Completed" keeps its preview.

## Observed, yet to be confirmed

- The 2-second refresh interval and the limit of 50 completed jobs are implementation defaults.
- Sorting of jobs that are not waiting above other jobs is an implementation choice that mirrors cupsd.
- Thumbnails are rendered at most 728 pixels on the longer side (step 7 at 2× scale); the job column keeps 200 points next to the thumbnail; with a large step in a narrow column the time gives way before the status label (implementation defaults, phase 01).
- The thick dividers and the visible line rely on AppKit's split view behind `NavigationSplitView`: its public `dividerStyle` is set to thick, and the line is a separate view on top of the divider that lets clicks through. The split view itself must not be altered otherwise (AppKit's toolbar observes it). A future macOS that builds the columns differently would fall back to the standard thin divider (technical assumption, phase 01).
- A ⇧-click range of completed jobs selects only the clicked job, the end of the range farthest from the previous selection (implementation default; several completed jobs cannot be selected together).
- Printer naming, sorting and fallback selection, hiding an empty "Completed" section and clearing the job selection when switching printers are implementation defaults.

## Related specifications

[PREV-001](PREV-001-print-preview.md), [JOB-001](JOB-001-job-actions.md), [I18N-001](I18N-001-localization.md), [scenario overview](../scenarios.md).

## Technical references

IPP `CUPS-Get-Printers`, `cupsGetJobs2` with `my-jobs`, `CUPS-Get-Document` (for thumbnails); see [architecture](../architecture/index.md) and [ADR-001](../decisions/ADR-001-documents-through-cupsd.md), [ADR-003](../decisions/ADR-003-polling-refresh.md).

## Traceability

There is no automated test target yet; evidence comes from development-time checks recorded in the phase 00 evidence (items `E01`–`E26`) and the phase 01 evidence (items `E01`–`E08`, cited as "phase 01 E…").

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| QUEUE-001-AC01 | E03 (printers and default printer read through the app's CUPS layer) | Partial: list display not visually checked |
| QUEUE-001-AC02 | E03, E08 (active and finished jobs, print order matches cupsd) | Partial: visual check pending |
| QUEUE-001-AC03 | E10 (`my-jobs` query; all returned jobs owned by the user) | Partial: no second user on this Mac to prove exclusion |
| QUEUE-001-AC04 | E13, E15 (store refresh reflects cancellations and state changes) | Indirect: timing in the running app not measured |
| QUEUE-001-AC05 | E13 (thumbnails generated for queued jobs), E17 (rendered rows) | Partial: real window not checked |
| QUEUE-001-AC06 | — | None |
| QUEUE-001-AC07 | E26 (selection set to a non-existent printer: default selected, no error, completed jobs loaded) | Partial: simulated with a printer name that does not exist; a real deletion of a printer was not done |
| QUEUE-001-AC08 | Phase 01 E01 (step sizes, limits, default step), E02 (thumbnails rendered at 728 pixels), E03 (rows rendered at all seven steps), E05 (the real window content off screen: job column width and window widening at every step) | Partial: buttons and shortcuts in the real window not exercised; rows rendered with `ImageRenderer`, not in the real list |
| QUEUE-001-AC09 | Phase 01 E01 (selection rules), E04 (selection rules in the store against the real queue), E08 (the list highlights exactly the selection the rules keep, for ⌘A and ⇧-click ranges; the round-1 code failed this) | Partial: ⌘-click and ⇧-click in the real list not exercised; whether a real ⇧-click can highlight a section header is not known (only a programmatic selection did) |
| QUEUE-001-AC10 | Phase 01 E05 (9-point dividers, also after a resize), E06 (line and grip drawn in the middle of the divider; clicks on them reach the split view; clicking rows with the app's toolbar does not crash) | Partial: appearance in the real window and an actual drag not checked (a drag cannot be simulated off screen) |
| QUEUE-001-AC11 | Phase 01 E01 (selection after a refresh: printed, canceled, removed, printed again, several), E04 (a selected test job that left the queue: selection empty, preview gone) | Partial: a job that is really printed was not used (paper); the real window not checked |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | Ad hoc Swift harnesses compiled with the app sources (see evidence) | See evidence items | Executor (Claude), phase 00 |
| 2026-11-16 | Phase 01 harnesses E01–E06 (see phase 01 evidence) | All checks passed | Executor (Claude), phase 01 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the behaviour built in phase 00 |
| 2 | 2026-11-16 | Review finding: the "Completed" order is by job number, not completion time (clarification of existing behaviour) |
| 3 | 2026-11-16 | Review finding: a disappearing selected printer is replaced without a false connection error (AC07, code fixed) |
| 4 | 2026-11-16 | Phase 01: thumbnail sizes (D38, D42, AC08), selecting several queued jobs (D39, AC09), the column dividers (D43, AC10) and deselecting a job that leaves the queue (D44, AC11); internal review 02: the list follows the corrected selection, ⇧-range of completed jobs keeps the clicked job |
