# Phase 02 — report 01

- Start (UTC): 2026-11-16T22:15:44Z (clock: creation time of the first file of the round, the icon proposal generator, after reading the roadmap).
- End (UTC): 2026-11-16T22:38:51Z (clock).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor session (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the round.
- Scope: round 1 of phase 02, everything the user asked for in this phase until the user's signal to start the report: RM-009 new app icon in the style of Print Center (D45, replaces D13), RM-010 About window as in the user's app BlueClap (D46), RM-011 build number raised with every build (D47). The user asked for "phase-03"; only phases 00 and 01 existed, so this is phase 02.
- Revision: git, baseline commit `0d6a388` (phase 01). Nothing staged; `git diff` plus `git status` show the whole round. Untracked: `BUILD_NUMBER`, `MacPrintQueueView-Info.plist`, `MacPrintQueueView/AboutPanel.swift`, `Tools/increase-build-number.sh`, `_docs/phases/phase-02/` (plan, icon proposals, evidence, this report). Changed: Xcode project, the seven icon PNGs, `Localizable.xcstrings`, `MacPrintQueueViewApp.swift`, `Tools/make-icon.swift`, README, roadmap, APP-001, validation plan, inventory.
- Verdict: READY FOR REVIEW.

## Changes

**User decisions** ([inventory](../../../_specs/inventory.md)): D45 (icon proposal A of four; D13 marked superseded), D46 (About window laid out as in BlueClap), D47 (every build raises the build number, production builds included).

**Icon (RM-009).** Four proposals drawn and kept in [icon-proposals/](icon-proposals/) on the user's request, with their generator. `Tools/make-icon.swift` draws A; all asset sizes regenerated with `Tools/update-app-icon.sh`. After the user reported the wrong icon in the Dock and the About window, the drawing was made full-bleed (light rim over the whole canvas, no outline or drop shadow of its own; printer and magnifying glass scaled 1.1), because macOS 26+ shows a pre-shaped icon reduced on a grey plate. The proposal files keep the earlier pre-shaped drawing.

**About window (RM-010).** `AboutPanel.swift` (new): `options(info:locale:)` builds the standard panel's options — name; "Version 1.0" and "Build n" with translated labels (so AppKit adds no prefix of its own); credits with the description "Shows what is actually being printed from the macOS print queue." and "Version date: …" as a long date in the app's language (an invalid value is shown as it is); centred, secondary colour. `MacPrintQueueViewApp.swift` replaces the app menu's About item with one that calls `AboutPanel.show()`. The version date is the build setting `MPQV_VERSION_DATE` (2026-11-16), placed in the Info.plist as `MPQVVersionDate` by `MacPrintQueueView-Info.plist` beside the project (outside the synchronized source folder, merged with the generated Info.plist). Five new strings translated into Dutch and Turkish.

**Build number (RM-011).** Build phase "Increase Build Number" (after Resources, always run, the built Info.plist declared as input for ordering) runs `Tools/increase-build-number.sh`: reads `BUILD_NUMBER` (refuses anything but a whole number), adds one, sets `CFBundleVersion` in the built Info.plist and writes the number back; signing follows. `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the app target, because the script writes `BUILD_NUMBER` in the source folder. `CURRENT_PROJECT_VERSION` stays 1 and is overwritten in every built app.

**Installation and icon cache.** Build 2 installed in the user's Applications folder with `Tools/install-release.sh`; the earlier builds in the local build folder unregistered from Launch Services; the user's icon cache (`com.apple.iconservices` in the user cache folder) cleared; `iconservicesagent` and the Dock restarted. The user then confirmed that everything works.

**Specs and documentation.** APP-001 v2 (behaviour 2 and 3, rule 5, user interface, AC05, technical references, traceability, history), inventory (D45–D47, D13 superseded, APP-001 v2), roadmap (RM-009–RM-011 in progress), validation plan (phase 01 marked closed, phase 02 row, practical checks 18–19), README (build number, version and date settings), [phase plan](plan.md), [evidence register](evidence/README.md).

## Checks

| Check | Result |
| --- | --- |
| E01 icon | First version byte-identical to proposal A; all sizes in the built `Assets.car`; the pre-shaped version shown on a grey plate by macOS (seen with `NSWorkspace.icon(forFile:)`), replaced by the full-bleed version |
| E02 About panel | Rendered from a copy of the built Debug app (build 4) in English, Dutch and Turkish, light and dark: name, translated version and build labels, description, version date, copyright, system-shaped icon ([image](evidence/E02/about-panels.png)) |
| E03 build number | Install build 2 (installed `CFBundleVersion` 2, signature valid); final Debug build 4, Release build 5 |
| Debug and Release builds | Both succeed; 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` line (2026-11-16T22:37:08Z) |
| String Catalog | 111 keys, 110 translatable, 0 missing, 0 stale; the catalog diff only adds the five new keys |
| User | Confirmed on 2026-11-16 after installing build 2: the new icon shows in the Dock and the About window, "everything works" |

No check printed on paper or touched print jobs or printers.

## Open points

- Unanswered user questions (not blocking; current values kept): version number 1.0 or another scheme (BlueClap uses 0.3.0); copyright "Copyright © 2026 Fenma IT" or "© 2026 FENMA" as in BlueClap.
- `BUILD_NUMBER` changes with every build, also the reviewers' and the executor's check builds; the value at commit time is whatever the last build left.
- The system-wide icon cache was not cleared (needs an administrator password); not needed after the user's confirmation.
- Practical checks 18–19: Finder, Launchpad, App Switcher and Dutch and Turkish in the real About window were not reported separately.
- App Review guideline 5.2.5 (similarity to Apple's Print Center icon) can only be settled by Apple's review (RM-002).
