# Phase 01 — thumbnail zoom, multiple selection, grid preview and column dividers

Date (UTC): 2026-11-16T22:12:36Z (created 2026-11-16T14:04:45Z)
Status: **closed** — [external review 12](12-external-gpt-6.1-sol.md) APPROVED after [internal review 11](11-internal-claude-Opus-5.5.md) APPROVED round 5 (round 4 resolved R1–R4 of [external review 07](07-external-gpt-6.1-sol.md); internal review 09 approved it). An external gate report numbered 09 (BLOCKED) was withdrawn and removed by its author as erroneous; report 12 is the authoritative correction, and the references to it in internal review 11 are historical. Left open: optional O1–O2 of internal review 06 and of internal review 11, the practical checks 12–17 of the validation plan, and the implementation defaults below for the user. (An internal review started earlier in round 1, on an intermediate state, was stopped on the user's instruction before it wrote a report.)
Baseline: git commit `55933af` (phase 00). At closure all phase changes are staged (2026-11-16T22:12:36Z, after report 12); commit on the user's instruction.

## Requests

1. **RM-001 — Thumbnail zoom in the queue** ([roadmap](../../roadmap.md); user, 2026-11-16): zoom in / zoom out controls set the size of the page thumbnails in the "In Queue" list in steps (first 5, extended to 7 by **D42**); step *n* is *n* × the height of step 1. Open questions settled by the user in **D38** ([inventory](../../../_specs/inventory.md)).
2. **RM-003 — Multiple selection in the queue** (user, 2026-11-16): select several queued jobs with ⌘ held down and move, pause or cancel them at once; the preview shows the selected jobs in a grid. Settled by the user in **D39**.
3. **RM-004 — Reorder in the preview grid** (user, 2026-11-16): drag one block of the grid at a time to change the order; then move the rows, and the selection moves as one block in the order arranged in the grid. Settled by the user in **D40**; order numbers in the blocks in **D41**.
4. **RM-005 — Visible, thicker column divider** (user, 2026-11-16): the divider between the job list and the preview is thicker, easy to grab and clearly visible (**D43**).
5. RM-001 extended to **seven** thumbnail steps (user, 2026-11-16, **D42**).
6. **RM-006 — Install script** (user, 2026-11-16; first a `.command` file, renamed to `.sh` on the user's request): `Tools/install-release.sh` builds the Release version and copies it to `~/Applications` (created if needed; optional other destination), quitting a copy that runs from there; build output in a temporary folder outside the project.
7. **RM-007 — Preview disappears when its job leaves the queue** (user, 2026-11-16): printed, canceled or aborted (**D44**).
8. **RM-008 — Test printer script** (user, 2026-11-16): `Tools/test-printer.sh` with `create`, `remove`, `jobs [x]` (default 5; random text starting with the current date and time), `printing` (next waiting job to "printing"), `complete` (printing job to "completed") and `sample`; the README section "Testing without wasting paper" describes it and the held-job alternative.

## Scope

### RM-001 (D38, D42)

- Step 1 = the current thumbnail (40 × 52 points) and the default at every start; step *n* = *n* × that size, seven steps (step 7 = 280 × 364 points). Not remembered after a restart.
- The job column keeps the thumbnail width plus 200 points and widens when zooming in; if the columns no longer fit, the window widens (within the screen).
- The sheet keeps its proportion; the row grows; title, status and time stay beside the thumbnail.
- Two toolbar buttons in the job column ("Smaller Thumbnails", "Larger Thumbnails") with ⌥⌘- and ⌥⌘=; disabled at step 1 and step 7 respectively. They change only the thumbnails; the preview keeps its own zoom and always fills its column. They do not collide with ⌘- / ⌘= / ⌘0 of the preview or ⌥⌘↑ / ⌥⌘↓ of reordering.
- Only "In Queue" rows (completed rows have no thumbnail, D14).

### RM-003 (D39)

- ⌘-click (and the standard ⇧-click range) selects several jobs in "In Queue". A completed job is always selected alone: clicking it replaces a queue selection; adding queue jobs to a selected completed job drops the completed job; select-all keeps only queued jobs.
- Preview: one selected job → unchanged single preview with page and zoom controls. Two or more → a grid of equal blocks: 2 → 2 side by side, 3–4 → 2 × 2, 5–9 → 3 × 3, 10–16 → 4 × 4; more than 16 → the first 16 in queue order plus a note with the number not shown. Each block shows the job title, the page count and only the first page; a block whose job cannot be shown says so; a partial job is marked with a warning symbol. The page and zoom controls are not shown with a grid.
- Actions on all selected jobs (toolbar, context menu, ⌫):
  - **Move** (⌥⌘↑ / ⌥⌘↓, Print Earlier / Later): the selected waiting jobs are first gathered into one block at the first selected job (moving up) and the block then moves one place: A B C D E with B, D selected → B D A C E. Moving down mirrors this (gathered at the last selected job). Dragging puts the selected jobs together at the drop position (existing list behaviour). Jobs that are printing do not move. The current state is re-checked with cupsd before the priorities change (as for one job, D15).
  - **Pause / Resume**: pauses every selected job that is waiting, resumes every selected paused job; each is re-checked with cupsd right before pausing; jobs that started printing meanwhile are not paused and the user is told how many (D17).
  - **Cancel**: one job → immediately (D18); several → confirmation first, then all are canceled.
- The hover buttons in a row keep acting on that row only.

### RM-004 (D40, D41)

- With several jobs selected, a block of the grid can be dragged onto another block (one block at a time); the dragged job takes that place in the grid. The selected jobs keep the places they occupy together in the queue and are put on those places in the new grid order; other jobs stay where they are. The change is applied to the queue right away (confirmed by the user); a following block move (RM-003) keeps the arranged order.
- Blocks of jobs that are printing cannot be dragged or be a drop target.
- Every block shows its order number at the bottom right, left to right and then the next row (D41).

### RM-005 (D43)

- Column dividers 9 points wide instead of 1 (all dividers of the window, as AppKit applies one style); the divider before the preview shows a line over the full height and a grip in the middle, in system colours, drawn by a separate view on top that lets clicks through.
- Crash found by the user (2026-11-16, app crashed when a row was clicked): the first implementation replaced the class of AppKit's split view, which AppKit's toolbar observes; fixed by leaving the split view's class alone. Regression check E06 (crashes with the first implementation, passes now).

### RM-007 (D44)

- After every refresh, a selected job that was in the queue and has left it is removed from the selection; a completed job selected in "Completed" stays. Pure rule `QueueSelection.keptAfterRefresh`.

### RM-008

- The printer `MPQV_Testprinter` uses the address `socket://127.0.0.1:59100` (a port on this Mac where normally nothing listens; first `ipp://127.0.0.1:9/ipp/print`, switched automatically) and the generic macOS printer description, and accepts jobs. It is stopped, except while `printing` keeps one job printing: the printer is started, macOS takes the next waiting job and keeps retrying the empty port. `complete` runs a one-connection receiver (`nc`) that discards the data, waits until the job is completed and stops the printer again. The script refuses when the printer has another address or another program listens on the port. `remove` first checks, read only, that the printer has the test address or the earlier test address (both lead nowhere: an empty port on this Mac, and the discard port 9); any other address, or one that cannot be read, is refused without an administrator command (external review 07, R1). Whether the printer accepts jobs is read exactly ("accepting" versus "not accepting"); a printer that does not accept jobs is made to accept them and checked again; an unreadable state is refused (R2). Checked in isolation with stub commands (E09).
- Assumptions to confirm with the user's first run (they need an administrator password, which the executor does not have): macOS keeps retrying the empty port so the job stays "printing", and stopping the printer after `complete` returns a job that has just started to "waiting". Creating and removing need an administrator password; the executor did not create or remove the printer (the user had created it by hand). Tested: usage, `sample`, invalid counts, `jobs 2` on the user's test printer (2 jobs submitted and removed again, the user's 5 test jobs there untouched; the user removed the test printer later), `remove`, `printing` and `complete` failing without a password and changing nothing; the job-state, printing-job and port helpers; a one-connection `nc` receiver on port 59100 (accepts one connection, then refuses).

### RM-006

- Tested with a temporary destination folder (twice, the second run replacing the first copy); the user runs it for `~/Applications`. Documented in the README.
- A running copy is found by comparing the executable path of each running program with the destination as plain text (not a regular expression), so a folder with a similar name never matches; when the list of running programs cannot be read, the script stops before replacing anything (external review 07, R3). Several copies are quit together (the earlier version passed their process numbers as one argument). Checked with dummy programs in temporary folders (E09). Known limit (internal review 09, O2): the path compared is the one the copy was started with; a copy started from Terminal through a symbolic link to the destination is not recognised (README).

### Out of scope

App Store work (RM-002), multiple selection of completed jobs, remembering the zoom step, automated test target.

## Implementation defaults (not user decisions; to be confirmed)

- Moving a non-contiguous selection **down** gathers the selected jobs at the last selected job (mirror of D39's example for "up").
- Thumbnails are rendered at most 728 pixels on the longer side (step 7 at 2× Retina scale), instead of 160.
- 200 points of room for title, status and time next to the thumbnail; the window is widened when needed but not narrowed again.
- Toolbar symbols for thumbnail size: arrows inward / outward, distinct from the preview's magnifier symbols.
- With a mixed selection of waiting and paused jobs, the toolbar shows "Pause" (for the waiting ones); the context menu offers both Pause and Resume.
- A grid block cannot be clicked to open the job; select the job alone in the list for the full preview.
- A ⇧-click range of completed jobs selects only the clicked job (the end of the range farthest from the previous selection).
- With a large thumbnail in a narrow column the time gives way before the status label.
- Settled after trying the app (2026-11-16): the thumbnail buttons stay in the toolbar of the job column; a drag in the grid changes the queue right away.

## Acceptance checks for this phase

- QUEUE-001, PREV-001 and JOB-001 are extended (new criteria for zoom steps, multiple selection, grid preview, order numbers, actions on several jobs and reordering in the grid).
- Pure logic (zoom sizes, grid layout, gathered move) checked with a harness compiled from the app source, including D39's example.
- Moves are not applied to cupsd while the user's own jobs are in the queue (they would be re-prioritized); the move logic is checked in the harness, and applied to cupsd with held test jobs only when the queue held no other job (E07).
- Actions on several jobs checked with held test jobs only (`lp -H hold`, titled `MPQV …`), removed afterwards including from the completed-job history; nothing printed; the user's real jobs untouched.
- Rows rendered with `ImageRenderer` at all zoom steps (visual inspection by the executor); the real window content built off screen for the column widths, the divider and the row clicks with the toolbar (E05, E06); the real window remains a practical check.
- Debug and Release builds with zero errors and zero compiler warnings; all new strings translated into Dutch and Turkish.
- Internal review `APPROVED`, then external review `APPROVED`.

## Rounds

| Round | Report | Status |
| --- | --- | --- |
| 1 | [01 executor](01-executor-claude-Opus-5.5.md), [02 internal](02-internal-claude-Opus-5.5.md) | CHANGES REQUESTED (S1, S2 should fix; M1–M6 minor; O1–O4 optional) |
| 2 | [03 executor](03-executor-claude-Opus-5.5.md), [04 internal](04-internal-claude-Opus-5.5.md) | APPROVED (N1, N2 minor; N3 optional) |
| 3 | [05 executor](05-executor-claude-Opus-5.5.md), [06 internal](06-internal-claude-Opus-5.5.md) | APPROVED (O1, O2 optional, left open) |
| — | [07 external](07-external-gpt-6.1-sol.md) | CHANGES REQUESTED (R1–R4 should fix) |
| 4 | [08 executor](08-executor-claude-Opus-5.5.md), [09 internal](09-internal-claude-Opus-5.5.md) | APPROVED (M1 minor; O1, O2 optional) |
| — | 09 external (withdrawn) | Gate report written in error and removed by its author; see [external review 12](12-external-gpt-6.1-sol.md) |
| 5 | [10 executor](10-executor-claude-Opus-5.5.md), [11 internal](11-internal-claude-Opus-5.5.md) | APPROVED (M1 record-keeping, done; O1, O2 optional, left open) |
| — | [12 external](12-external-gpt-6.1-sol.md) | APPROVED — phase closed |

## Open questions

None blocking. The implementation defaults above may be confirmed or changed by the user.
