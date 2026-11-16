# Phase 01 — draft

Date (UTC): 2026-11-16T18:03:51Z (created 2026-11-16T14:04:45Z)
Status: draft; not started. RM-001 waits for the open questions below.

## Requests recorded so far

1. **RM-001 — Thumbnail zoom in the queue** ([roadmap](../../roadmap.md); user, 2026-11-16): the "In Queue" list gets zoom in / zoom out controls that set the size of the page thumbnails, in 5 steps. Each step is a multiple of the height of step 1: step 2 is 2× the height of step 1, …, step 5 is 5× the height of step 1.


## Open questions for the user (to settle before building)

- Is step 1 the current thumbnail size (52 points high), or smaller?
- Should the row grow with the thumbnail (title and status next to a larger thumbnail), and should the width follow the page's aspect ratio?
- Where are the controls (toolbar of the job column, keyboard shortcuts)? The preview already uses ⌘= / ⌘- / ⌘0.
- Should the chosen step be remembered after restarting the app?
- Does the zoom apply only to the queue (thumbnails), as requested, and not to the "Completed" list?
