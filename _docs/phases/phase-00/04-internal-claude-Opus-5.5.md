# Phase 00 — report 04

- Start (UTC): 2026-11-16T16:25:50Z (clock).
- End (UTC): 2026-11-16T16:27:20Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: the reviewer's own system context (model Opus 5.5, model ID `claude-opus-5-5`), read at the start of this review, 2026-11-16T16:25:50Z.
- Scope: re-review of round 2 (executor report 03): fixes for findings F1–F13 of internal report 02, the F7 handling, new criterion QUEUE-001-AC07 and evidence E26. Unchanged parts of phase 00 were reviewed in report 02 and were checked here only where round 2 touches them.
- Revision: repository `src/` without commits; baseline staged at 2026-11-16T16:23:29Z (55 files, including report 02); round-2 changes unstaged in 14 files (2 Swift files, 12 Markdown files); executor report 03 untracked.
- Verdict: CHANGES REQUESTED.

The reviewer did not implement or fix anything. The only file written to the repository is this report.

## Checks actually run

| Check | Command or procedure | Result |
| --- | --- | --- |
| Round diff | `git -C src status`, `git -C src diff` | Code changes only in `QueueStore.refresh()` and `PreviewBuilder.kind(of:)`; documentation as listed in report 03 |
| Debug build | `xcodebuild … -configuration Debug … -derivedDataPath /private/tmp/mpqv-review-build build` (clean, 2026-11-16T16:26:37Z) | `BUILD SUCCEEDED`; 1 `warning:` line, the accepted `appintentsmetadataprocessor` diagnostic; 0 compiler warnings, 0 errors. Entitlements `app-sandbox`, `print`, `get-task-allow`. Build folder removed afterwards |
| String Catalog | Copy synced with the build's `.stringsdata` files (repeated `--stringsdata`), compared with `cmp` | Unchanged by sync; 85 translatable keys, 0 missing, 0 stale, 0 placeholder mismatches |
| F1 premise and fix | Harness compiled with `QueueStore.swift`, `CUPSClient.swift`, `PreviewBuilder.swift` (no sandbox). Only read requests: `CUPS-Get-Printers`, `Get-Jobs` (`my-jobs`), and the thumbnail document reads that `refresh()` triggers. No job or printer changed. 2026-11-16T16:27:13Z | `CUPSClient.finishedJobs(printer: "MPQV_nonexistent", …)` throws "The document is no longer available in the queue. (CUPS: The printer or class does not exist.)", which confirms the F1 premise. `QueueStore.refresh()` with `MPQV_nonexistent` selected → selected `Brother_MFC_J6520DW` (default), `connectionError` nil, 50 completed jobs; second refresh the same, all completed jobs belong to the selected printer |
| F11 | In-memory harness calling only `PreviewBuilder.kind(of:)` and `makePreview` | `text/plain` + `%!` → text (`makePreview` renders, no problems); `Text/Plain` + `%!` → text; `text/plain` + `%PDF` → pdf; `application/postscript` + `%!` → postscript; `application/octet-stream` + `%!` → postscript; `application/postscript` without signature → postscript; `text/html` → text; `image/png` label → image |
| Links | Script over all Markdown files in `src/` | 104 relative links, none broken |
| Local environment rule | `grep` for home-folder paths, the project folder, the agreements' file names, the editor-settings and build folders | Nothing found (only `DerivedData/` in `.gitignore`) |
| Times | `stat` (UTC) of the round's files and `.git/index` | Index 16:23:29Z = report 03 Start ✓; code 16:24:02Z; specs and evidence 16:24:53Z; plan 16:25:04Z; model log and report 03 16:25:36Z (report 03 End 16:25:28Z, before writing) ✓ |
| Model-log facts | Compared the new summary row with the rows that round 1 removed, as shown by `git -C src diff` at the start of review 02 | See G1 |

## Assessment of the changed criteria

Criteria not listed are unchanged since report 02: the round-2 code changes do not touch their code paths, and their status stands as assessed there.

| Criterion | Status | Explanation |
| --- | --- | --- |
| QUEUE-001-AC01 | PASS | The default-or-first rule now runs inside `refresh()`. At start (nothing selected) the harness logic gives the default printer, and the completed jobs are loaded in the same refresh |
| QUEUE-001-AC06 | PASS | Unchanged behaviour for real connection errors; the false "No connection" case of F1 is gone. NOT TESTED in the window |
| QUEUE-001-AC07 (new) | PASS | Reviewer harness: a missing selected printer → default printer selected, no connection error, its completed jobs shown. A real printer deletion is NOT TESTED (validation plan item 9) |
| PREV-001-AC03 | PASS | Reviewer harness: format detection as in rule 4 (v3); text with a `%!` start renders as text |
| PREV-001-AC04 | PASS | PostScript is still refused when it is labelled PostScript or unlabelled with a `%!` signature |

Code review of the F1 fix: `chosen` is taken from the fresh printer list before `finishedJobs` is requested. It is applied only when the user did not change the selection while the request ran. Setting it runs `didSet` (it clears the old completed list and the job selection, then refreshes), after which `finishedJobs` is set to the chosen printer's list. With no printers left, the selection becomes nil and the completed list empty. No regression found in the start-up path or in a user switching printers during a refresh.

## Status of the report 02 findings

| Finding | Status |
| --- | --- |
| F1 | Resolved: code, QUEUE-001 v3 with AC07, validation item 9, E26; reproduced by the reviewer |
| F2 | Resolved: limits list E23 as sandboxed, E25/E26 as not; APP-001-AC03 lists E23 |
| F3 | Resolved for the evidence register (Date 16:24:53Z = modification time). The same rule is now broken by the plan, see G2 |
| F4 | Resolved (`E01`–`E26`) |
| F5 | Resolved: limits mention `makePDFData` → `makePreview`; PREV-001-AC03 cites E22 and E26 |
| F6 | Partly resolved: the dangling reference is gone and the removed rounds are kept as one row, but that row states a wrong verdict, see G1 |
| F7 | Resolved: dated correction note in report 01; inventory note on D21, D25, D26, D29; report 03 lists the round-1 edits. Optional wording point G3 |
| F8 | Resolved |
| F9 | Resolved |
| F10 | Resolved (PREV-001 behaviour 1) |
| F11 | Resolved: code and PREV-001 rule 4 (v3); reproduced by the reviewer |
| F12 | Resolved: reviewer guideline names permanent removal; JOB-001 and APP-001 name their defaults |
| F13 | Resolved (noted in report 03; the reviewer's clean Debug build again showed the diagnostic) |

## Findings

### G1 — should fix — the model log claims an approval that did not happen

- Location: `_docs/model-log.md`, row "2026-11-16T13:32Z–16:13Z".
- What is wrong: the row says "the last internal review before the restart approved its round." The rows that round 1 removed (visible in `git -C src diff` at the start of review 02) show something else. The last internal review before the restart, at 16:11:34Z, gave **CHANGES REQUESTED**. The executor round that followed (16:11:34Z–16:13:11Z) was never reviewed. The last internal approval was at 16:05:36Z, for an earlier round. The model log must not misstate verdicts, and this sentence overstates the approval state just before the restart. The other facts in the row (internal reviews by Claude Opus 5.5; one external review by `gpt-6.1-sol` at 13:52:46Z, CHANGES REQUESTED, which found the two D21 defects) match the removed rows.
- How to verify the fix: the row says that the last internal review before the restart (16:11:34Z) requested changes and that the following round was not reviewed before the restart, or it leaves out the claim. No other verdict is stated differently from the removed rows.

### G2 — minor — phase plan header is out of date

- Location: `_docs/phases/phase-00/plan.md`, lines 3 and 5.
- What is wrong: round 2 changed the plan (modification time 16:25:04Z), but `Date (UTC)` still says 16:14:54Z. That is the same rule as F3. The Baseline line still says "staged as the baseline for round 1".
- How to verify the fix: the Date line is the time of the plan's last change, and the Baseline line names the current round.

### G3 — optional — inventory note wording

- Location: `_specs/inventory.md`, note under the decisions table.
- What is wrong: "(2026-11-16T16:14Z)" is a truncated time (the edit was at 16:14:54Z), and "their content is unchanged" is slightly too strong. Besides references, the removed clauses described how the old reports were treated (neutralized with notes, renamed, kept their headers). They are moot now, but they were content. A phrase such as "unchanged apart from clauses about the removed reports" would be exact.

## Open practical checks

Unchanged from report 02: all 11 practical checks of the validation plan, now including deleting the selected printer while the app is open (QUEUE-001-AC07). This review approves no visual, paper or App Store behaviour.

## Handoff

```text
CHANGES REQUESTED — src/_docs/phases/phase-00/04-internal-claude-Opus-5.5.md
G1 (should fix): the model log says the last internal review before the restart approved its round; it gave CHANGES REQUESTED (16:11:34Z), and the round after it was never reviewed.
Also 1 minor point (G2, plan Date and Baseline lines) and 1 optional point (G3). F1–F13 resolved; F1 and F11 fixes reproduced.
Next: executor round 3 (stage the baseline, fix G1 and G2) → executor report 05, then internal re-review.
```
