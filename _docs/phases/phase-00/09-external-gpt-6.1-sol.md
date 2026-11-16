# Phase 00 — report 09

- Start (UTC): 2026-11-16T16:46:19Z (clock; first recorded clock sample after opening the review brief).
- End (UTC): 2026-11-16T16:51:59Z (clock).
- Role: external.
- Agent/model: `gpt-6.1-sol`.
- Model verification: the reviewer's current session metadata explicitly identifies `gpt-6.1-sol`; checked at the first recorded clock sample, 2026-11-16T16:46:19Z.
- Scope: external review after internal report 08; current phase 00 as a whole, including the prior external findings, subsequent code fixes, D1–D33, reports 01–08, evidence E01–E26, specifications, roadmap and the phase 01 draft. Both working agreements were read directly.
- Revision: no version control (D33). Reviewed the actual project-root files and the changed-file lists in executor reports 01, 03, 05 and 07. The former source subfolder and git folder are absent. Files modified after internal review 08 began are that report itself and the plan/model-log entries recording its approval; no subsequent product change was found. A temporary SHA-256 manifest of 61 project files was used to check that reviewed files remained unchanged during this review.
- Verdict: CHANGES REQUESTED.

I did not implement or fix anything; the only project file I wrote is this report.

## Verdict and internal gate

The internal gate is met: report 06 approves the substantive state together with reviews 02/04; report 08 approves round 4. The later plan and model-log updates record that approval and do not introduce a new implementation round.

The previous whole-document preview failures, empty-input handling, stale-removal safeguard and warning terminology have been addressed. Both builds and localization checks pass. One remaining preview-completeness case was independently reproduced: a multipage TIFF with an unreadable second image is displayed as one page with no warning. This conflicts with the documented promise that partial content is never presented as complete. Finding K1 requires disposition before external approval.

No practical, paper or App Store acceptance is claimed.

## Findings

### K1 — should fix — unreadable content within a multipage image can still disappear without warning

**References:** `MacPrintQueueView/PreviewBuilder.swift:29`, `:96`, `:135`–`:145`; PREV-001 rule 3 (a partial preview is never shown as complete), rule 4 (multi-frame images become multiple pages), AC01/AC03/AC04, and phase acceptance that specs and code do not contradict each other.

The new warning collection operates at document level. A returned non-empty PDF is considered successfully rendered. `pdfFromImage` relies on ImageIO's reported image count, silently continues when a frame cannot be created, and returns whatever pages it obtained. Neither that path nor the caller reports incomplete content within one image document.

**Current-source reproduction, no CUPS access:**

1. Create a TIFF containing two 16×16 images (red, then blue), using `CGImageDestinationCreateWithData(..., "public.tiff", 2, ...)` and `CGImageDestinationAddImage` twice. Finalize it. The unmodified file produces two preview pages with no problems.
2. Follow the TIFF's first IFD's next-IFD pointer to its second IFD. In that second IFD only, set the SHORT value of Compression tag 259 to 65535. Keep both IFDs and the rest of the file intact. This makes the second image's compression unsupported/unreadable.
3. Pass the resulting bytes as one `JobDocument(format: "image/tiff")` to the actual `PreviewBuilder.makePreview`.
4. ImageIO reports one image for this malformed input. The app returns a successful one-page preview and `problems == []`. The second image disappears without any notice.

Observed output:

```text
Unmodified TIFF: source count=2, decodes=[true, true]
Unmodified TIFF preview: pages=2, problems=[]
Modified TIFF: source count=1, decodes=[true]
Modified TIFF preview: pages=1, problems=[]
```

Temporary fixtures retained for the executor to inspect safely:

- `/private/tmp/mpqv-review09-harness/two.tiff`
  - SHA-256: `71f03f359fc38d79e44958ad3f44ab0d9cc6281c8e6fc96dfe2bf86c14655908`
- `/private/tmp/mpqv-review09-harness/bad-compression.tiff`
  - SHA-256: `931a99de3d6e872b9c197cae32a7d968ad71661ad2326d76df69f283cdd48155`
- The synthetic harness is `/private/tmp/mpqv-review09-harness/main.swift`; its `check` executable accepts a fixture path. It calls PreviewBuilder only, never a CUPS method. These temporary paths are not permanent project evidence.

**Required result:** this known incomplete input must produce an explicit warning or an unavailable-preview error, rather than an apparently complete one-page preview. Address both decoder-reported truncation and the explicit per-frame `continue` paths; merely throwing when `CGImageSourceCreateImageAtIndex` returns nil does not cover this fixture, because ImageIO already reports a smaller image count. Preserve the user's D22 choice to show readable content with a warning where that can be established. If the platform cannot establish completeness for some malformed formats, record the technical limit and seek an explicit product disposition rather than retaining an unqualified completeness promise.

Verify with the two fixtures above and the existing text-plus-unreadable-document case; a synthetic check is sufficient and must not print. The ordinary whole-document fix works; this finding concerns content loss inside one document, not a failure to implement the earlier test cases.

No other new blocking or should-fix finding was established. Existing H1–H2 and J1–J4 remain non-blocking as recorded in the plan and internal reviews; no historical report was edited here.

## Checks and evidence

| Check actually performed | Result |
| --- | --- |
| Current files, working agreements, specs, reports 01–08 and evidence | Read directly. Current product code, report change lists, ownership guards, action routes, preview warning propagation, roadmap and draft next phase inspected. No version-control command used. |
| Debug and Release builds from the current project root | Both `BUILD SUCCEEDED`, zero compiler warnings and errors. Each clean build emits the accepted `appintentsmetadataprocessor` metadata-extraction diagnostic. Builds ran with normal development signing outside the restricted tool sandbox; no account/provisioning action or app launch. |
| Bundle inspection | Both configurations: name `Mac Print Queue View`, ID `nl.fenma.MacPrintQueueView`, version 1.0 (1), minimum macOS 14.0, copyright as specified, encryption false and AppIcon included. |
| Signature/entitlement inspection | Release reports team `8RQJ83KNF9`, hardened runtime and exactly app-sandbox, print and get-task-allow. Certificate authority is unavailable to the restricted inspector; certificate-chain and distribution export acceptance are not claimed. |
| Catalog and extracted source keys | 86 catalog keys, 85 translatable; every nl/tr unit translated; no placeholder mismatch. Debug `.stringsdata` yields exactly the same 86 keys. The mutating sync tool was not run. |
| Preferred bundle languages | Independently reproduced E21 against the fresh Debug bundle: de,nl,en→nl; de,tr→tr; fr,de→en; en-GB,nl→en; nl-BE→nl; tr→tr. No preferences changed and no app launch. |
| Whole-document preview fixes, current source | Text→1 page/no problems; text + undecodable image→1 page plus document-2 warning; empty text→“The document is empty”; text + empty + text→2 pages plus document-2 warning; unreadable image + PostScript→none-readable error listing both reasons. Matches E22. |
| Multipage-image boundary checks | Valid TIFF→2 pages. K1 fixture→1 page/no warning. Exploratory GIF truncation did not produce a partly decoded frame case; moving a TIFF strip offset beyond EOF still returned two image objects and did not demonstrate the explicit skip branch. These inconclusive probes are not presented as passing corruption/completeness tests. |
| Removal safeguard and printer fallback | Inspected actual code: single and bulk removal both call `purgeJobIfFinished`; the current job state is queried immediately before purge, and skipped removals produce a notice. Printer choice is resolved from the fresh printer list before history is requested. E23/E25/E26 and internal review 04 support runtime behaviour; no live scheduler operations were rerun by this reviewer. |
| Relative Markdown links | No broken relative file links in 34 project Markdown files, excluding code fences. Working-agreement paths were inspected directly as well. |
| Files after internal review | Only report 08 and approval-recording plan/model-log updates are newer than its start. No unreviewed later source/spec change found. Final manifest comparison checks that review work did not alter project inputs. |

Build command, once per Debug/Release configuration:

```sh
xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView \
  -configuration <Debug-or-Release> -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/mpqv-review09-build build
```

Synthetic compilation:

```sh
swiftc -module-cache-path /private/tmp/mpqv-review09-harness/cache \
  MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
  /private/tmp/mpqv-review09-harness/main.swift \
  -o /private/tmp/mpqv-review09-harness/check
```

No jobs or printers were created, canceled, held, resumed, reordered, purged or reprinted; no system settings changed; nothing installed; no version-control action. Temporary compilation, fixtures and logs are under `/private/tmp/`.

## Acceptance criteria

“Code” assesses specification conformance by inspection and the synthetic cases. “Execution” assesses independent execution in this review, with partial results stated explicitly. Historical E-items are executor-reported evidence, not newly repeated results; their deleted harnesses and earlier code revisions remain an explicit limitation.

| Criterion | Code | Execution / evidence |
| --- | --- | --- |
| QUEUE-001-AC01 | PASS | NOT TESTED in the window; printer filtering, default/fallback and counts wired. E03 partial. |
| QUEUE-001-AC02 | PASS | NOT TESTED in the window; sort and limit match the now-explicit descending job-number rule. E03/E08 partial. |
| QUEUE-001-AC03 | PASS | CANNOT VERIFY cross-user exclusion experimentally; my-jobs=1 and ownership checks present; E10 single-user only. |
| QUEUE-001-AC04 | PASS | NOT TESTED timing; refresh then two-second sleep. Query time adds latency; E13/E15 indirect. |
| QUEUE-001-AC05 | PASS | NOT TESTED real rows; thumbnails limited to active jobs, completed row has none. E13/E17 partial. |
| QUEUE-001-AC06 | PASS | NOT TESTED empty-printer/service-error overlays; no configuration change performed. |
| QUEUE-001-AC07 | PASS | NOT TESTED independently; fresh printer selection precedes history lookup. E26 and internal review 04 demonstrate nonexistent-selection fallback; real printer deletion pending. |
| PREV-001-AC01 | FAIL | K1 returns incomplete original content without notice in the synthetic case. Real job fetch/window not rerun. |
| PREV-001-AC02 | PASS | NOT TESTED interaction; page/zoom controls and shortcuts wired to PDFKit. |
| PREV-001-AC03 | FAIL | Valid two-page TIFF passes, but K1 loses its unreadable second image without notice. Text rendering and multi-document concatenation pass the reproduced cases. |
| PREV-001-AC04 | FAIL | Whole-document unreadable/empty/unsupported cases PASS synthetically; K1 unreadable content instead yields unqualified success. Real-window messages not tested. |
| PREV-001-AC05 | PASS | CANNOT VERIFY new runtime/disk-retention result; code uses private 0600 O_EXCL file, immediately unlinked. E01/E04 historical. |
| PREV-001-AC06 | PASS | PASS for reproduced whole-document rendering/problem collection; warning banner NOT TESTED visually. K1 limits the broader rule-3 completeness guarantee within individual image documents. |
| JOB-001-AC01 | PASS | NOT TESTED independently; immediate cancel routes and ownership guards intact. E06/E15 held jobs only. |
| JOB-001-AC02 | PASS | NOT TESTED real pending-job pause/resume; E14/E20 remain indirect. |
| JOB-001-AC03 | PASS | NOT TESTED printing race; pending-only enablement and current-state re-query present. |
| JOB-001-AC04 | PASS | NOT TESTED independently; priority algorithm unchanged, E08 historical. Paper order/real drag pending. |
| JOB-001-AC05 | PASS | NOT TESTED independently; current waiting-state guard present, E13 canceled-job simulation. |
| JOB-001-AC06 | PASS | NOT TESTED real reprint or dialogs; confirmation routes match spec. E07 never demonstrated the current plain Restart-Job path printing. |
| JOB-001-AC07 | PASS | NOT TESTED independently; own-job selection and fresh per-job purge guard present. E09/E23 partial; bulk purge not run. |
| JOB-001-AC08 | PASS | NOT TESTED independently; skipped-result notice and per-job re-query inspected. E23 simulates stale confirmation; real-window notice pending. |
| I18N-001-AC01 | PASS | NOT TESTED windows/meanings; independent catalog and placeholder checks PASS. Turkish native review pending. |
| I18N-001-AC02 | PASS | PASS for bundle selection, E21 reproduced; running app not launched per preference list. |
| I18N-001-AC03 | PASS | NOT TESTED restart/persistence independently; implementation and E12 partial evidence inspected. |
| I18N-001-AC04 | PASS | PASS: all 85 translatable keys have nl/tr translations; source/catalog equality. |
| APP-001-AC01 | PASS | PASS: fresh Debug/Release bundle inspection. |
| APP-001-AC02 | PASS | PASS for inspected development team identifier, runtime and capability entitlements; certificate chain/export not validated. |
| APP-001-AC03 | PASS | CANNOT VERIFY all operations in the app sandbox independently; E04/E06/E07/E20/E23 are qualified harness evidence. |
| APP-001-AC04 | NOT APPLICABLE to phase delivery | NOT TESTED; submission deferred to RM-002. |

## Phase acceptance and remaining work

| Phase criterion | Assessment |
| --- | --- |
| Current behaviour fully specified without contradictions | FAIL: K1 contradicts the preview completeness guarantee. |
| Explicit decisions recorded and defaults distinguished | PASS for the supplied record D1–D33 and defaults; completeness against unavailable original conversation is CANNOT VERIFY. D33 clearly explains current layout and absence of version control. |
| Evidence honest; no visual/paper/App Store acceptance claimed | PASS: scope limits, prior code revisions and harness limitations are explicit; earlier warning terminology corrected. |
| Both builds clean of compiler warnings/errors; no missing translation | PASS, independently reproduced. |
| Internal then external approval | Internal PASS; external FAIL pending K1. |

All 11 practical checks in the validation plan remain open: actual window appearance, controls, partial-preview banner, hardware/job actions, reprinting, relaunch and native-language review, dialogs, empty/error states, printer deletion, another user's jobs and App Store acceptance. Date/time locale handling also remains unverified.

Technical limits already recorded remain: state queries and mutations are separate scheduler requests; pause/reorder/removal cannot offer atomic exclusion of later state transitions. Priority updates are non-atomic and capped at 100. Proposed ADRs and implementation defaults require user confirmation; this reviewer does not approve product choices on the user's behalf. RM-001 remains planned for phase 01 and is not part of this review's implementation scope.

Next: executor addresses K1 and records its evidence/disposition, then obtains independent internal re-review before the next external review. The next free report number is 10. Existing non-blocking historical points need not be rewritten merely to address K1.
