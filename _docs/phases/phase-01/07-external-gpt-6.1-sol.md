# Phase 01 — report 07

- Start (UTC): 2026-11-16T21:39:52Z (clock; first recorded clock sample after opening the review brief).
- End (UTC): 2026-11-16T21:44:52Z (clock).
- Role: external.
- Agent/model: `gpt-6.1-sol`.
- Model verification: current reviewer session metadata explicitly identifies `gpt-6.1-sol`; checked at the first recorded clock sample, 2026-11-16T21:39:52Z.
- Scope: phase 01 following internal review 06; all phase changes relative to phase 00, including RM-001 and RM-003–RM-008, the ten new feature criteria, changed existing behaviour, tools, specs, evidence E01–E08 and reports 01–06. Both working agreements were read directly.
- Revision: HEAD `55933afc44caf8b4754dab9861ac4fdd958db444` (phase 00). Rounds 1–2 are staged as the baseline; round 3 is unstaged. Inspected `git status`, `git diff`, `git diff --cached`, combined changes against HEAD and the two untracked reports 05/06 directly. No other non-ignored untracked input found. A temporary SHA-256 manifest of 106 input files was used for final unchanged-input verification.
- Verdict: CHANGES REQUESTED.

I did not implement or fix anything; the only project file I wrote is this report.

## Verdict and gate

The internal gate is met: internal review 04 approves round 2 and review 06 explicitly approves the current round 3. The later plan/model-log entries record that approval.

The builds, translation completeness, pure selection/reordering logic and synthetic preview checks pass. However, the new scripts have three concrete defects affecting their documented safety or behaviour, and the bulk-pause implementation does not provide the per-job freshness required by the phase plan. Findings R1–R4 require changes. The optional points of internal review 06 remain non-blocking.

This review does not claim real-window, printer-administration, installation or paper acceptance.

## Findings

### R1 — should fix, high — `remove` bypasses the test-printer identity guard

**Location:** `Tools/test-printer.sh:112`–`:115`; README lines 165–166; RM-008 and the phase plan's promise to refuse a printer with another address.

The `remove` command checks only whether a queue named `MPQV_Testprinter` exists, then issues `sudo lpadmin -x MPQV_Testprinter`. It never reads or validates the queue's device URI. A queue with that name but a real printer address is therefore deleted, including its jobs, despite the documented refusal rule. The existing URI guard in `check_printer` is not on this path.

**Safe reproduction:** ran the actual script with temporary PATH stubs for `lpstat`, `sudo`, `lsof` and `lpoptions`. `lpstat -p` reported an existing queue and the configured URI stub was `socket://192.0.2.10:9100`. `remove` exited 0 and the mock sudo log contained:

```text
lpadmin -x MPQV_Testprinter
```

No real command requiring privileges ran; no queue was deleted. Notably, the URI query was unnecessary to the current path, because it is never performed.

**Required:** verify the queue is the expected safe test printer before destructive removal. Reject unexpected addresses without issuing a deletion. Use a read-only identity check here; do not reuse a helper that first migrates/reconfigures the printer merely to validate deletion. Specify how the documented legacy test URI is handled. Add an isolated test proving an unrelated URI yields no destructive command.

### R2 — should fix, medium — a rejecting queue is mistaken for an accepting queue

**Location:** `Tools/test-printer.sh:83`–`:85`; RM-008 (the script ensures the test printer accepts jobs).

`grep -q "accepting requests"` also matches the negative CUPS text `not accepting requests`. Consequently, an existing stopped test queue that rejects jobs passes `check_printer` without `cupsaccept`; `create` can return success while the queue still rejects jobs, and `jobs` then fails to submit.

**Safe reproduction:** actual `create` path with the same PATH stubs: existing stopped queue, correct `socket://127.0.0.1:59100` URI, no listener, not shared, and `lpstat -a` returning:

```text
MPQV_Testprinter not accepting requests since now
```

The command exited 0 with “MPQV_Testprinter already exists”; the mock sudo log was empty. `cupsaccept` was not requested.

**Required:** distinguish the positive and negative acceptance states precisely, and fail closed if the state cannot be read. Add isolated accepting/rejecting/error cases. This does not require creating or changing a real printer.

### R3 — should fix, medium — install destination is interpreted as a regular expression

**Location:** `Tools/install-release.sh:42`, `:46`, `:47` (and the signal at `:45`); RM-006, whose contract is to quit only the copy at the destination and leave other copies alone.

Canonicalizing `DEST` fixes relative/symlink spellings, but the script interpolates the path unescaped into `pgrep -f`'s regular expression. Valid destination characters such as `.`, `[`, `(` and `+` can change matching or make the expression invalid. The fixed `.app` suffix is also unescaped. A process from a different directory may match and receive SIGTERM; a valid destination with invalid regex syntax may produce an error that `|| true` hides, letting the script replace a still-running copy.

**Safe pattern reproduction:** the actual expanded ERE

```text
^/private/tmp/mpqv-release.v1/Mac Print Queue View.app/Contents/MacOS/
```

matches this different destination's executable text:

```text
/private/tmp/mpqv-releaseXv1/Mac Print Queue View.app/Contents/MacOS/Mac Print Queue View
```

Verified with `grep -E`, without installing or signaling an app. A live `pgrep` probe against a reviewer-created dummy child returned an environment error (exit 3), so I do not claim live process-selection verification. The ERE interpretation and missing escaping are directly established by code and pattern matching.

**Required:** compare canonical executable paths literally or correctly escape the entire path used in the process query. Distinguish a query failure from “no matching process” and stop before replacement on uncertainty. Test regex-significant destination names and a similarly named different destination without signaling user processes or installing into real application locations.

### R4 — should fix, medium — bulk pause uses one increasingly stale snapshot for every job

**Location:** `MacPrintQueueView/QueueStore.swift:272`–`:290`; phase plan RM-003 (“each is re-checked with cupsd right before pausing”), D17 and JOB-001-AC11.

`pause(_:)` reads all active states once, builds `pausable`, then sequentially sends Hold-Job to every ID in that list. The second and later jobs are not rechecked immediately before their own operation. If an earlier Hold-Job/connection is slow or fails, a later candidate may have started printing before its Hold-Job is issued. It is still paused, and is not included in the already-started count because that count also came from the initial snapshot.

JOB-001 rule 9 honestly discloses the growing snapshot-to-action gap, but that disclosure does not implement the stronger per-job freshness promise in the phase plan. This is additional avoidable staleness beyond the unavoidable interval between one job's last query and its mutation.

**Basis:** static review of the actual code. I did not provoke a printing transition or send Hold-Job to real jobs. Historical E04 covers resume and selection; multi-pending pause and failure paths remain unexecuted.

**Required:** refresh each candidate's state immediately before issuing that candidate's hold, skipping/reporting jobs that are now printing, while preserving the continue-after-failure behaviour. Retain the honest limit that query and hold are separate requests. Verify safely with a fake client: while processing A, change B from pending to printing; B must never receive Hold-Job. Do not weaken D17 or the phase plan to approve the batch snapshot.

## Checks actually performed

| Check | Result and limitations |
| --- | --- |
| Repository and review scope | Staged and unstaged changes read separately; untracked reports 05 and 06 read directly; HEAD and working-agreement changes understood. Both approvals cover the current material scope. No staging or commit. |
| Specs → code → evidence | Read the phase plan, decisions D38–D44, feature changes, affected Swift code, tools, README, architecture/scenarios/validation changes, evidence register and internal/executor reports. Historical live results remain attributed to their authors. |
| E01 pure logic | Compiled current QueueLayout with the retained harness. 63 PASS checks, ALL PASS, output byte-identical to E01/results.txt. Covers seven zoom steps, grid dimensions, gathered moves, grid insertion/rearrangement, normalization and deselection after refresh. |
| E02 synthetic documents | Compiled actual CUPSClient, PreviewBuilder, QueueLayout and retained E02 main, invoking only PreviewBuilder. ALL PASS: portrait 514×728 and landscape 728×514 thumbnails; first-page copy with correct whole-document page count; multi-document and partial-preview cases. PNG byte counts need not be stable. |
| Debug and Release | Both fresh builds succeed; zero errors and compiler warnings; one accepted appintentsmetadataprocessor metadata-extraction warning each. No app launch, provisioning or account action. |
| Localization | 106 extracted Debug keys equal 106 catalog keys, 105 translatable. All Dutch/Turkish units translated; placeholders match by argument index/type. No catalog mutation or sync script execution. |
| Release entitlements | Exactly app-sandbox, print and development get-task-allow; no new capability introduced. |
| Script checks | Both scripts pass `zsh -n`. Isolated actual-script probes prove R1/R2; isolated ERE matching supports R3. No install script execution, administrator command or real printer action. |
| Markdown links | No broken relative file links in inspected project Markdown, code fences excluded. |
| Whitespace | Unstaged `git diff --check` passes. Staged check reports five trailing spaces in E01/results.txt on lines printing empty selections; these are generated output, not a product defect or approval blocker. |
| Input integrity | Final SHA-256 comparison confirms all 106 recorded review inputs unchanged. Only this report is added by the reviewer. |

Build command, once for each configuration:

```sh
xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView \
  -configuration <Debug-or-Release> -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/mpqv-phase01-review07/build build
```

E01 uses `swiftc -O` with QueueLayout and its retained main; E02 additionally compiles CUPSClient and PreviewBuilder, as documented in each harness. Reviewer outputs and mock commands are under `/private/tmp/mpqv-phase01-review07/`. The mocks replace every printer/privilege helper used by the two probe paths; they only return text or append requested arguments to a temporary log. They never delegate to real CUPS/admin tools.

I did not run E04/run.sh or E07/run.sh, because they create and mutate scheduler jobs. E05/E06/E08 off-screen integration and live CUPS order results remain historical evidence; I do not present them as independent reruns. Nothing printed; no existing user process was signaled, installed app replaced, printer configured, print job changed or system preference modified. The unsuccessful process-query experiment used only a reviewer-created dummy child, which was then terminated.

## Acceptance assessment

“Code” assesses conformance by source inspection and the specific safe reproductions. “Execution” distinguishes my checks from historical evidence. PASS in code does not imply practical acceptance.

| Criterion / requirement | Code | Execution and evidence |
| --- | --- | --- |
| QUEUE-001-AC08, seven thumbnail steps | PASS | E01/E02 PASS independently; E03/E05 historical rendering/column measurements. Real buttons, shortcuts, display limits and restart remain NOT TESTED. |
| QUEUE-001-AC09, multiple selection rules | PASS | E01 PASS; E04/E08 historical integration, including a discriminating round-1 negative control. Actual clicks/header-highlight behaviour NOT TESTED. |
| QUEUE-001-AC10, visible draggable divider | PASS | Separate mark view, hit-test passthrough and thick style inspected. E05/E06 historical; real drag/appearance NOT TESTED. |
| QUEUE-001-AC11, deselect departed queued job | PASS | E01 pure rule PASS; refresh records previous queue before applying D44. E04 historical; real window NOT TESTED. |
| PREV-001-AC07, preview grid | PASS | E01 dimensions and E02 page-content preparation PASS. Source caps at 16, displays total note, first-page views and per-job errors/warnings. Real grid/controls NOT TESTED; E04 historical store evidence. |
| PREV-001-AC08, order numbers | PASS | Enumerated row-major index + 1 and bottom-trailing badge inspected; actual visual result NOT TESTED. |
| JOB-001-AC09, confirm cancellation of several | PASS | Ownership-filtered count, snapshot, dialog and continue-after-error loop inspected. E04 historical; actual dialog and Don't Cancel NOT TESTED independently. |
| JOB-001-AC10, gathered moves/list drag | PASS | E01 PASS including D39. E07 reports actual held-job scheduler ordering; no live move rerun. |
| JOB-001-AC11, pause/resume several | FAIL | R4: per-job state freshness required by the phase plan is absent for bulk pause. Resume now continues after failure by code review; real multi-pending pause and error branches NOT TESTED. |
| JOB-001-AC12, grid reorder | PASS | E01 includes the exact A E C B D example; moveInGrid preserves unselected slots and reuses apply's current-state guard. E07 historical, real drag NOT TESTED. |
| RM-006, install script | FAIL | R3 violates destination-specific process handling. Historical temporary-destination tests do not cover regex-significant paths. Real install NOT TESTED here. |
| RM-008, test-printer script | FAIL | R1/R2 reproduced without system changes. create/printing/complete/remove with admin rights remain NOT TESTED; README now correctly identifies unconfirmed scheduler assumptions. |

Affected existing criteria were checked for regressions: QUEUE-001-AC03 (own-job queries), QUEUE-001-AC05 (completed rows still lack thumbnails), PREV-001-AC02 (single-preview controls hidden for a grid), PREV-001-AC06 (warnings propagated into grid tiles), JOB-001-AC01 (one cancel remains immediate), JOB-001-AC05 (moved-job state guard) and I18N-001-AC04 (catalog completeness) are PASS by code inspection; AC04 localization is also independently executed. JOB-001-AC03 retains the single-job guard but the extended bulk-pause obligation is subject to R4. Other phase-00 criteria are unchanged and retain report 16's software assessment and practical limitations.

## Phase-level assessment and open items

| Phase acceptance | Assessment |
| --- | --- |
| Specifications extended for the requested behaviour | PASS for recorded scope and criteria; R4 is an implementation/plan discrepancy, not permission to relax the requirement. |
| Pure zoom/grid/reorder logic checked from actual source | PASS, independently reproduced. |
| Reordering verified safely with no unrelated queued jobs | PASS as historical E07 evidence; live scheduler actions NOT TESTED by this reviewer. |
| Multi-job actions safely checked | Partial historical coverage; FAIL for the bulk-pause freshness obligation (R4); no claim of fully tested pause/error handling. |
| Rendering/column/crash regression evidence | PASS as qualified E03/E05/E06 evidence; actual window remains NOT TESTED. |
| Debug/Release and translations | PASS, independently reproduced. |
| Internal then external approval | Internal PASS; external FAIL pending R1–R4. |

Practical validation items 12–17 remain open: zoom and window sizing, actual selection/range/header highlights, grid and order numbers, both cancellation choices, list/grid dragging, multi-pending pause, divider behaviour across layouts/screens, administrator-driven test-printer commands and installation into the real destination. Earlier phase-00 practical checks also remain open. O1–O2 of internal review 06 remain optional traceability/history improvements.

Implementation defaults remain subject to user confirmation (downward gathering, thumbnail render size, column/window policies, mixed-selection toolbar choice and grid interaction). AppKit split-view structure is a documented platform assumption; CUPS query/mutation pairs remain non-atomic, and priority ordering has the existing cap. That unavoidable single-operation race does not remove the need to address R4's avoidable batch staleness.

Next: executor addresses R1–R4 with safe isolated regression evidence, writes report 08, and obtains an independent internal re-review before requesting another external review. Preserve the pending practical checks; do not perform unsafe operations to satisfy this report.
