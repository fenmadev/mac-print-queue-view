---
id: QUEUE-001
title: Printers, queue and completed jobs
type: feature
status: draft
version: 3
---

# QUEUE-001 — Printers, queue and completed jobs

## Purpose

Show the user the printers set up on this Mac and, per printer, the existing macOS print queue with its jobs, so the user can select a job and see what is being printed (D1).

## Behaviour for the user

1. The window has three columns: printers, jobs of the selected printer, and the preview ([PREV-001](PREV-001-print-preview.md)).
2. The printer column lists the printers configured in macOS by their description (`printer-info`, or the queue name if empty), sorted alphabetically; each shows the number of the user's jobs in its queue, and its tooltip shows the queue name, with "(default printer)" for the default. At start the default printer is selected, or the first printer if there is no default; if the selected printer disappears, the same rule picks another.
3. The job column has two sections: **In Queue** (active jobs, in the order in which they will print) and **Completed** (the 50 finished jobs with the highest job numbers, highest first; the section is hidden when there are none). Each section header shows the number of jobs listed. Switching to another printer clears the job selection.
4. Queue rows show a thumbnail of the first page, the title, a coloured status label and the time; a job that is printing shows a small spinner (D14).
5. Completed rows are compact: a status icon (✓ completed, ✕ canceled, ! aborted), the title, the state and the date (D14). The tooltip of every row shows the title and the document format.
6. The lists update automatically when jobs appear, change state or disappear.

## Functional rules

1. Only the user's own jobs are requested and shown; other users' jobs are not listed (D6).
2. The queue shows jobs in the order in which macOS will print them: jobs that are not waiting (printing or stopped) first, then by priority (highest first), then by job number.
3. Thumbnails are shown only for jobs in the queue, never for completed jobs (D14).
4. Temporary printers (`printer-is-temporary`) are not listed.
5. The lists refresh about every 2 seconds (implementation default).
6. The "Completed" list is limited to 50 jobs per printer, ordered by job number, highest first (implementation default). This is not the completion time: a job that was held, reordered or restarted can finish later than a job with a higher number, and then appears below it.
7. When a selected job disappears from both lists, the selection and preview are cleared.

## User interface

Three-column window, minimum 900 × 560 points. Status labels: Pending (grey), Paused (orange), Printing (blue), Stopped (red); completed icons: green ✓, grey ✕, red !. Selected rows use white labels and icons. An empty queue shows a tray icon with "No jobs in the queue". Exact layout may change.

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

## Observed, yet to be confirmed

- The 2-second refresh interval and the limit of 50 completed jobs are implementation defaults.
- Sorting of jobs that are not waiting above other jobs is an implementation choice that mirrors cupsd.
- Printer naming, sorting and fallback selection, hiding an empty "Completed" section and clearing the job selection when switching printers are implementation defaults.

## Related specifications

[PREV-001](PREV-001-print-preview.md), [JOB-001](JOB-001-job-actions.md), [I18N-001](I18N-001-localization.md), [scenario overview](../scenarios.md).

## Technical references

IPP `CUPS-Get-Printers`, `cupsGetJobs2` with `my-jobs`, `CUPS-Get-Document` (for thumbnails); see [architecture](../architecture/index.md) and [ADR-001](../decisions/ADR-001-documents-through-cupsd.md), [ADR-003](../decisions/ADR-003-polling-refresh.md).

## Traceability

There is no automated test target yet; evidence comes from development-time checks recorded in the phase 00 evidence (items `E01`–`E26`).

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| QUEUE-001-AC01 | E03 (printers and default printer read through the app's CUPS layer) | Partial: list display not visually checked |
| QUEUE-001-AC02 | E03, E08 (active and finished jobs, print order matches cupsd) | Partial: visual check pending |
| QUEUE-001-AC03 | E10 (`my-jobs` query; all returned jobs owned by the user) | Partial: no second user on this Mac to prove exclusion |
| QUEUE-001-AC04 | E13, E15 (store refresh reflects cancellations and state changes) | Indirect: timing in the running app not measured |
| QUEUE-001-AC05 | E13 (thumbnails generated for queued jobs), E17 (rendered rows) | Partial: real window not checked |
| QUEUE-001-AC06 | — | None |
| QUEUE-001-AC07 | E26 (selection set to a non-existent printer: default selected, no error, completed jobs loaded) | Partial: simulated with a printer name that does not exist; a real deletion of a printer was not done |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | Ad hoc Swift harnesses compiled with the app sources (see evidence) | See evidence items | Executor (Claude), phase 00 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the behaviour built in phase 00 |
| 2 | 2026-11-16 | Review finding: the "Completed" order is by job number, not completion time (clarification of existing behaviour) |
| 3 | 2026-11-16 | Review finding: a disappearing selected printer is replaced without a false connection error (AC07, code fixed) |
