# Phases and practical checks

## Phases

| Phase | Content | Status |
| --- | --- | --- |
| 00 | Record everything built before the review method was introduced: app, specs, decisions, evidence. | Closed |
| 01 | Thumbnail sizes in the queue (RM-001), selecting several queued jobs with actions and a grid preview (RM-003), reordering in the grid (RM-004), visible column divider (RM-005), release install script (RM-006), deselecting a job that leaves the queue (RM-007), test printer script (RM-008). | In progress |

Later phases are defined by the user; requested functions are first recorded in the [roadmap](../../_docs/roadmap.md). Each phase has a plan, evidence, reviews and a closure in `_docs/phases/phase-NN/` in this project.

## How to check safely

- **Never print on paper in a check.** Prefer a stopped test printer whose address leads nowhere (see the README section "Testing without wasting paper"; setting it up changes the printer configuration and needs the user's consent). Otherwise create test jobs with a title starting with `MPQV ` and either hold them (`lp -H hold -t "MPQV test" -d <printer> file`) or create them without a document (IPP `Create-Job`, which stays `pending-held` with `job-incoming`).
- Do not touch the user's real jobs. Remove test jobs afterwards: cancel them (`cancel <printer>-<id>`) and purge them from the completed history.
- Verify job lists by job number, not by title: `lpstat -o` does not show titles.
- Build: `xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath <path> build`.
- Translations: after building, run `Tools/sync-strings.sh <path>` with the same derived data path and check that no key lacks a Dutch or Turkish translation.

## Practical checks that need the user

These cannot be done by the executor (no screen recording or accessibility access, or they would print on paper):

1. Visual check of the window in light and dark mode: printer list, queue rows with thumbnails, completed rows, hover icons, swipe actions, toolbar stability when switching jobs.
2. Preview of a real multi-page job: paging and zooming; the warning banner of a partial preview.
3. Pause a real pending job while another job prints; resume it.
4. Try to pause a job that is printing (the button must be disabled or a message shown).
5. Drag a job in the queue; cancel a printing job.
6. Print a completed job again (uses paper).
7. Language: switch to Nederlands and Türkçe in Settings, use "Restart Now", and check the texts; a native speaker check of the Turkish text.
8. Remove one completed job and use "Clear…" in the window (confirmation dialogs; "Clear…" removes all completed jobs of that printer).
9. The printer column without printers and with the printing service unreachable (QUEUE-001-AC06); deleting the selected printer while the app is open (QUEUE-001-AC07).
10. Behaviour with another user's jobs on the Mac (they must not appear).
11. App Store: archive, upload and submit (not yet attempted).
12. Phase 01, thumbnails (QUEUE-001-AC08): Larger/Smaller Thumbnails in the toolbar of the job column and ⌥⌘= / ⌥⌘- through all seven steps; disabled at the ends; the preview's own zoom (⌘= / ⌘- / ⌘0) is not affected; the job column and, if needed, the window widen at the large steps and the preview is not cut off; step 1 again after a restart.
13. Phase 01, several jobs (QUEUE-001-AC09, PREV-001-AC07–AC08): ⌘-click and ⇧-click in "In Queue", a completed job ⌘-clicked, ⌘A, a ⇧-click range from the queue into "Completed" (no completed row and no section header may stay highlighted), a ⇧-click range within "Completed" (only the clicked job stays selected); a selected job that leaves the queue (printed, canceled or aborted) is deselected and its preview disappears (QUEUE-001-AC11); the grid for 2, 3–4, 5–9, 10–16 and more than 16 jobs, with order numbers; light and dark mode.
14. Phase 01, actions on several jobs (JOB-001-AC09–AC12): Cancel Jobs… with both dialog buttons; Print Earlier / Later on a non-contiguous selection (A B C D E, B and D → B D A C E); dragging several rows; dragging a block in the grid (the queue follows right away); Pause and Resume of several jobs. Moving changes the priorities of all waiting jobs of the printer, so do this only with jobs that may be reordered.
15. Phase 01, column divider (QUEUE-001-AC10): the divider between the job list and the preview is clearly visible (line and grip) in light and dark mode and easy to grab and drag; the divider at the printer column is also wider; the line stays on the divider when the printer column is hidden or shown, in full screen and after moving the window between screens.
16. Phase 01, test printer (RM-008): `Tools/test-printer.sh create`, `jobs`, then `printing` (one job shows as printing in the app, the others wait) and `complete` (that job moves to "Completed" as completed, the others still wait, the printer is stopped); finally `remove`. Nothing may come out of any printer.
17. Phase 01, install script (RM-006): `Tools/install-release.sh` into `~/Applications`, also while the installed copy is running (it is quit first), and the installed app starts.
