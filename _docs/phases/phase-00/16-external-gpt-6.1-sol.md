# Phase 00 — report 16

- Start (UTC): 2026-11-16T17:51:11Z (clock; first recorded clock sample after opening the review brief).
- End (UTC): 2026-11-16T17:53:33Z (clock).
- Role: external.
- Agent/model: `gpt-6.1-sol`.
- Model verification: current reviewer session metadata explicitly identifies `gpt-6.1-sol`; checked at the first recorded clock sample, 2026-11-16T17:51:11Z.
- Scope: external re-review following internal report 15; K1 from external report 09, executor rounds 5–7 (reports 10, 12, 14), internal reviews 11, 13, 15, PREV-001 v4, D34, E27/E28, catalog, current plan and model log. Both working agreements were read directly. Unchanged phase-00 material retains the assessment of report 09, updated below.
- Revision: no version control (D33). Compared actual project files against the retained SHA-256 manifest from external review 09: changes are exactly PreviewBuilder.swift, Localizable.xcstrings, PREV-001, inventory, evidence register, plan and model log; new reports and E27/E28 artifacts were inspected directly. Only report 15 and approval-recording plan/model-log updates are newer than internal review 15's start. No later product change found.
- Verdict: APPROVED.

I did not implement or fix anything; the only project file I wrote is this report.

## Verdict and scope of approval

K1 is resolved for the reproduced failure and the explicit per-image failure path. The current code preserves readable pages and reports the missing image count, also inside a multi-document job. D34 records the user's disposition of the platform limit: image data that macOS returns as successfully decoded cannot reliably be distinguished from legitimate empty image content. The specification states that limit rather than claiming a heuristic detects it. I did not alter requirements or make that product decision on the user's behalf.

Internal report 15 explicitly approves the current material changes. I found no new blocking or should-fix issue. This is software and documentation approval of phase 00; it does not approve the pending practical checks, App Store publication, proposed product defaults or ADRs on the user's behalf.

## Findings and resolutions

| Finding | Result |
| --- | --- |
| K1, external report 09 | **Resolved.** Independently reproduced with the preserved fixtures: valid TIFF → 2 pages/no problems; bad-compression TIFF → 1 readable page plus “Only 1 of the 2 images in this document can be displayed.” Generic MIME label behaves identically. Text plus the TIFF adds “Document 2 of 2:” to that warning. Current `makePreview` propagates per-image missing-content information to the existing warning mechanism. |
| L1, internal report 11 | **Resolved.** Count traversal is capped at 10,000 directories and 255 inspected entries per directory; loops terminate through the visited set. TIFF counting is skipped for thumbnails and when ImageIO reports zero images. The remaining data-copy cost is linear in input size. E28 rerun supports the intended improvement; timings below are measurements, not a universal deadline. |
| L2, internal report 11 | **Resolved.** E27's comment distinguishes the two fixtures named/hashed in report 09 from the third fixture originating in its temporary folder. Report 12 records the correction without rewriting report 10. All three actual hashes match the evidence register. |
| M1/M2, internal report 13 | **Resolved.** The first 255 entries are searched regardless of tag order; LONG8 uses 8 bytes for BigTIFF. The retained unsorted-thumbnail and big-endian LONG8 cases both return one full-resolution image in my E27 rerun. |

No new findings. L3 remains an optional Dutch wording choice for the user. H1–H2 and J1–J4 remain the previously recorded non-blocking documentation/future-work points; this approval does not require rewriting historical reports to remove them.

## Independent checks

| Check actually performed | Result and limits |
| --- | --- |
| Actual files versus review-09 manifest | The seven changed existing files match the executor change lists. Other previously reviewed code and project inputs are unchanged. A new temporary manifest was used to check review inputs remain unchanged through report delivery. No version-control command used. |
| Source review | Read the complete current PreviewBuilder, the changed spec/decision, retained harnesses and reports 10–15. Checked warning propagation, thumbnail behavior, parser byte order/value sizes, range checks, traversal bounds and termination. Other app code remains byte-identical to the reviewed baseline. |
| E27 | Compiled actual CUPSClient.swift and PreviewBuilder.swift with the retained E27 main. Output is byte-identical to `E27/results.txt` (21 lines); stderr empty. No CUPS function invoked. Covers K1, generic label, multi-document warning, prior undecodable-image case, valid TIFF/GIF/PNG/JPEG/text, rejected TIFF chains, classic/BigTIFF count cases and round-7 cases. |
| D34 fixture | `bad-second.tiff` still yields 2 pages and no problem, exactly as disclosed. This is the recorded platform limit, not evidence that damaged pixels are detected. |
| Fixture hashes | `two.tiff`: `71f03f359fc38d79e44958ad3f44ab0d9cc6281c8e6fc96dfe2bf86c14655908`; `bad-compression.tiff`: `931a99de3d6e872b9c197cae32a7d968ad71661ad2326d76df69f283cdd48155`; `bad-second.tiff`: `14409ded8d2dd39a947cda55711a1c18ceab0e587810b5e0454caf7770b6bda2`. All match the evidence. |
| E28, optimized build | BigTIFF 20,000,032 bytes → count 1 in 0.002 s. Classic chain 30,660,008 bytes → count 10,000 in 0.006 s. Consistent with recorded millisecond-scale results. I did not repeat the internal reviewer's broader fuzzing and valid-file generation; those remain attributed historical checks. |
| Debug and Release | Both fresh builds succeed, zero errors and compiler warnings. Each emits only the accepted appintentsmetadataprocessor metadata-extraction warning. Normal development signing, no provisioning/account action or app launch. |
| Catalog/source equality | 87 keys, 86 translatable; all nl/tr units translated. Placeholders match by argument position and type, including reordered Turkish positional placeholders. Extracted Debug `.stringsdata` keys equal catalog keys exactly; sync script not executed. |
| Bundle/signing | Both fresh bundle plists match the name, identifier, version 1.0 (1), minimum macOS 14.0, copyright, encryption declaration and icon. Release reports team `8RQJ83KNF9`, hardened runtime, app-sandbox, print and get-task-allow. Certificate authority unavailable to the restricted inspector; no certificate-chain or distribution-export approval claimed. |
| Documentation and gate | D34, PREV-001 v4, E27/E28, plan, model log and executor/internal report chain agree. The only post-gate updates record report 15's approval. No broken relative file links across 41 project Markdown files, code fences excluded. |

Commands, from the project root:

```sh
swiftc -O -module-cache-path /private/tmp/mpqv-review16/cache \
  MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
  _docs/phases/phase-00/evidence/E27/main.swift -o /private/tmp/mpqv-review16/e27
/private/tmp/mpqv-review16/e27 _docs/phases/phase-00/evidence/E27
```

E28 uses the same compilation command with `E28/main.swift` and an `e28` output executable; it takes no argument. Builds, once each for Debug and Release:

```sh
xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView \
  -configuration <Debug-or-Release> -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/mpqv-review16/build build
```

No print tasks or printers were created or changed; nothing printed on paper, installed or committed; no system preferences, accounts or version-control state changed. Temporary output is under `/private/tmp/`.

## Acceptance criteria

“Code” assesses conformance within the documented limits. “Execution” distinguishes my independent checks from historical evidence and pending practical checks. Unchanged criteria retain report 09's assessments; none becomes practically verified merely because this re-review approves the software.

| Criterion | Code | Execution / evidence |
| --- | --- | --- |
| QUEUE-001-AC01 | PASS | NOT TESTED real window; E03 partial; code unchanged. |
| QUEUE-001-AC02 | PASS | NOT TESTED real window; descending job-ID rule and counts unchanged; E03/E08. |
| QUEUE-001-AC03 | PASS | CANNOT VERIFY exclusion experimentally without another user; my-jobs query unchanged. |
| QUEUE-001-AC04 | PASS | NOT TESTED real-window latency; polling unchanged, E13/E15 indirect. |
| QUEUE-001-AC05 | PASS | NOT TESTED real rows; active-only thumbnails unchanged, E13/E17 partial. |
| QUEUE-001-AC06 | PASS | NOT TESTED no-printer/service-error states; unchanged. |
| QUEUE-001-AC07 | PASS | NOT TESTED independently; E26/internal review 04 support fallback, real printer deletion pending. |
| PREV-001-AC01 | PASS | K1 synthetic content/warning path PASS within D34; real fetch/window not rerun, E01–E03 partial. |
| PREV-001-AC02 | PASS | NOT TESTED controls/shortcuts in a window; unchanged. |
| PREV-001-AC03 | PASS | PASS for retained E27 synthetic formats and concatenation; full format range and real window not tested. K1's former FAIL resolved. |
| PREV-001-AC04 | PASS | PASS for E27 undecodable/rejected TIFF cases; historical E22 covers empty/none-readable inputs. Missing-job fetch/window not rerun. K1's former FAIL resolved. |
| PREV-001-AC05 | PASS | CANNOT VERIFY new runtime/disk-retention result; transfer code unchanged, E01/E04 partial. |
| PREV-001-AC06 | PASS | PASS synthetic problem collection and document-number prefix; warning banner NOT TESTED visually. D34 limitation explicit. |
| JOB-001-AC01 | PASS | NOT TESTED independently; immediate cancellation code unchanged; E06/E15 partial. |
| JOB-001-AC02 | PASS | NOT TESTED real pending pause/resume; E14/E20 indirect. |
| JOB-001-AC03 | PASS | NOT TESTED printing race; current-state guard unchanged. |
| JOB-001-AC04 | PASS | NOT TESTED independent scheduler/physical order; E08 historical. |
| JOB-001-AC05 | PASS | NOT TESTED independently; guard unchanged, E13 canceled-job simulation. |
| JOB-001-AC06 | PASS | NOT TESTED real reprint/dialogs; E07 does not demonstrate plain Restart-Job printing. |
| JOB-001-AC07 | PASS | NOT TESTED independently; ownership and per-job recheck unchanged; E09/E23 partial. |
| JOB-001-AC08 | PASS | NOT TESTED independently; E23 stale confirmation, window notice pending. |
| I18N-001-AC01 | PASS | Catalog/placeholder structure PASS; windows/meaning/native Turkish NOT TESTED. L3 optional. |
| I18N-001-AC02 | PASS | PASS for bundle selection in external report 09; unchanged resources/languages, app preference-list launches not tested. |
| I18N-001-AC03 | PASS | NOT TESTED restart/persistence independently; unchanged, E12 partial. |
| I18N-001-AC04 | PASS | PASS: all 86 translatable keys have nl/tr units and exact source-key coverage. |
| APP-001-AC01 | PASS | PASS fresh Debug/Release bundle inspection. |
| APP-001-AC02 | PASS | PASS inspected development team/runtime/capabilities; chain/export not validated. |
| APP-001-AC03 | PASS | CANNOT VERIFY all live operations in the actual app sandbox; historical harness evidence remains partial. |
| APP-001-AC04 | NOT APPLICABLE | NOT TESTED; App Store submission outside phase delivery, RM-002. |

## Phase assessment and pending work

- **PASS:** the reviewed code and specification now agree for the former K1 case, with the recorded D34 technical limit. No unresolved material contradiction found in this scope.
- **PASS for the supplied record:** D1–D34 and implementation defaults are distinguished. Exhaustive completeness of unavailable original conversations remains CANNOT VERIFY, as before; this is not a new blocker.
- **PASS:** evidence separates historical checks, current synthetic results and unperformed practical acceptance.
- **PASS:** both builds and translation completeness independently verified.
- **PASS:** internal approval followed by this external approval. Administrative closure remains the executor's responsibility.

All 11 practical checks in the validation plan remain open, not just the partial-preview banner and native Turkish checks highlighted in recent internal reports. These include real-window appearance and interaction, page/zoom controls, hardware/printing actions, reprinting, language relaunch, deletion dialogs, no-printer/error states, printer deletion, another user's jobs and App Store acceptance. Date/time locale handling remains unverified.

Existing technical assumptions remain: separate CUPS state queries and mutations are not atomic; priority updates are non-atomic and capped at 100; TIFF inspection has documented finite traversal limits; successful platform decoding is not a guarantee of undamaged original pixels (D34). Proposed ADRs/defaults and L3 remain with the user. Phase 01's thumbnail zoom is not implemented or approved by this review.

Next: the executor records this approval and closes phase 00 according to the working agreements, preserving practical checks and optional points. The next free phase-00 report number is 17 if another report is needed. No new implementation or internal re-review is required merely to record this approval.
