# Phase 00 — report 02

- Start (UTC): 2026-11-16T16:16:00Z (clock).
- End (UTC): 2026-11-16T16:22:11Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: the reviewer's own system context (model Opus 5.5, model ID `claude-opus-5-5`), read at the start of this review, 2026-11-16T16:16:00Z.
- Scope: all of phase 00, as the first review after the restart of the phase's reports: the five feature specs compared with the Swift code, decisions D1–D30 and the implementation defaults, architecture, ADR-001..004, CUPS research, evidence E01–E25, plan, model log, roadmap, phase 01 draft, guidelines, README, tools, and executor report 01. The executor agreement and the external-reviewer agreement were read directly.
- Revision: repository `src/` without commits; the baseline is staged (53 files); this round's unstaged edits are in 8 files (`_docs/model-log.md`, `_docs/phases/phase-00/evidence/README.md`, `_docs/phases/phase-00/plan.md`, `_specs/agent-guidelines/reviewer.md`, `_specs/functional/JOB-001-job-actions.md`, `PREV-001-print-preview.md`, `QUEUE-001-queue-overview.md`, `_specs/inventory.md`); executor report 01 is untracked.
- Verdict: CHANGES REQUESTED.

The reviewer did not implement or fix anything. The only file written to the repository is this report.

## Checks actually run

| Check | Command or procedure | Result |
| --- | --- | --- |
| Repository state | `git -C src status`, `git -C src diff`, `git -C src diff --cached --stat` | As described under Revision. None of the removed reports is left in the folder or the index |
| Debug build | `xcodebuild … -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath /private/tmp/mpqv-review-build build` (clean, 2026-11-16T16:17:23Z) | `BUILD SUCCEEDED`. The log has 1 line with `warning:`, the accepted `appintentsmetadataprocessor` diagnostic. 0 compiler warnings, 0 errors. Build folder removed afterwards |
| Bundle values | `PlistBuddy` on the built Info.plist | Name and display name "Mac Print Queue View", `nl.fenma.MacPrintQueueView`, 1.0 (1), minimum 14.0, "Copyright © 2026 Fenma IT", `ITSAppUsesNonExemptEncryption` false, icon `AppIcon`; `nl.lproj` and `tr.lproj` present |
| Signing | `codesign -dvv`, `codesign -d --entitlements -` | Team `8RQJ83KNF9`, hardened runtime (`flags=0x10000(runtime)`), entitlements `app-sandbox`, `print`, `get-task-allow` |
| Property lists | `plutil -lint` on the entitlements file and `project.pbxproj` | OK |
| String Catalog | Copy of `Localizable.xcstrings` in a scratch folder (named `Localizable.xcstrings`), `xcstringstool sync` with the build's 11 `.stringsdata` files; JSON check script | Sync changes nothing, so the catalog matches the code. 85 translatable keys, 0 missing nl/tr, 0 stale, 0 placeholder mismatches. The repository catalog was not touched |
| PreviewBuilder harness | Isolated harness compiled with `PreviewBuilder.swift` and `CUPSClient.swift`; calls only `PreviewBuilder.makePreview` and `makeThumbnailPNG` with in-memory documents (no CUPS call) | 3-page PDF → 3; PDF labelled `application/octet-stream` → 2; password-protected PDF → "The PDF document is password protected."; 200-line text → 4; Latin-1 text → 1; PNG, JPEG, TIFF, HEIC → 1 each; 3-frame GIF → 3; PNG labelled `application/octet-stream` → 1; PostScript → PostScript message; `application/vnd.cups-raster`, `image/urf`, `image/pwg-raster` → "Document format “…” cannot be displayed."; empty → "The document is empty."; text + PNG → 5; text + empty + text → 8 pages + "Document 2 of 3: The document is empty."; undecodable PNG + PostScript → "None of the documents…" with both reasons; thumbnail 106×160. A `text/plain` document starting with `%!` → PostScript message (see F11) |
| Links | Script over all Markdown files in `src/` (relative links and anchors) | 99 relative links, none broken |
| Local environment rule | `grep` for home-folder paths, the project folder, the agreements' file names, the editor-settings folder, the build folder | Nothing found. Allowed: `/tmp` in a `Tools/make-icon.swift` usage comment, system paths (`/etc/cups/cupsd.conf`, `/private/var/run/cupsd`, `/private/var/spool/cups`). The evidence names the tool "VS Code" and "the launch settings" (E19) without a path. That is a neutral description |
| Times | `stat` (UTC) of the changed files and of `.git/index` | The round's edits all have the time 16:14:54Z; the model log 16:15:34Z; report 01 16:15:57Z; the index (baseline staging) 16:14:27Z. The evidence register changed after its Date line (see F3); report 01's start time is later than the staging (see F7) |
| Printers (read-only) | `lpstat -d -p`; `sw_vers`; `xcodebuild -version` | One printer `Brother_MFC_J6520DW` (default, idle); macOS 27.2.1 (26B131); Xcode 27.2. Matches the evidence environment |
| Code reading | All 9 Swift files, compared line by line with the five specs and the scenario overview | See the assessment and the findings |

Not run, under the safety rules: nothing that sends IPP requests to cupsd (no CUPS harness), no printing, no app launch.

## Assessment per acceptance criterion

"Code" means checked by reading the code. Visual, hardware and paper checks are listed under open practical checks.

| Criterion | Status | Explanation |
| --- | --- | --- |
| QUEUE-001-AC01 | PASS | Code: `CUPSClient.printers()` filters `printer-is-temporary` and marks the default printer. `refresh()` selects the default or the first printer. The badge shows the count of the user's active jobs. E03. Display not checked |
| QUEUE-001-AC02 | PASS | Code: `queueOrder` (not waiting first, then priority, then job number), `finishedJobs` sorted by job number, highest first, cut to 50; both section headers show counts. E03, E08 |
| QUEUE-001-AC03 | PASS | Code: `cupsGetJobs2(…, myjobs = 1, …)` for both lists. E10. Exclusion with a second user NOT TESTED |
| QUEUE-001-AC04 | PASS | Code: `run()` loop with 2 s sleep; UI updated only when data changed. Timing in the window not measured |
| QUEUE-001-AC05 | PASS | Code: thumbnails only for `activeJobs`; `FinishedJobRow` has no thumbnail. E13, E17 |
| QUEUE-001-AC06 | PASS | Code: "No Printers" overlay; "No connection to the printing service" overlay with the error. NOT TESTED in the window. F1 shows the same "No connection" overlay for an error that is not a connection error |
| PREV-001-AC01 | PASS | Code: `CUPS-Get-Document` per document. E01–E03 |
| PREV-001-AC02 | NOT TESTED | Code: toolbar buttons, ⌘↑/⌘↓, ⌘-/⌘0/⌘=, "Page x of y" wired to `PDFViewController`. No check exercised them |
| PREV-001-AC03 | PASS | Reviewer harness: PDF, PNG, JPEG, TIFF, HEIC, multi-frame GIF, text, and several documents as one sequence |
| PREV-001-AC04 | PASS | Reviewer harness: PostScript, raster, `image/urf`, empty, undecodable. Code: not-found and no-document messages. Messages in the window not seen |
| PREV-001-AC05 | PASS | Code: temporary file opened `O_EXCL` 0600 and unlinked right away; sandbox per E04. On-disk absence only by code review |
| PREV-001-AC06 | PASS | Reviewer harness reproduced E22. Code: `.loaded(…, warning:)` → `PartialPreviewBanner`. Banner not seen |
| JOB-001-AC01 | PASS | Code: `cancel` without confirmation; ⌫ via `deleteSelection`. E06, E15. Canceling a printing job NOT TESTED |
| JOB-001-AC02 | PASS | Code: `canPause` only for pending, `holdJob` with `indefinite`, `releaseJob`. E14, E20. Real pending job NOT TESTED |
| JOB-001-AC03 | PASS | Code: control disabled unless pending; re-check through `activeJobs()` and message when printing. Printing case NOT TESTED |
| JOB-001-AC04 | PASS | Code: `apply(order:moved:)` priority assignment. E08 |
| JOB-001-AC05 | PASS | Code: re-check guard returns without error. E13 (simulated with a canceled job) |
| JOB-001-AC06 | PASS | Code: row icon and swipe → `requestReprint` (confirmation); toolbar and context menu → `restart` directly. Real reprint NOT TESTED (paper) |
| JOB-001-AC07 | PASS | Code: own-user filter; per-job `purgeJobIfFinished`. E09, E23. "Clear…" on real history NOT TESTED |
| JOB-001-AC08 | PASS | Code: `jobState` re-check; "Not Removed" notice. E23. Notice not seen |
| I18N-001-AC01 | PASS | Reviewer catalog check (complete, placeholders kept); E11. Texts in the window per language NOT TESTED |
| I18N-001-AC02 | PASS | E21; bundle has en (development), nl, tr |
| I18N-001-AC03 | PASS | Code: `AppleLanguages` stored or removed; restart notice. E12. "Restart Now" NOT TESTED |
| I18N-001-AC04 | PASS | Reviewer catalog check: 85 keys, 0 missing, sync changes nothing |
| APP-001-AC01 | PASS | Reviewer Debug build: all values as specified (E16 for Release) |
| APP-001-AC02 | PASS | Reviewer Debug build: team, sandbox, print, `get-task-allow`, hardened runtime |
| APP-001-AC03 | CANNOT VERIFY | This reviewer may not send CUPS requests. The evidence (E04, E06, E07, E20, E23) supports it partly, with harness bundles, not the app bundle |
| APP-001-AC04 | NOT TESTED | Not attempted; correctly stated as such |

## Findings

### F1 — should fix — a disappearing selected printer is not replaced, and a "No connection" error stays

- Location: `MacPrintQueueView/QueueStore.swift`, `refresh()`; spec QUEUE-001 behaviour 2 and edge cases.
- What is wrong: QUEUE-001 behaviour 2 says "if the selected printer disappears, the same rule picks another." In `refresh()`, `CUPSClient.finishedJobs(printer: selectedPrinterName)` is inside the same `Result` as the printer and active-job requests. The fallback selection runs only in the `.success` branch. For a printer that no longer exists, cupsd answers `Get-Jobs` with `client-error-not-found`, and libcups `cupsGetJobs2` then returns -1, so `finishedJobs` throws. Every refresh then fails the same way. The selection is never moved. The printer column shows "No connection to the printing service" with "The document is no longer available in the queue. (CUPS: …)", although the service can be reached. This contradicts the spec and the phase acceptance ("nothing in the specs contradicts the code"). It happens, for example, when the user deletes the selected (default) printer in System Settings while the app is open. No criterion covers the fallback, so no AC flags it.
- How to verify the fix: make the printer fallback independent of the completed-jobs request. One way is to pick the printer from the fresh printer list before requesting its completed jobs. Another is to treat a failing completed-jobs request for a printer that is no longer listed as "switch printer". Confirm it with a read-only harness: `CUPSClient.finishedJobs(printer: "MPQV_nonexistent", limit: 50)` (a `Get-Jobs` request, which changes nothing) throws today. After the fix, `refresh()` with that name selected ends with the default printer selected and `connectionError == nil`. Optionally add a criterion to QUEUE-001 and list the case in the validation plan.

### F2 — minor — sandbox scope in the evidence limits is incomplete

- Location: `_docs/phases/phase-00/evidence/README.md` (limits, fourth bullet); `_specs/functional/APP-001-app-identity-and-distribution.md` (AC03 traceability); report 01 (checks table).
- What is wrong: the limits say E04, E06, E07 and E20 ran sandboxed and "the other harnesses ran without the sandbox". E23's own row, and JOB-001-AC07's traceability, say E23 ran in a sandboxed harness bundle. APP-001-AC03 does not list E23 either.
- How to verify the fix: the limits bullet and APP-001-AC03 list E23 (and say whether E25 was sandboxed); no item is called both sandboxed and not sandboxed.

### F3 — minor — the evidence register's Date line is not the time of its last change

- Location: `_docs/phases/phase-00/evidence/README.md`, line 3.
- What is wrong: this round changed the file (modification time 2026-11-16T16:14:54Z). The Date line still says 14:10:40Z. The reviewer guideline requires the actual time of the last change.
- How to verify the fix: the Date line matches the file's last change.

### F4 — minor — stale evidence range in QUEUE-001

- Location: `_specs/functional/QUEUE-001-queue-overview.md`, Traceability intro ("items `E01`–`E21`").
- What is wrong: the evidence now runs to E25.
- How to verify the fix: the range reads `E01`–`E25`, or the item IDs are left out.

### F5 — minor — E03 and E05 name a function that no longer exists

- Location: evidence E03, E05; PREV-001-AC03 and AC04 traceability.
- What is wrong: E03 and E05 called `PreviewBuilder.makePDFData`, which the partial-preview fix replaced with `makePreview`, which renders each document separately. The limits bullet about later edits does not mention this, and PREV-001-AC03 relies on E05 for several documents. (This reviewer's harness reproduced the E05 results with the current `makePreview`, so the claim holds, but the evidence trail does not show it.)
- How to verify the fix: the evidence limits mention that `makePDFData` was replaced by `makePreview`, and PREV-001-AC03 also cites E22, which covers the current function with several documents.

### F6 — minor — model log: dangling reference and collapsed history

- Location: `_docs/model-log.md`, rows 2 and 3.
- What is wrong: row 2 says "see the phase 00 plan" for the changes of location and folder names, but this round removed that history from the plan. Row 3 replaces the removed rounds with one line. The model log therefore no longer records that an external review (with its model) took place, or that it found the two defects of D21. The executor agreement asks to preserve the model log's history. The user asked for the reports to restart, but whether that also covers the model-log rows cannot be verified from the repository.
- How to verify the fix: row 2 no longer points to text that is gone (or the plan keeps a one-line location history). The executor confirms with the user that collapsing the model-log rows was intended, or keeps a short factual record of the removed review rounds (roles, models, verdicts), without links to the removed files.

### F7 — minor — executor report 01 is incomplete about its own round

- Location: `_docs/phases/phase-00/01-executor-claude-Opus-5.5.md`.
- What is wrong:
  1. Start (UTC) 16:14:54Z is later than the baseline staging (`.git/index` 16:14:27Z) and the report removal, which the report itself counts as part of the round. 16:14:54Z is the time the edits were written.
  2. The report lists the changes of the whole phase, but not this round's edits. In particular, it does not mention that the text of recorded user decisions D21, D25, D26 and D29 was reworded, and that a sentence was removed from the reviewer guideline. The inventory has no note on these rewordings; for D20 a "partly superseded" note was used.
- How to verify the fix: the report's start time is no later than the staging, and a short "changes in this round" list names the reworded decisions. The rewording is either marked in the inventory or confirmed as intended by the user.

### F8 — minor — the developer guideline contradicts the report header rule

- Location: `_specs/agent-guidelines/developer.md`, "Language and identifiers".
- What is wrong: it says "Reports keep the label `Date (UTC)`". Since D29, reports carry Start (UTC) and End (UTC) in the fixed header; `Date (UTC)` applies to plans, evidence and the roadmap (reviewer guideline).
- How to verify the fix: the sentence matches D29 and the reviewer guideline.

### F9 — minor — APP-001 overstates when the app quits

- Location: `_specs/functional/APP-001-app-identity-and-distribution.md`, behaviour 5.
- What is wrong: "quits when that window is closed". The code (`applicationShouldTerminateAfterLastWindowClosed`) quits when the last window closes. With the Settings window open, closing the main window does not quit the app. The architecture document says this correctly.
- How to verify the fix: the wording says "when the last window is closed", or the code is changed to match.

### F10 — optional — the preview's empty state is not described

- Location: PREV-001, Behaviour for the user.
- What is wrong: with no job selected, the preview shows "No Job Selected — Select a print job to see what is being printed." and the window title is the app name. Neither is in a spec.

### F11 — optional — a `text/*` document that starts with `%!` is refused as PostScript

- Location: `PreviewBuilder.kind(of:)`; PREV-001 rule 4 ("any `text/*` type … laid out").
- What is wrong: content sniffing for `%!` runs before the label check (reviewer harness: `text/plain` "%!not postscript…" → PostScript message). This is rare, but the spec states otherwise. Either note it in the spec or check the label first for `text/*`.

### F12 — optional — small consistency points between the guidelines, the defaults and the specs

- `_specs/agent-guidelines/reviewer.md` lists re-checked actions as "(pause, reorder)". Permanent removal now re-checks too.
- The inventory lists as defaults "removing a completed job and 'Clear…' ask for confirmation", "a job that is printing cannot be reordered" and "one main window that quits the app". JOB-001 and APP-001 do not repeat these in their "Observed, yet to be confirmed" sections.

### F13 — optional — build diagnostic wording in report 01

- Location: report 01, checks table.
- What is wrong: it says a full Release build "additionally" prints the `appintentsmetadataprocessor` diagnostic. The reviewer's clean Debug build printed it too; only incremental Debug builds do not. This does not affect the phase acceptance, which accepts the diagnostic for every build.

## Report 01 accuracy

Correct and verified: the two defect fixes and where they are in the code; 8 new translated texts (catalog now 85 keys, 0 missing); the code comment in `CUPSClient.swift`; the optional argument of `Tools/sync-strings.sh`; no broken links (this reviewer counted 99 links including those of report 01 itself); the open points; the handoff. Not accurate or incomplete: see F2 (sandbox list), F7 (start time, round changes) and F13.

## Open practical checks

All 11 practical checks of the validation plan remain open: the window in light and dark mode; a real multi-page preview with paging, zoom and the partial-preview banner; pausing and resuming a real pending job; the "already printing" pause refusal; dragging and canceling a printing job; a real "Print Again"; the languages with "Restart Now" and a native-speaker review of Turkish; removing one job and "Clear…" in the window; the printer column without printers or without the service; another user's jobs; App Store upload and review. In addition, F1 has to be checked after the fix (see its verification). This review approves no visual, paper or App Store behaviour.

## Handoff

```text
CHANGES REQUESTED — src/_docs/phases/phase-00/02-internal-claude-Opus-5.5.md
F1 (should fix): a removed selected printer is never replaced; refresh keeps failing with a false "No connection" message (QueueStore.refresh vs QUEUE-001 behaviour 2).
Also 8 minor (F2–F9) and 4 optional points (F10–F13).
Next: executor round 2 (stage the baseline, fix F1 and the minor points) → executor report 03, then internal re-review.
```
