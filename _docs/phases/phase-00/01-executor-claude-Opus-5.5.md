# Phase 00 — report 01

- Start (UTC): 2026-11-16T16:14:54Z (clock, start of this round).
- End (UTC): 2026-11-16T16:15:34Z (clock, before writing the report).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor's own chat (`claude-opus-5-5`, Claude Opus 5.5); no model change during the session.
- Scope: phase 00 as a whole — the existing app, its specification, decisions, architecture, research and evidence ([plan](plan.md)).
- Revision: repository without commits; the baseline of this round was staged (`git -C src add -A`) right after the old reports were removed; the clean-up edits of this round (plan, model log, evidence wording, spec wording) are unstaged and this report is untracked. Because this is the first report of the phase, the review covers all files, not only the diff.
- Verdict: READY FOR REVIEW.

> Note (2026-11-16T16:24:53Z): correction — the round started with the removal of the old reports and the baseline staging at 2026-11-16T16:14:27Z (index time), not at 16:14:54Z; the round's own edits are listed in [executor report 03](03-executor-claude-Opus-5.5.md). Nothing else changed.

## What phase 00 delivers

| Area | Where | Content |
| --- | --- | --- |
| Queue overview | [QUEUE-001](../../../_specs/functional/QUEUE-001-queue-overview.md) | Printers, own jobs in queue order, the 50 completed jobs with the highest job numbers, thumbnails for queued jobs, 2-second refresh |
| Print preview | [PREV-001](../../../_specs/functional/PREV-001-print-preview.md) | Original document fetched with `CUPS-Get-Document`; PDF, images and text; paging and zoom; partial previews with a warning |
| Job actions | [JOB-001](../../../_specs/functional/JOB-001-job-actions.md) | Immediate cancel; pause/resume with a fresh state check; reorder by drag or arrows via priorities; print again; remove and clear completed jobs with a fresh state check |
| Localization | [I18N-001](../../../_specs/functional/I18N-001-localization.md) | English, Dutch, Turkish; system language by default; choice in Settings, applied after a restart |
| App identity | [APP-001](../../../_specs/functional/APP-001-app-identity-and-distribution.md) | Name, icon, sandbox with only the printing entitlement, team signing, encryption declaration |
| Decisions | [inventory](../../../_specs/inventory.md) | User decisions D1–D30 and the implementation defaults |
| Architecture | [architecture](../../../_specs/architecture/index.md), [ADR-001–004](../../../_specs/decisions/index.md), [CUPS research](../../../_specs/research/phase-00-cups.md) | Components, CUPS operations, safety properties, technical choices |
| Evidence | [evidence E01–E25](evidence/README.md) | Development-time checks with their limits |
| Planning | [roadmap](../../roadmap.md) | RM-001 thumbnail zoom (phase 01 draft), RM-002 App Store publication |

## Changes to the app made during phase 00

While the existing app was recorded, two defects were found and fixed (D21):

| Change | Code | Evidence |
| --- | --- | --- |
| A job whose documents cannot all be rendered shows the readable pages with a warning that names each missing document (D22); an empty document gets "The document is empty."; if nothing can be rendered, the reasons are listed | `PreviewBuilder.makePreview`, `QueueStore` (`.loaded(…, warning:)`), `ContentView` (`PartialPreviewBanner`) | E22 |
| Permanent removal re-checks the job state with cupsd right before each purge, also per job in "Clear…"; a job back in the queue is not removed and the user gets a "Not Removed" notice; a job that has disappeared is skipped | `CUPSClient.jobState`, `purgeJobIfFinished`, `purgeFinishedJobs`; `QueueStore.perform`, `actionNotice`; `ContentView` alert | E23, E25 |

Eight new texts were translated into Dutch and Turkish. A code comment in `CUPSClient.swift` lists pause and resume among the user actions. `Tools/sync-strings.sh` takes the build output folder as an optional argument.

## Checks

| Check | Result |
| --- | --- |
| `xcodebuild` Debug and Release (arm64, incremental), 2026-11-16T16:15:09Z | Both succeeded; 0 compiler warnings, 0 errors. A full Release build additionally prints the accepted `appintentsmetadataprocessor` diagnostic (E24). |
| String Catalog | 85 translatable keys; 0 missing Dutch or Turkish translations. |
| Relative links in the repository's Markdown files | 84 links; none broken. |
| Development-time evidence | E01–E25 as recorded, including sandboxed job operations (E04, E06, E07, E20) and the two fixes above (E22, E23, E25). No check printed on paper; all test jobs were removed. |

## Open points

- No automated test target; the criteria are covered by development-time harnesses only.
- Practical checks 1–11 of the [validation plan](../../../_specs/getting-started/validation.md) (real window, paper, App Store).
- Known minor items listed in the [plan](plan.md#known-open-items).
- Proposed defaults and ADRs await the user's confirmation; all features are `draft`.

## Handoff

```text
READY FOR REVIEW — src/_docs/phases/phase-00/01-executor-claude-Opus-5.5.md
Review all of phase 00 (first report of the phase): specs vs code vs evidence.
Next: internal review → report 02-internal-….
```
