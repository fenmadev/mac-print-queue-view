# Phase 01 — report 12

- Start (UTC): 2026-11-16T22:08:26Z (clock; first recorded clock sample after opening the review brief).
- End (UTC): 2026-11-16T22:11:32Z (clock).
- Role: external.
- Agent/model: `gpt-6.1-sol`.
- Model verification: current reviewer session metadata explicitly identifies `gpt-6.1-sol`; checked at the first recorded clock sample, 2026-11-16T22:08:26Z.
- Scope: external re-review of phase 01 following internal review 11; complete phase-folder inventory, reports through 11, fixes R1–R4 from external report 07, rounds 4–5 (executor reports 08/10, internal reviews 09/11), current specs, evidence and retained negative controls. Both working agreements were read directly. Unchanged phase material retains the assessment of report 07, updated below.
- Revision: HEAD `55933afc44caf8b4754dab9861ac4fdd958db444`. Rounds 1–4 staged as the baseline; round 5 unstaged; reports 10/11 and pinned E09/review-07 files untracked. Read staged and unstaged changes separately and untracked inputs directly. The withdrawn external gate report 09 remains a staged addition with a working-tree deletion; no index changes were made by this reviewer. Temporary SHA-256 manifests identify the reviewed inputs.
- Verdict: APPROVED.

I did not implement or fix anything; the only new project file I wrote in this review is this report.

## Verdict and approval gate

Internal review 09 approves round 4's material fixes, and internal review 11 approves the subsequent evidence/documentation round. The approval gate is met for the current state. Independent safe reruns confirm R1–R4 are resolved. No new blocking or should-fix issue was found.

This approves the software and documentation within the stated test limits. It does not claim practical window, printer-administration, real-installation or paper acceptance, and does not approve proposed implementation defaults on the user's behalf.

## Resolution of external report 07

| Finding | Assessment |
| --- | --- |
| R1 — removal bypasses test-printer identity | **Resolved.** `remove` first calls the read-only exact-URI guard. Another, empty, unreadable or prefix-only URI is refused without an administrator command. Both documented test URIs are accepted without migration during removal. E09 reproduced all cases using stubs. |
| R2 — negative acceptance text treated as positive | **Resolved.** Positive/negative text is distinguished; a rejecting queue is enabled and rechecked; unreadable/unknown state and an ineffective enable are refused. E09 reproduced each case. |
| R3 — destination interpreted as regex | **Resolved.** Process command text is compared with the quoted literal target prefix rather than a regex. Failure to read the process list stops replacement. E09 independently confirms two destination dummies are quit, a similarly named destination remains untouched, and replacement is skipped on ps failure. Multiple PID expansion is also corrected. Noncanonical launch-path limitations remain disclosed; see open items. |
| R4 — increasingly stale bulk-pause snapshot | **Resolved.** `BulkPause.run` queries each candidate immediately before its hold, skips newly printing/other jobs, and continues after query/hold failures. Actual QueueStore code maps a fresh `CUPSClient.jobStatus(id:)` to that policy. Independent fake-client cases prove B is not held when it starts printing while A is handled, including A's failure case; C is still processed. The old snapshot negative control demonstrates the former failure. |

Internal review 09's evidence-reproducibility finding is also resolved: negative-control scripts are retained and SHA-256 checked rather than read from the changing git index. Their hashes exactly match my saved review-07 input manifest, independently confirming their provenance.

## Correction of the withdrawn gate report

My external gate report named `09-external-gpt-6.1-sol.md` was erroneous and has been withdrawn and removed from the working tree by its author. I did not recheck the phase-folder inventory before writing it; internal review 09 had appeared by then. Its BLOCKED verdict must not be treated as the current gate state. The internal report was never removed or changed.

Internal review 11's M1 and the subsequent plan/model-log entries describe that external report while it still existed. The current links to it are now stale because of my withdrawal, not because of an executor implementation defect. This report supplies the authoritative correction. At closure, the executor can record the withdrawal, point the historical references here and stage the intended final state under the existing rules. Do not recreate the incorrect gate report or renumber internal review 09 merely to repair links. This is record-keeping, not a product blocker or a request for a new implementation round.

## Independent checks

| Check performed | Result and limits |
| --- | --- |
| Full phase-folder inventory and current gate | Enumerated the complete phase-01 folder recursively, including every report, harness, result file and pinned script; checked the latest plan/model-log status and actual internal approvals 09/11. No missing approval inferred from the supplied filename. |
| Actual changes since external 07 | Compared with the retained review-07 SHA-256 manifest: changed existing inputs are CUPSClient, QueueLayout, QueueStore, both scripts, README, JOB-001, E01 source/results, evidence register, plan and model log. Matches rounds 4–5. Other previously reviewed implementation paths are unchanged. New evidence/reports inspected directly. |
| E01 | Compiled current QueueLayout and the retained main with `swiftc -O`. 68 PASS checks, ALL PASS, output byte-identical to retained results. Includes 63 original checks, per-job pause state changes/query failures/hold failures and an old-snapshot negative control. |
| E02 | Compiled actual CUPSClient, PreviewBuilder and QueueLayout with the retained main. All six assertions PASS, ALL PASS: 728-pixel thumbnails, one-page grid document with correct total page count, multi-document content and partial-warning preparation. No CUPS method invoked. |
| E09 | Read the entire shell harness before execution. Ran with isolated printer/admin/build/signature stubs and only its own compiled dummy programs in a fresh temporary folder. All 26 checks PASS; output byte-identical to retained results; stderr empty. Includes the pinned former-script negative controls. No real application installed or printer command delegated. |
| Pinned negative controls | SHA-256: test-printer `16a7ded80030c9ae41821ce4a61f56b68c6eeab2bd3c832869a45afb7181c2ef`; install-release `b6d74a8d2a9d6b6db918235c1af3ee6a2714261f76d9ac1e75c8cc010616263c`. Both equal the files inspected during external review 07. |
| Debug and Release | Both fresh builds succeed, zero errors and compiler warnings. Each emits only the accepted appintentsmetadataprocessor metadata-extraction warning. No app launch or provisioning/account operation. |
| Translations and extraction | 106 catalog keys, 105 translatable; all nl/tr units translated; placeholder index/type checks pass. Debug extracted keys equal catalog keys exactly. No new strings in rounds 4–5. Catalog not modified. |
| Script syntax and diff | `zsh -n` passes for both product scripts and E09. Unstaged `git diff --check` passes. No staging or commit performed. |
| Relative links | Current genuine broken links point to the withdrawn gate report and are covered by the correction above. Inline regex-like sample paths containing `[x](y)` are code text, not actual Markdown links; no unrelated broken file link found. |
| Input integrity | Temporary manifest covers 115 existing tracked/untracked input files, excluding the already-withdrawn report. Final hashes unchanged through this review. |

Commands from the project root:

```sh
swiftc -O -module-cache-path /private/tmp/mpqv-phase01-review12/cache \
  MacPrintQueueView/QueueLayout.swift \
  _docs/phases/phase-01/evidence/E01/main.swift \
  -o /private/tmp/mpqv-phase01-review12/e01
/private/tmp/mpqv-phase01-review12/e01

zsh _docs/phases/phase-01/evidence/E09/run.sh \
  /private/tmp/mpqv-phase01-review12/e09

xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView \
  -configuration <Debug-or-Release> -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/mpqv-phase01-review12/build build
```

E02 uses the compilation command recorded in its retained main, adding CUPSClient and PreviewBuilder to QueueLayout. Builds and the dummy-process harness ran with permission for local compiler/signing/process access; the latter still used stubs for all printer and administrator operations. No existing user process, installed app, print job, printer, system preference or account was changed. No paper output. I did not run the live-job E04/E07 scripts.

## Acceptance assessment

Code assesses conformance by inspection and the specified safe reruns. Execution distinguishes independent results from historical evidence and pending practical checks. Unchanged criteria retain report 07's assessment; the former FAIL results below are replaced by PASS within the documented limits.

| Criterion / requirement | Code | Execution / evidence |
| --- | --- | --- |
| QUEUE-001-AC08, seven thumbnail steps | PASS | E01/E02 independently PASS; historical E03/E05 partial. Actual controls/window/restart NOT TESTED. |
| QUEUE-001-AC09, multiple selection | PASS | E01 independently PASS; E04/E08 historical integration. Actual click/range/header highlights NOT TESTED. |
| QUEUE-001-AC10, divider | PASS | Implementation unchanged since report 07; E05/E06 historical. Actual appearance/drag NOT TESTED. |
| QUEUE-001-AC11, deselect departed job | PASS | E01 independently PASS; E04 historical store evidence. Actual window NOT TESTED. |
| PREV-001-AC07, grid preview | PASS | E01 dimensions/E02 content preparation independently PASS; current grid wiring unchanged. Actual rendering/interaction NOT TESTED. |
| PREV-001-AC08, order numbers | PASS | Row-major badge code unchanged; visual result NOT TESTED. |
| JOB-001-AC09, multi-cancel confirmation | PASS | Ownership-filtered routing and continue-after-failure code unchanged; E04 historical, real dialog NOT TESTED. |
| JOB-001-AC10, gathered/list moves | PASS | E01 independently PASS; E07 historical actual held-job ordering. Live move NOT TESTED here. |
| JOB-001-AC11, pause/resume several | PASS | R4 independently verified through actual pure policy with a fake client and actual store/CUPS mapping reviewed. Real multi-pending pause NOT TESTED; resume's live happy path remains historical E04, failure continuation by code review. |
| JOB-001-AC12, grid reorder | PASS | E01 exact example independently PASS; E07 historical. Real drag NOT TESTED. |
| RM-006, install script | PASS | R3 independently verified by E09 dummy processes and fake destination payload, including process-query failure. Real installation NOT TESTED. |
| RM-008, test-printer script | PASS | R1/R2 independently verified with actual scripts under stubs. Admin-driven create/printing/complete/remove remain NOT TESTED on a real queue. |

The affected existing ownership, thumbnail, single-preview, warning and single-cancel criteria keep report 07's PASS-by-code assessment. I18N-001-AC04 is independently PASS again. The old single-job pause safeguard now shares the per-job bulk policy; both are checked against D17. Other phase-00 criteria and practical limits remain as previously recorded, not newly exercised here.

## Phase acceptance and open work

- **PASS:** the feature specs cover the requested zoom, selection, grid, ordering, action and divider scope; JOB-001 v4 now matches the per-job state-check implementation.
- **PASS:** pure logic and regression checks from current sources, including D39's ordering example.
- **PASS as historical evidence:** safe held-job ordering and action checks E04/E07. They were not rerun by this external reviewer.
- **PASS within test limits:** corrected bulk-pause logic and script guard behaviour independently verified without touching real jobs, printers or installations.
- **PASS as qualified historical evidence:** row/column/divider/crash regression checks; practical appearance and interaction are still open.
- **PASS:** current Debug/Release builds and localization completeness independently verified.
- **PASS:** internal approval 09/11 followed by this external approval. Administrative closure remains the executor's work.

Practical validation items 12–17 remain open: actual zoom/layout/shortcuts, selection and section-header behaviour, grid/order numbers, both cancellation choices, list/grid dragging, pausing pending jobs, divider across layouts/screens, administrator-driven test-printer commands and real installation. Earlier phase-00 practical checks remain open too.

Optional O1–O2 of internal review 06 remain traceability/history points. Internal review 11's optional points also remain: E09 supports its documented relative invocation but refuses a full absolute invocation, and the install script's documented symbolic-link launch limitation also applies to relative or otherwise noncanonical executable command paths. These limits were not silently claimed tested or solved here. Proposed implementation defaults remain for the user. CUPS state query and mutation remain separate requests; the per-job fix removes avoidable batch staleness but does not claim atomicity.

Next: executor records this approval, reconciles the withdrawn gate-report references and closes phase 01 under the working agreements, preserving practical checks and optional points. Merely recording this approval/correction does not require a new implementation round. The next free phase-01 report number is 13 if another report is needed.
