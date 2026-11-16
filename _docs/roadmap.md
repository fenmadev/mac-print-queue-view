# Roadmap

Date (UTC): 2026-11-16T23:21:44Z

All functions the user has asked for, planned or delivered. A new request is added here first, with the next free `RM` number. When it is built, it gets a phase plan in `phases/phase-NN/`, and the row links to that plan and, once delivered, to the spec.

Status values: **requested** (recorded, not yet in a phase) → **planned** (assigned to a phase) → **in progress** → **delivered** (with phase and spec) or **dropped** (with reason).

## Planned and requested

| ID | Function | Requested | Status | Phase | Spec |
| --- | --- | --- | --- | --- | --- |
| RM-002 | Publish the app free of charge in the Mac App Store (D8): archive, App Store Connect record, metadata, screenshots, privacy policy, submission. | 2026-11-16, user | requested | — | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) (AC04) |

## Delivered

Phase 00 is closed (internal approval report 15, external approval report 16). The specs keep status `draft` until the practical checks in the validation plan are done; the approval covers software and documentation, not practical acceptance. After closure the git repository was set up as part of phase 00 (D35–D37). Phase 01 (RM-001, RM-003–RM-008) is closed (internal approval report 11, external approval report 12); its practical checks 12–17 are open. Phase 02 (RM-009–RM-011) is closed (internal approval report 04, external approval report 05); its practical checks 18–19 are partly open.

| ID | Function | Phase | Spec |
| --- | --- | --- | --- |
| RM-D01 | Printers, queue and completed jobs, with thumbnails for queued jobs | [phase 00](phases/phase-00/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) |
| RM-D02 | Print preview of a job's content, with a warning for partial previews | [phase 00](phases/phase-00/plan.md) (closed) | [PREV-001](../_specs/functional/PREV-001-print-preview.md) |
| RM-D03 | Cancel, pause/resume, reorder (drag and arrows), print again, remove and clear completed jobs | [phase 00](phases/phase-00/plan.md) (closed) | [JOB-001](../_specs/functional/JOB-001-job-actions.md) |
| RM-D04 | English, Dutch and Turkish, with a language choice in Settings | [phase 00](phases/phase-00/plan.md) (closed) | [I18N-001](../_specs/functional/I18N-001-localization.md) |
| RM-D05 | App name, icon, sandbox, signing and App Store preparation | [phase 00](phases/phase-00/plan.md) (closed) | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) |
| RM-001 | Thumbnail zoom in the queue in 7 steps; step *n* is *n* × the height of step 1 (D38, D42) | [phase 01](phases/phase-01/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) (AC08) |
| RM-003 | Multiple selection in the queue with move, pause, resume and cancel at once, and a grid preview (D39) | [phase 01](phases/phase-01/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) (AC09), [JOB-001](../_specs/functional/JOB-001-job-actions.md) (AC09–AC11), [PREV-001](../_specs/functional/PREV-001-print-preview.md) (AC07) |
| RM-004 | Reorder in the preview grid, with order numbers (D40, D41) | [phase 01](phases/phase-01/plan.md) (closed) | [JOB-001](../_specs/functional/JOB-001-job-actions.md) (AC12), [PREV-001](../_specs/functional/PREV-001-print-preview.md) (AC08) |
| RM-005 | Thicker, clearly visible column divider (D43) | [phase 01](phases/phase-01/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) (AC10) |
| RM-006 | Install script for the Release version (`Tools/install-release.sh`) | [phase 01](phases/phase-01/plan.md) (closed) | [README](../README.md) (Building) |
| RM-007 | A selected job that leaves the queue is deselected and its preview disappears (D44) | [phase 01](phases/phase-01/plan.md) (closed) | [QUEUE-001](../_specs/functional/QUEUE-001-queue-overview.md) (AC11) |
| RM-008 | Test printer script that never prints on paper (`Tools/test-printer.sh`) | [phase 01](phases/phase-01/plan.md) (closed) | [README](../README.md) (Testing without wasting paper) |
| RM-009 | New app icon in the style of Print Center: a printer on a graphite rounded square with a magnifying glass over the printed sheet, full-bleed (D45; replaces D13) | [phase 02](phases/phase-02/plan.md) (closed) | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) (behaviour 2) |
| RM-010 | About window: icon, name, version and build, description, version date and copyright, in the app's language (D46) | [phase 02](phases/phase-02/plan.md) (closed) | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) (behaviour 3, AC05) |
| RM-011 | Build number raised by one with every build (D47) | [phase 02](phases/phase-02/plan.md) (closed) | [APP-001](../_specs/functional/APP-001-app-identity-and-distribution.md) (rule 5) |

"Delivered" means built and recorded in a phase; the practical checks listed in the [validation plan](../_specs/getting-started/validation.md) may still be open.
