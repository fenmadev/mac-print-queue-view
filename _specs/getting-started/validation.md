# Phases and practical checks

## Phases

| Phase | Content | Status |
| --- | --- | --- |
| 00 | Record everything built before the review method was introduced: app, specs, decisions, evidence. | In review |

Later phases are defined by the user; requested functions are first recorded in the [roadmap](../../_docs/roadmap.md). Each phase has a plan, evidence, reviews and a closure in `_docs/phases/phase-NN/` in this project.

## How to check safely

- **Never print on paper in a check.** Create test jobs with a title starting with `MPQV ` and either hold them (`lp -H hold -t "MPQV test" -d <printer> file`) or create them without a document (IPP `Create-Job`, which stays `pending-held` with `job-incoming`).
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
