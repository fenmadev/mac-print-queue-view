# Phase 02 — report 04

- Start (UTC): 2026-11-16T22:46:37Z (clock, `date -u` at the start of the review).
- End (UTC): 2026-11-16T22:47:41Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the review.
- Scope: independent internal re-review of phase 02 round 2 ([executor report 03](03-executor-claude-Opus-5.5.md)): resolution of findings S1, M1–M3 and O1–O3 of [internal review 02](02-internal-claude-Opus-5.5.md), any new problem introduced by the round, and whether the approval-relevant state of round 1 (icon, About window, build-number mechanism, APP-001 v2, inventory D45–D47, roadmap, validation plan, README, architecture overview, model log) still holds. Triggered by the executor's request for the internal gate.
- Revision: git, baseline commit `0d6a388`; round 1 and internal review 02 staged as the review baseline (`git diff --cached`: 34 files). Round 2 diff (unstaged, 10 files): `AboutPanel.swift`, README, `Tools/increase-build-number.sh`, model log, phase plan, evidence register, reviewer guideline, architecture overview, APP-001, inventory. Untracked: executor report 03, `evidence/E04/` (`run.sh`, `results.txt`). The working agreements were read directly.
- Verdict: APPROVED.

I did not implement or fix anything; the only file I wrote is this report.

## Checks

`BUILD_NUMBER` was `5` (SHA-256 `f0b5c2c2211c8d67ed15e75e656c7862d086e9245420892a7de62cd9ec582a06`) before my builds; my Debug and Release builds raised it to 7; I wrote `5` back afterwards and confirmed the same SHA-256 and that `git status` shows `BUILD_NUMBER` only as staged (`A `), with no working-tree change. Builds went to a temporary derived-data folder outside the project. No print job, printer or system setting was touched; nothing was installed, staged or committed.

| Check | Result |
| --- | --- |
| SHA-256 of `Tools/increase-build-number.sh`, `AboutPanel.swift`, `Tools/make-icon.swift`, E02 `main.swift`, E04 `run.sh`, `icon_1024.png` | All match the values in the evidence register (E01, E04 footer) |
| E04 harness re-run (`sh _docs/phases/phase-02/evidence/E04/run.sh`) | Output byte-identical to `E04/results.txt` (9 cases) |
| Script read (`Tools/increase-build-number.sh`) | Surrounding whitespace (including CR) trimmed per line; any inner space or second line rejected; leading zeros stripped after validation (`0`/`000` → 1); missing file → error with counter and Info.plist untouched. Invoked by Xcode directly (`"$SRCROOT/Tools/increase-build-number.sh"`, executable, `#!/bin/sh`) |
| Debug build, `xcodebuild … -configuration Debug build` | Succeeded; no `warning:` or `error:` lines; "Build number 6"; `CFBundleVersion` 6 |
| Release build | Succeeded; no `warning:` or `error:` lines; "Build number 7"; `CFBundleVersion` 7 |
| Bundle values of both builds (APP-001-AC01, E05) | Display name "Mac Print Queue View", `nl.fenma.MacPrintQueueView`, version 1.0, `MPQVVersionDate` 2026-11-16, "Copyright © 2026 Fenma IT", `ITSAppUsesNonExemptEncryption` false — matches E05 |
| Signature and entitlements (APP-001-AC02, E05) | `codesign --verify --strict --deep` valid; entitlements App Sandbox, printing, `get-task-allow` only; team `8RQJ83KNF9` |
| `AboutPanel.show()` | `NSApplication.shared.activate()` (macOS 14+, matches the deployment target 14.0); options unchanged, so E02 needs no re-run |
| String Catalog | Not changed in round 2 |
| References (D25) | No added line in the staged or unstaged diff, nor the untracked files, names the working agreements, editor settings, build output or home-folder paths |
| Round 1 state | Staged diff unchanged in substance by round 2; APP-001 v2, inventory D13/D45–D47, roadmap RM-009–RM-011 (in progress, linked to the plan and APP-001), validation plan checks 18–19 and README read again: consistent with the code and builds |

The executor report mentions the accepted `appintentsmetadataprocessor` line; my clean builds did not log it at all, which is not a problem.

### Criteria

| Criterion | Assessment |
| --- | --- |
| APP-001 behaviour 2 / D45 (icon) | PASS (asset unchanged since review 02); practical check 18 open |
| APP-001 behaviour 3 / D46, APP-001-AC05 | PASS (code, E02); real window in Dutch and Turkish is practical check 19 |
| APP-001 rule 5 / D47 (build number) | PASS (Debug and Release raise it before signing; archive verified in review 02) |
| APP-001-AC01 | PASS |
| APP-001-AC02 | PASS (development-signed); App Store signing not done |
| APP-001-AC03, AC04 | NOT APPLICABLE to this round |
| Localization completeness | PASS (unchanged) |
| Sandbox and entitlements | PASS |

## Status of the findings of review 02

| Finding | Status |
| --- | --- |
| S1 (check builds change `BUILD_NUMBER`, not documented for reviewers) | Resolved. The reviewer guideline, "Safe checks", now says every build raises `BUILD_NUMBER`, that a check build notes and writes back the value and says so in its report, and builds into a temporary folder; the external-reviewer agreement sends the external reviewer to that guideline. README says the same for anyone building. The rule is recorded in the plan as an implementation default for the user to confirm. |
| M1 (inventory phase sentence) | Resolved: "D38–D44 in phase 01, D45 and later in phase 02". |
| M2 (APP-001 traceability and last run) | Resolved: AC01 cites the new E05 instead of E03; AC05 states what the user actually reported; "Last run" has a phase 02 row. See N1 for a remaining small gap on AC02. |
| M3 (architecture overview, README layout) | Resolved: `AboutPanel.swift` row, About item in the app entry row, icon note, "Version and build number" section (matches the project settings); README `Tools/` line names the build-number script. |
| O1 (archive not in evidence) | Resolved: E03 cites the archive checked by review 02. |
| O2 (script robustness notes) | Resolved: inner spaces now rejected, leading zeros handled (E04); gaps, simultaneous builds and `CURRENT_PROJECT_VERSION` documented in README and plan; App Store build-number option recorded in the plan for RM-002. |
| O3 (`activate(ignoringOtherApps:)`) | Resolved: `activate()`. |

## New findings

### N1 — minor: APP-001-AC02 traceability does not cite E05

The evidence register lists E05 as evidence for APP-001-AC01 and AC02 (entitlements and team of the phase 02 builds), but the AC02 row in APP-001 still cites only E16 and "the inspected development-signed build" of phase 00. Add phase 02 E05 to the AC02 row. Not blocking.

### N2 — optional: script comment slightly broader than the behaviour

The script comment and E04 say spaces and line ends "around the number" are ignored; trailing blank lines are, but a leading blank line (`"\n5"`) makes the build stop with the error. This fails safely; adjust the wording or leave it.

## Pending practical checks

- Practical check 18 (icon in Dock, Finder, Launchpad, App Switcher, About window, light and dark, all sizes): Dock and About window reported by the user; the rest not reported.
- Practical check 19 (real About window in English, Dutch and Turkish with the installed build number).
- App Review guideline 5.2.5 (similarity to Apple's Print Center icon): only Apple's review can settle it (RM-002).
- User confirmation of the plan's implementation defaults (check builds restore `BUILD_NUMBER`; gaps and simultaneous builds; App Store build-number option) and the open questions (version scheme, copyright text); not blocking.

## Verdict

APPROVED: S1, M1–M3 and O1–O3 of review 02 are resolved; round 2 introduced no blocking or should-fix problem; the approval-relevant state of round 1 still holds. N1 (minor) and N2 (optional) may be addressed in a later round or at phase closure; this software approval does not claim the pending practical checks.
