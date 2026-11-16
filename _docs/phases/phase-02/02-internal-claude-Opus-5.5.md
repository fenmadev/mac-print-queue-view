# Phase 02 — report 02

- Start (UTC): 2026-11-16T22:39:13Z (clock, `date -u` at the start of the review).
- End (UTC): 2026-11-16T22:42:54Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the review.
- Scope: independent internal review of phase 02 round 1 ([executor report 01](01-executor-claude-Opus-5.5.md)): RM-009 / D45 new app icon, RM-010 / D46 About window (APP-001-AC05), RM-011 / D47 build number raised with every build; APP-001 v2, inventory (D13, D45–D47), validation plan, roadmap, README, model log, phase plan, evidence register E01–E03 and the icon proposals. Triggered by the executor's request for the internal gate.
- Revision: git, baseline commit `0d6a388`; nothing staged. Round diff (unstaged): Xcode project, the seven AppIcon PNGs, `Localizable.xcstrings`, `MacPrintQueueViewApp.swift`, `Tools/make-icon.swift`, README, model log, roadmap, APP-001, validation plan, inventory. Untracked: `BUILD_NUMBER` (5), `MacPrintQueueView-Info.plist`, `MacPrintQueueView/AboutPanel.swift`, `Tools/increase-build-number.sh`, `_docs/phases/phase-02/`. The working agreements were read directly.
- Verdict: CHANGES REQUESTED.

I did not implement or fix anything; the only file I wrote is this report.

## Checks

All builds went to a temporary derived-data folder under `/private/tmp`. `BUILD_NUMBER` was 5 (SHA-256 `f0b5c2c2…582a06`) before my builds; my four builds raised it to 9; I restored it to `5` afterwards and confirmed the same SHA-256 and an unchanged `git status`. No print job, printer or system setting was touched; nothing was installed, staged or committed.

| Check | Result |
| --- | --- |
| SHA-256 of `Tools/increase-build-number.sh`, `AboutPanel.swift`, `Tools/make-icon.swift`, E02 `main.swift` | Match the values in the evidence register |
| Debug build (clean), `xcodebuild … -configuration Debug build` | Succeeded; 0 warnings, 0 errors; log order `ProcessInfoPlistFile` → `PhaseScriptExecution Increase Build Number` → `CodeSign` (debug dylib, preview dylib, app) → `Validate`; "Build number 6"; built Info.plist `CFBundleVersion` 6, `MPQVVersionDate` 2026-11-16, copyright, display name; `codesign --verify --strict --deep` valid |
| Debug build (incremental, same derived data) | `ProcessInfoPlistFile` ran again, then the script ("Build number 7"), then signing; `CFBundleVersion` 7; signature valid |
| Release build | Succeeded; 0 warnings; `CFBundleVersion` 8; `MPQVVersionDate`, `ITSAppUsesNonExemptEncryption` false, bundle identifier and name as in APP-001-AC01; team `8RQJ83KNF9`; signature valid |
| Archive (`xcodebuild … archive`, generic macOS, archive path in the temporary folder) | Succeeded; "Build number 9"; app in the archive and the archive's `ApplicationProperties` both `CFBundleVersion` 9; signature valid; only the accepted `appintentsmetadataprocessor` line |
| Entitlements (APP-001-AC02) | `MacPrintQueueView.entitlements` unchanged since the baseline; built app: App Sandbox, printing, `get-task-allow` (development) only |
| Icon (D45) | `Tools/make-icon.swift` compiled and run into the temporary folder: output byte-identical to `icon_1024.png` (SHA-256 `4b7a40aa…755219`, as in E01); `sips` of that output to 16–512 byte-identical to the six other PNGs; all PNGs have the right pixel size; minimum alpha of `icon_1024.png` is 1.0 (fully opaque, full-bleed); `Contents.json` unchanged; built app has `AppIcon.icns` and `Assets.car`. Viewed: printer, sheet, magnifying glass, green light, graphite face with light rim |
| About panel (D46, AC05) | Code read: name, "Version %@", "Build %@" (so AppKit adds no prefix), description and "Version date: %@" as credits, long date in the app's language, invalid date shown as is; menu item replaces `.appInfo`. Evidence image E02 viewed: matches AC05 in English, Dutch and Turkish, light and dark |
| String Catalog | 111 keys, none missing Dutch or Turkish, none stale; a copy synced with `xcstringstool` against the stringsdata of my Debug build is identical to the catalog |
| Specs and documentation | APP-001 v2, inventory, roadmap, validation plan, README, plan, evidence register and model-log row read against the code; findings below. No project file names the working agreements or local folders (D25) in the round's changes |

### Criteria

| Criterion | Assessment |
| --- | --- |
| APP-001 behaviour 2 / D45 (icon) | PASS for the asset catalog and built app; practical check 18 open |
| APP-001 behaviour 3 / D46, APP-001-AC05 | PASS (code, off-screen render E02, catalog); the real window in Dutch and Turkish is part of practical check 19 |
| APP-001 rule 5 / D47 (build number) | PASS: Debug, incremental Debug, Release and archive each raise the number, write `CFBundleVersion` before signing, signature valid |
| APP-001-AC01 | PASS for my phase 02 Debug and Release builds (see M2 on how the evidence records it) |
| APP-001-AC02 | PASS (development-signed); App Store signing not done |
| APP-001-AC03, AC04 | NOT APPLICABLE to this round (unchanged) |
| Localization completeness | PASS |
| Sandbox and entitlements unaffected | PASS (`ENABLE_USER_SCRIPT_SANDBOXING = NO` affects only the build script, not the app sandbox) |

## Findings

### S1 — should fix: a reviewer's or check build now changes a tracked project file, and the review rules do not say so

The reviewer guideline (`_specs/agent-guidelines/reviewer.md`, "Safe checks") says reviewers may build the app, and the external-reviewer agreement says the external reviewer does not change product files. Since D47 every build of the app target writes `BUILD_NUMBER` in the repository, so an external review that builds (as earlier phases did) silently changes a tracked file and leaves it in the round's diff. Only this review's brief mentions the restore step; the plan and executor report note the consequence but no project file tells a reviewer what to do. Record it where reviewers read it (reviewer guideline, and README for anyone building): a build raises `BUILD_NUMBER`; reviewers note its value before building and restore it afterwards (or another explicit rule). Whether the external-reviewer agreement also needs a line is the executor's call.

### M1 — minor: inventory sentence on when decisions were made is out of date

`_specs/inventory.md` line 19: "D1–D37 during the work recorded as phase 00, D38 and later in phase 01." D45–D47 were made in phase 02. Suggest "D38–D44 in phase 01, D45 and later in phase 02".

### M2 — minor: APP-001 traceability and "Last run" overstate or lag the phase 02 evidence

- AC01 row cites "E03 (build number)", but AC01 does not cover the build number, and the coverage "Full for the inspected … Release builds of … phase 02" is not backed by a recorded inspection of name, bundle identifier, copyright and `ITSAppUsesNonExemptEncryption` in phase 02 (E01 covers the icon, E03 the build number). The values are correct (verified in this review), but the evidence should record them or the coverage should say what phase 02 inspected.
- AC05 row says "the user confirmed the real About window in English", while the evidence register records the user's confirmation as "everything works (the new icon in the Dock and the About window)". Align the wording with what the user actually confirmed.
- The "Last run" table still lists only phase 00.

### M3 — minor: architecture overview and README layout do not mention the new parts

`_specs/architecture/index.md` (components table) has no row for `AboutPanel.swift`, and the `MacPrintQueueViewApp.swift` row does not mention the replaced About menu item; the build-number mechanism (`BUILD_NUMBER`, `Tools/increase-build-number.sh`, `MacPrintQueueView-Info.plist`) is not in the architecture overview. The README layout line for `Tools/` lists the other scripts but not the build-number script.

### O1 — optional: archive behaviour is stated but not in the evidence

APP-001 rule 5, D47, RM-011 and README say an archive raises the build number; E03 covers install, Debug and Release only. This review verified an archive (build 9 in the app and in the archive's properties, signature valid); the executor may add an archive run to E03 or cite this report.

### O2 — optional: robustness notes on the build-number script

Each is acceptable as is; record or harden as preferred:
- The number is consumed even when a later step (signing, validation) fails, so gaps can appear.
- Two builds at the same time (Xcode and `Tools/install-release.sh`) can read the same value and produce the same number.
- A value with leading zeros (`08`) fails in shell arithmetic (octal); the script then stops the build with an error, which is safe.
- For App Store distribution later (RM-002): Xcode's distribution option to manage the build number can change `CFBundleVersion` in the exported app, so it would no longer match `BUILD_NUMBER`; worth deciding then.
- `CURRENT_PROJECT_VERSION` stays 1, so Xcode's target settings show build 1 while built apps carry another number (documented in the plan; a comment near the setting or in the README would help).

### O3 — optional: `activate(ignoringOtherApps:)`

`AboutPanel.show()` uses `activate(ignoringOtherApps:)`, which Apple marks for future deprecation; with the macOS 14 deployment target, `NSApp.activate()` is available. No warning today (0 warnings in both configurations).

## Pending practical checks

- Practical check 18 (icon in Dock, Finder, Launchpad, App Switcher, About window, light and dark, all sizes): the user confirmed Dock and About window; the rest not reported.
- Practical check 19 (real About window in English, Dutch and Turkish with the installed build number).
- App Review guideline 5.2.5 (similarity to Apple's Print Center icon): only Apple's review can settle it (RM-002).

## Verdict

CHANGES REQUESTED: S1 must be resolved (or explicitly declined by the user); M1–M3 should preferably be fixed in the same round; O1–O3 are optional. The code, icon, About window and build-number mechanism themselves are sound; no blocking finding.
