---
id: JOB-001
title: Cancel, pause, reorder, print again and remove jobs
type: feature
status: draft
version: 4
---

# JOB-001 — Cancel, pause, reorder, print again and remove jobs

## Purpose

Let the user manage their own print jobs from the same window in which they see what is being printed (D2–D5, D15–D18), also several queued jobs at once (D39, D40).

## Behaviour for the user

**Jobs in the queue**

1. **Cancel Job** (✕ toolbar button, ✕ row icon on hover/selection, context menu, or ⌫): the job is canceled immediately, without confirmation, also while printing. It then appears under "Completed" as "Canceled" (D2, D18).
2. **Pause** (⏸ toolbar button, row icon, context menu): a waiting job is held; it stays in the queue as "Paused" and the jobs behind it keep printing. **Resume** (▶) puts it back in its place (D17).
3. **Reorder**: drag a waiting job to another position, or use **Print Earlier / Print Later** (toolbar arrows, ⌥⌘↑/⌥⌘↓, context menu) (D4, D15).

**Completed jobs**

4. **Print Again** (↻): puts the job back in the queue, where it is printed again. From the row icon or a trackpad swipe to the right, the app asks for confirmation first; from the toolbar or context menu it acts immediately (D3, D16).
5. **Remove from List…** (🗑 toolbar button, row icon, context menu, swipe to the left, or ⌫): permanently removes the job and its retained document, after confirmation (D5).
6. **Clear…** next to the "Completed" header: removes all of the user's completed jobs for that printer, including older ones not shown in the list, after confirmation (D5).

**Several jobs in the queue** (selected with ⌘-click or ⇧-click, [QUEUE-001](QUEUE-001-queue-overview.md), D39)

7. The toolbar, the context menu and ⌫ act on all selected jobs; the ✕ and ⏸/▶ icons in a row act on that row only.
8. **Cancel Jobs…** (✕ toolbar button, context menu, or ⌫): asks "Cancel n Jobs?" ("Cancel Jobs" / "Don’t Cancel") and then cancels all of them; they appear under "Completed" as "Canceled". With one job selected, Cancel Job acts immediately as before (D18).
9. **Pause** pauses every selected job that is waiting; **Resume** resumes every selected paused job. With a mix of waiting and paused jobs, the toolbar shows Pause and the context menu offers both.
10. **Print Earlier / Print Later** (toolbar arrows, ⌥⌘↑/⌥⌘↓, context menu): the selected jobs are first gathered into one block and the block then moves one place. Moving up, the block is gathered at the first selected job; moving down, at the last selected job. Example: queue A B C D E with B and D selected; Print Earlier → B D A C E (D39). **Dragging** the selected rows puts them together, in their current order, at the drop position.
11. **Reorder in the preview grid** (D40): with several jobs selected, drag one block of the grid onto another block. The dragged job takes that block's place in the grid and the blocks in between shift one place; in the queue, the selected jobs keep the places they occupy together and are put on those places in the new grid order, while all other jobs stay where they are. Example: queue A B C D E with B, D, E selected (grid B D E); drag E onto B → grid E B D, queue A E C B D. A following block move (rule 10) keeps the order arranged in the grid.

## Functional rules

1. All actions apply only to the user's own jobs (D6). No action needs an administrator password.
2. A job that is printing cannot be paused. Right before pausing, the app re-checks the job's state with macOS; if it has started printing, nothing is paused and the user is told that it can be canceled instead (D17).
3. Only pending or paused jobs can be reordered; a job that is printing stays where it is. Right before applying a new order, the app re-checks with macOS; if a moved job is no longer waiting (for example it started printing while being dragged), nothing is moved (D15).
4. Reordering changes job priorities (1–100) so that cupsd prints in the requested order; priorities stay as close to the default 50 as possible, so new jobs still go to the end.
5. Cancel acts immediately; permanent removal and "Clear…" always ask for confirmation.
6. "Print Again" is only possible while macOS retains the job's document.
7. The toolbar shows the buttons that apply to the selected job or jobs: reorder, pause/resume and cancel for a queued job; print again and remove for a completed job. With no job selected, only a disabled "Remove from List…" button is shown; right-clicking an empty area of the list shows the queue context menu with all items disabled.
8. Permanent removal re-checks each job's state with macOS right before removing it; only jobs that are still completed, canceled or aborted are removed. A job that is back in the queue (for example restarted while the confirmation was open, or during "Clear…") is left alone and the user is told so in a notice titled "Not Removed"; during "Clear…" a job that has disappeared is skipped and the remaining jobs are still handled. The check and the removal are two separate requests; a state change in the milliseconds between them cannot be excluded.
9. Several jobs (D39): only the user's own queued jobs are acted on. Canceling one of them is immediate; canceling several always asks first ("Cancel Jobs…"); when only one of the selected jobs is the user's own, it is canceled right away and the button says "Cancel Job". Pausing several pauses them one after another and re-checks each job's state with macOS right before pausing that job: jobs that started printing meanwhile, also while earlier jobs were being paused, are not paused, and the user is told how many ("Jobs that had already started printing and were not paused: n"); the others are paused, also when pausing one of them fails or the state of one cannot be read (that job is not paused; the first error is shown); resuming several also continues after a failure. As for removal (rule 8), the check and the pausing of one job are separate requests; a job that starts printing in the moment between them cannot be excluded.
10. Moving several jobs with the arrows or by dragging moves only the jobs that are waiting; selected jobs that are printing stay where they are. The arrow is disabled when the move would not change the order. The re-check of rule 3 applies to every job that moves.
11. Dragging in the preview grid (D40) works only between blocks of waiting jobs; a block of a job that is printing cannot be dragged or be a drop target. The new order is applied right away, with the re-check of rule 3.
12. All reordering uses the priorities of rule 4. Priorities are capped at 100; when many jobs are moved above many others, the order may not be fully reachable, and the list then shows the actual order (technical limit, [ADR-002](../decisions/ADR-002-reorder-by-priority.md)).

## User interface

Toolbar buttons, context menu items, row icons shown on hover or selection, trackpad swipe actions on completed rows, drag and drop in the list and in the preview grid, and confirmation dialogs as described above. Exact layout may change.

## Permissions

None beyond the App Sandbox printing entitlement; cupsd allows these operations for the job owner without a password.

## Edge cases

- The job finishes between the click and the action: cancel/pause report a CUPS error or do nothing; the list refreshes.
- "Print Again" for a job whose document has been removed: an error message.
- Removing the selected completed job clears the selection and preview.
- Dragging in the grid arranges only the blocks of jobs that can move. When a waiting job of another user lies, in the grid, between the dragged block and the target (only possible if such jobs were listed), the other blocks shift around it rather than strictly "one place". Other users' jobs are not listed (D6), so this does not occur in practice.

## Error handling

Failed actions show an "Action Failed" alert with a translated explanation and the technical CUPS detail; the list then refreshes.

## Acceptance criteria

### JOB-001-AC01

- **Given** the user's own job in the queue (waiting or printing).
- **When** the user chooses Cancel Job (button, row icon, context menu or ⌫).
- **Then** the job is canceled immediately without confirmation and appears under "Completed" as "Canceled".

### JOB-001-AC02

- **Given** the user's own pending job.
- **When** the user chooses Pause.
- **Then** the job is held and shown as "Paused" while other jobs keep printing; Resume returns it to waiting.

### JOB-001-AC03

- **Given** a job that is printing, or that started printing just before the click.
- **When** the user tries to pause it.
- **Then** the job is not paused; the control is disabled, or the app re-checks with macOS and shows a message.

### JOB-001-AC04

- **Given** several of the user's own waiting jobs.
- **When** the user drags a job to another position or uses Print Earlier/Later.
- **Then** macOS prints the jobs in the new order.

### JOB-001-AC05

- **Given** a waiting job is being dragged.
- **When** it has started printing (or is no longer waiting) at the moment it is dropped.
- **Then** nothing is moved and no error is shown; the list shows the actual queue.

### JOB-001-AC06

- **Given** the user's own completed job whose document is retained.
- **When** the user chooses Print Again from a row icon or swipe and confirms.
- **Then** the job is put back in the queue; from the toolbar or context menu it is put back without confirmation.

### JOB-001-AC07

- **Given** the user's own completed jobs.
- **When** the user removes one job or chooses Clear… and confirms.
- **Then** those jobs and their retained documents are removed permanently; other users' jobs and jobs in the queue are untouched.

### JOB-001-AC08

- **Given** a removal was confirmed for a job that has meanwhile returned to the queue (or a job returns to the queue during "Clear…").
- **When** the removal is carried out.
- **Then** that job is not removed and the user is told that it is no longer completed.

### JOB-001-AC09

- **Given** two or more of the user's own jobs in the queue are selected.
- **When** the user chooses Cancel Jobs… (toolbar, context menu or ⌫).
- **Then** the app asks for confirmation; after "Cancel Jobs" all selected jobs are canceled and appear under "Completed"; after "Don’t Cancel" nothing changes. With one job selected, it is canceled immediately (AC01).

### JOB-001-AC10

- **Given** the user's own waiting jobs A B C D E with B and D selected.
- **When** the user chooses Print Earlier once.
- **Then** macOS prints in the order B D A C E; moving down gathers the selection at the last selected job and moves it one place down; dragging the selected rows puts them together at the drop position.

### JOB-001-AC11

- **Given** several selected jobs in the queue, some waiting and some paused.
- **When** the user chooses Pause or Resume.
- **Then** Pause pauses every selected waiting job (except jobs that started printing meanwhile, which are reported) and Resume resumes every selected paused job.

### JOB-001-AC12

- **Given** the user's own waiting jobs A B C D E with B, D and E selected, so the preview grid shows B D E.
- **When** the user drags block E onto block B.
- **Then** the grid shows E B D with order numbers 1 2 3 and macOS prints in the order A E C B D.

## Observed, yet to be confirmed

- Toolbar/context-menu "Print Again" without confirmation (implementation default).
- Removing a completed job and "Clear…" asking for confirmation, and a printing job not being reorderable, are implementation defaults.
- Reordering by changing job priorities, with 50 as the baseline (technical choice, [ADR-002](../decisions/ADR-002-reorder-by-priority.md)).
- Phase 01 implementation defaults: moving several jobs down gathers them at the last selected job (mirror of D39's example); a drag in the preview grid is applied to the queue right away (confirmed by the user, D40); with mixed waiting and paused jobs the toolbar shows Pause; a dragged selection that includes a printing job moves the other jobs.

## Related specifications

[QUEUE-001](QUEUE-001-queue-overview.md), [scenario overview](../scenarios.md).

## Technical references

IPP `Cancel-Job` (with `purge-job` for removal), `Hold-Job` (`job-hold-until=indefinite`), `Release-Job`, `Restart-Job`, `Set-Job-Attributes` (`job-priority`); see [phase 00 CUPS research](../research/phase-00-cups.md) and [ADR-002](../decisions/ADR-002-reorder-by-priority.md).

## Traceability

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| JOB-001-AC01 | E06 (Cancel-Job in the sandbox), E15 (immediate cancel and ⌫ through the store) | Partial: a printing job was not canceled in a check (paper) |
| JOB-001-AC02 | E14, E20 (Hold-Job and Release-Job accepted, also in the sandbox; a held job is shown as "Paused") | Indirect: pausing a real pending job and resuming a job with a document were not tested (would print) |
| JOB-001-AC03 | — | None: the printing case cannot be produced without paper; re-check reviewed in code only |
| JOB-001-AC04 | E08 (arrow/drag order through the store matches cupsd) | Partial: dragging in the real window not checked |
| JOB-001-AC05 | E13 (drop after the job stopped waiting: no move, no error) | Partial: simulated with a canceled job, not a printing one |
| JOB-001-AC06 | E07 (Restart-Job behaviour) | None: a real reprint was not run (paper); confirmation dialog not visually checked |
| JOB-001-AC07 | E09 (purge of own test jobs only), E23 (state re-check before purge, in the sandbox) | Partial: "Clear…" for all jobs deliberately not run on real history |
| JOB-001-AC08 | E23 (stale confirmation for an active held job: not removed, message shown; a canceled job removed) | Partial: "Clear…" path covered by the same per-job check in code, not run on real history |
| JOB-001-AC09 | Phase 01 E04 (⌫ with two held test jobs asks for confirmation; confirming cancels both; selection cleared) | Partial: dialog not visually checked; "Don’t Cancel" reviewed in code only |
| JOB-001-AC10 | Phase 01 E01 (gathered move, D39 example, down mirror, edges), E04 (move availability against the real queue), E07 (applied to cupsd with held test jobs: B D A C E, down, list drag of two rows) | Partial: the arrow buttons, shortcuts and dragging in the real window not exercised |
| JOB-001-AC11 | Phase 01 E04 (resume of two empty test jobs at once), E01 (pausing several with a fake client: a job that starts printing while an earlier one is paused is never paused, also after a failure; negative control for a single snapshot) | Partial: pausing several pending jobs against cupsd not run (pending jobs with a document would print) |
| JOB-001-AC12 | Phase 01 E01 (grid move and rearranged queue order, including the AC12 example), E07 (grid drag applied to cupsd with held test jobs) | Partial: no drag in the real window |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | Ad hoc Swift harnesses with held or empty test jobs (see evidence) | See evidence items | Executor (Claude), phase 00 |
| 2026-11-16 | Phase 01 harnesses E01, E04 and E07 (held and empty test jobs, removed afterwards) | All checks passed | Executor (Claude), phase 01 |
| 2026-11-16 | Phase 01 round 4: E01 with the fake client for pausing several jobs (no CUPS call) | All checks passed | Executor (Claude), phase 01 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the behaviour built in phase 00 |
| 2 | 2026-11-16 | Review finding: removal re-checks the job state right before purging (rule 8, AC08) |
| 3 | 2026-11-16 | Phase 01: actions on several selected jobs (D39, AC09–AC11) and reordering in the preview grid (D40, AC12); internal review 02: cancel label and pause behaviour for several jobs clarified (rule 9) |
| 4 | 2026-11-16 | Phase 01, external review 07 (R4): pausing several re-checks each job right before pausing it (rule 9) |
