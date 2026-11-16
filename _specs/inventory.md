# Scope, decisions and research

MacPrintQueueView ("Mac Print Queue View") is a native macOS app that shows what is actually being printed from the existing macOS print queue: select a print job and see a preview of its content. The user can also manage their own jobs in the queue. Target environment: Apple Silicon Mac, macOS 27 (deployment target macOS 14), Xcode 27, Swift 6, printing system CUPS. Distribution: free through the Mac App Store.

## Features

| ID | Subject | Status | Evidence |
| --- | --- | --- | --- |
| [QUEUE-001](functional/QUEUE-001-queue-overview.md) | Printers, queue and completed jobs | draft, v3 | phase 00 evidence |
| [PREV-001](functional/PREV-001-print-preview.md) | Print preview of a job's content | draft, v3 | phase 00 evidence |
| [JOB-001](functional/JOB-001-job-actions.md) | Cancel, pause, reorder, print again and remove jobs | draft, v2 | phase 00 evidence |
| [I18N-001](functional/I18N-001-localization.md) | English, Dutch and Turkish with an in-app choice | draft, v1 | phase 00 evidence |
| [APP-001](functional/APP-001-app-identity-and-distribution.md) | Name, icon, sandbox, signing and App Store readiness | draft, v1 | phase 00 evidence |

All features are `draft`: phase 00 records behaviour that was built before this method was introduced. The user approves them after the phase 00 reviews.

## Product decisions

Explicit user decisions, all made on 2026-11-16 during the work recorded as phase 00. Other choices in the specs are implementation defaults; the main ones are listed below and in the "Observed, yet to be confirmed" section of each feature.

| Decision | Agreement |
| --- | --- |
| D1 | Show the real, existing macOS print queue (not a virtual printer or a separate PDF viewer). Core flow: select a print job → view its content. Show printers and their queues, preview immediately, page through and zoom multi-page documents, update the queue when jobs appear or disappear, and clearly say when a preview is not available. Start simple; add nothing unnecessary. |
| D2 | A job deleted from the queue moves to the "Completed" list; that is accepted behaviour. |
| D3 | A completed job can be put back in the queue ("Print Again"). |
| D4 | The order of the queue can be changed (arrow buttons, context menu). |
| D5 | Completed jobs can be cleaned up (removed permanently). |
| D6 | Only the user's own jobs are shown; other users' jobs are not listed at all. |
| D7 | All text in the app, code comments and repository documents is in English (base language). |
| D8 | The source code is proprietary and kept in a private GitHub repository; the app is offered free of charge to everyone through the Mac App Store. License: "All rights reserved", Copyright Fenma IT. |
| D9 | Sign with the paid Apple Developer team FENMA IT B.V. (Team ID `8RQJ83KNF9`, account `developer@fenma.nl`). |
| D10 | Declare in the app that it uses no non-exempt encryption (`ITSAppUsesNonExemptEncryption = NO`). |
| D11 | The app name is shown as "Mac Print Queue View" (with spaces). |
| D12 | The app is available in English, Dutch and Turkish and follows the system language by default; the user can also choose the language inside the app. |
| D13 | The app icon: a stack of paper sheets with a magnifying glass (accepted as designed). |
| D14 | The job list column gets a modern look; a thumbnail of the first page is shown **only** for jobs in the queue, not for completed jobs. |
| D15 | The queue order can be changed by drag and drop; if the dragged job is already printing when it is dropped, nothing is moved. |
| D16 | Completed jobs show "print again" and "remove" icons on hover or selection, plus trackpad swipe actions; printing again from a row icon or swipe asks for confirmation. |
| D17 | Jobs waiting in the queue can be paused while the rest continues; a job that is printing cannot be paused, which is checked at the moment of clicking. |
| D18 | Canceling a job in the queue happens immediately, without confirmation. |
| D19 | Working method: Claude executes; an independent internal Claude agent reviews until `APPROVED`; Codex is the external reviewer. Specs and reports are in English, review folders are named `phase-NN`, and everything done so far is recorded as phase 00. No commits unless explicitly requested. |
| D20 | (Partly superseded by D23 and D24.) The specification lives in the repository folder `specs/`. Phase plans, evidence, review reports and the working agreements are kept outside the repository, and the repository contains no paths or links to them; the specs cite evidence only by item ID (for example "phase 00 evidence E03"). |
| D21 | The two defects found in review (an incomplete preview without notice; removal without a fresh state check) are fixed within phase 00. |
| D22 | If part of a job cannot be displayed, the readable pages are shown with a warning that says which part is missing, rather than refusing the whole preview. (Implementation note: this covers documents that cannot be rendered; if fetching a document from the printing service fails, the whole preview is unavailable.) |
| D23 | The phase documentation (plans, evidence, review reports, model log) is kept in the repository folder `_docs/`, next to `specs/` (now `_specs/`); this supersedes that part of D20. Only the working agreements stay outside the repository, and the repository contains no paths or links to them. |
| D24 | The specification folder in the repository is named `_specs/` (supersedes the folder name `specs/` in D20 and D23). |
| D25 | The rule that nothing in the repository names or links to the local working environment outside it — the working agreements, the project folder and its other folders (such as local build output and editor settings), and paths in the user's home folder — also applies to historical documents (review reports, evidence, plans, model log). System locations and temporary paths that are part of technical content (for example the CUPS spool directory, the cupsd socket and its configuration file, temporary build folders) are allowed; this matches the user's original rule about the folders of the project folder. Reports refer to the working agreements by role, not by file name. |
| D26 | Report files are named `<NN>-<role>-<model>.md` with role `executor`, `internal` or `external` and one sequence number per phase across all roles (for example `01-executor-claude-Opus-5.5.md`, `02-internal-claude-Opus-5.5.md`, `03-external-gpt-6.1-sol.md`); every executor round has its own executor report. |
| D27 | Phase folders live in `_docs/phases/` (`_docs/phases/phase-NN/` with the phase plan, evidence and reports); the model log stays in `_docs/`. |
| D28 | All requested and planned functions are kept in one overview, [`_docs/roadmap.md`](../_docs/roadmap.md), with an `RM` number and a status; a function is built in a phase with its own phase plan. |
| D29 | Every report (executor, internal, external) starts with a fixed header: Start (UTC), End (UTC), Role, Agent/model, Model verification, Scope, Revision, Verdict. |
| D30 | At the end of every executor round and every review, the executor or reviewer prepares a short handoff message with only the essentials (verdict or status, report path, what must happen, next step), not a summary of the report. |
| D31 | The executor keeps its context small: at the start of a session it reads only the roadmap, the active phase's plan and its latest report (for a new phase also the last review reports of the previous phase), and reads evidence, older reports, older phases and the whole model log only when the task requires it; it reads only the files the task needs, by path; everything a later session needs is recorded in the repository files, not only in the chat; the internal reviewer is started as a new agent, never as a fork of the executor's conversation; and the handoff message says when the chat can be cleared. This does not narrow what reviewers check. |
| D32 | The working agreements and the repository contain no references to the user's central process folder outside the project; the project's rules are self-contained in the working agreements, `_specs/` and `_docs/`. |
| D33 | The git repository in the former subfolder `src/` (without commits) is removed and its whole content is moved to the project folder root, next to the working agreements. There is no version control for now; the user sets up git later. Until then, "repository" in earlier decisions and reports means the project files (everything except the working agreements and the local editor settings and build output), there is no staging baseline, and each executor report lists the files its round created, changed, moved or deleted. |
| D34 | The preview reports incomplete content as far as macOS reports it: documents and images that cannot be read, and images of a TIFF file that macOS does not report. Damaged image data that macOS decodes without an error (for example returned as an empty image) is accepted as a recorded technical limit: it may appear as an empty page without a warning. No heuristic check for empty images is added. |
| D35 | The git repository is created in the project folder root (2026-11-16, after phase 00 was closed), without a commit. The working agreements and the local editor settings stay outside the repository (as in D23); they are ignored through the repository's local exclude file, not the tracked ignore file, so no project file names them (D25); the build output stays in the tracked ignore file. The user confirmed (2026-11-16) that the staging rules that applied before D33 apply again: the review baseline is staged at the start of a round that answers a review report, and phase closure stages all phase changes. The first staging (the closed phase-00 state) is the phase-00 closure staging that could not be done under D33. "Repository" in decisions and reports again means this git repository; D33 describes the period without version control. |
| D36 | Commit messages never contain `Co-Authored-By` or any other attribution line. (A first commit with such a line, made by the user on 2026-11-16 from a proposed message, was undone on the user's request.) |
| D37 | The git repository setup (D35, D36) belongs to phase 00 and needs no separate review or reports; phase 00 ends with report 16. Reports and a review that were briefly written for the setup were removed on the user's request. |

Note (2026-11-16T16:14:54Z): when the reports of phase 00 were restarted, the wording of D21, D25, D26 and D29 was edited to remove references to the removed reports; their content is unchanged apart from clauses about how those reports were treated (neutralized, renamed, kept their headers), which no longer apply.

## Implementation defaults (not explicit user decisions)

Recorded so they do not silently become product decisions: refresh interval of 2 seconds; printer naming, alphabetical sorting and fallback selection; hiding an empty "Completed" section; one main window that quits the app when closed; text layout of plain-text previews (A4, 10 pt monospaced); the "Completed" list shows 50 jobs ordered by job number (highest first); removing a completed job and "Clear…" ask for confirmation; a job that is printing cannot be reordered; "Print Again" from the toolbar or context menu prints without confirmation; the language choice takes effect after a restart; the project layout. The user may confirm or change these in the phase 00 review.

## Research

- [Phase 00 CUPS research](research/phase-00-cups.md): how the app reaches the queue and job documents without root access, and observed cupsd behaviour on this Mac.
