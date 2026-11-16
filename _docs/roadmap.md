# Roadmap

Date (UTC): 2026-11-16T18:02:36Z

All functions the user has asked for, planned or delivered. A new request is added here first, with the next free `RM` number. When it is built, it gets a phase plan in `phases/phase-NN/`, and the row links to that plan and, once delivered, to the spec.

Status values: **requested** (recorded, not yet in a phase) → **planned** (assigned to a phase) → **in progress** → **delivered** (with phase and spec) or **dropped** (with reason).

## Planned and requested

| ID | Function | Requested | Status | Phase | Spec |
| --- | --- | --- | --- | --- | --- |
| RM-001 | Thumbnail zoom in the queue: zoom in / zoom out controls set the size of the page thumbnails in 5 steps; step *n* is *n* × the height of step 1. Open questions in the phase plan. | 2026-11-16, user | planned | [phase 01 (draft)](phases/phase-01/plan.md) | QUEUE-001 (to be extended) |
| RM-002 | Publish the app free of charge in the Mac App Store (D8): archive, App Store Connect record, metadata, screenshots, privacy policy, submission. | 2026-11-16, user | requested | — | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) (AC04) |

## Delivered

Phase 00 is closed (internal approval report 15, external approval report 16). The specs keep status `draft` until the practical checks in the validation plan are done; the approval covers software and documentation, not practical acceptance. After closure the git repository was set up as part of phase 00 (D35–D37). Phase 01 has not started; RM-001 waits for the open questions in its plan.

| ID | Function | Phase | Spec |
| --- | --- | --- | --- |
| RM-D01 | Printers, queue and completed jobs, with thumbnails for queued jobs | [phase 00](phases/phase-00/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) |
| RM-D02 | Print preview of a job's content, with a warning for partial previews | [phase 00](phases/phase-00/plan.md) (closed) | [PREV-001](../_specs/functional/PREV-001-print-preview.md) |
| RM-D03 | Cancel, pause/resume, reorder (drag and arrows), print again, remove and clear completed jobs | [phase 00](phases/phase-00/plan.md) (closed) | [JOB-001](../_specs/functional/JOB-001-job-actions.md) |
| RM-D04 | English, Dutch and Turkish, with a language choice in Settings | [phase 00](phases/phase-00/plan.md) (closed) | [I18N-001](../_specs/functional/I18N-001-localization.md) |
| RM-D05 | App name, icon, sandbox, signing and App Store preparation | [phase 00](phases/phase-00/plan.md) (closed) | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) |

"Delivered" means built and recorded in a phase; the practical checks listed in the [validation plan](../_specs/getting-started/validation.md) may still be open.
