---
id: APP-001
title: Name, icon, sandbox, signing and App Store readiness
type: feature
status: draft
version: 2
---

# APP-001 — Name, icon, sandbox, signing and App Store readiness

## Purpose

Give the app a clear identity and make it ready for free distribution through the Mac App Store (D8–D11, D45, D46).

## Behaviour for the user

1. The app is called "Mac Print Queue View" in the window title, menu bar, Dock, Finder and About window (D11).
2. The app icon shows a dark printer with a green status light on a graphite rounded square with a light rim, a printed sheet coming out of it and a magnifying glass over that sheet, in the style of the macOS Print Center icon (D45; until phase 02 a stack of paper sheets with a magnifying glass, D13).
3. The About window (app menu → "About Mac Print Queue View") shows the icon, the name, "Version 1.0 (Build n)" with the current build number, the description "Shows what is actually being printed from the macOS print queue.", "Version date: November 16, 2026" and "Copyright © 2026 Fenma IT"; the labels, the description and the date follow the app's language (D46).
4. The app is free in the Mac App Store (D8).
5. The app has one main window (no "New Window" command) and quits when its last window is closed; with the Settings window still open, closing the main window does not quit the app. Settings open in a separate Settings window (⌘,).

## Functional rules

1. The app runs in the App Sandbox with only the printing entitlement (`com.apple.security.print`); it does not need access to files, network or other resources.
2. The app uses only public macOS APIs (libcups, PDFKit, AppKit, SwiftUI).
3. The app is signed with team FENMA IT B.V. (`8RQJ83KNF9`) (D9).
4. The app declares that it uses no non-exempt encryption (`ITSAppUsesNonExemptEncryption = NO`) (D10).
5. Bundle identifier `nl.fenma.MacPrintQueueView`; minimum macOS 14; version 1.0; version date 2026-11-16. Every build — Debug, Release or archive — raises the build number (`CFBundleVersion`) by one: the build phase "Increase Build Number" (`Tools/increase-build-number.sh`) raises the last number kept in `BUILD_NUMBER` and writes it into the built app's Info.plist before signing (D47). The version (`MARKETING_VERSION`) and version date (`MPQV_VERSION_DATE`, `yyyy-MM-dd`, in the Info.plist as `MPQVVersionDate`) are build settings of the app target; a version date that is not a valid date is shown as it is.
6. The source code is proprietary ("All rights reserved", Copyright Fenma IT) in a private repository (D8).

## User interface

Not applicable beyond name, icon and About window. The About window is the standard macOS About panel with the options above (centred, secondary-colour description and version date).

## Permissions

App Sandbox with `com.apple.security.print`; hardened runtime.

## Edge cases

- The first launch after a change of signing identity shows macOS's "differs from previously opened versions" prompt once; this is expected.
- A development build is rejected by Gatekeeper's distribution assessment (`spctl`); only App Store or Developer ID builds pass it.

## Error handling

Not applicable.

## Acceptance criteria

### APP-001-AC01

- **Given** the built app.
- **When** its bundle is inspected.
- **Then** the name is "Mac Print Queue View", the bundle identifier is `nl.fenma.MacPrintQueueView`, the copyright is "Copyright © 2026 Fenma IT", the icon is included and `ITSAppUsesNonExemptEncryption` is false.

### APP-001-AC02

- **Given** the built app.
- **When** its signature and entitlements are inspected.
- **Then** it is signed by team `8RQJ83KNF9` and its only capability entitlements are the App Sandbox and printing (plus `get-task-allow` in development-signed builds; an App Store export removes it).

### APP-001-AC03

- **Given** the sandboxed app.
- **When** it runs.
- **Then** it can list printers and jobs, fetch documents and perform the job actions without any further entitlement.

### APP-001-AC04

- **Given** a Release build archived with Xcode.
- **When** it is uploaded to App Store Connect and reviewed by Apple.
- **Then** it is accepted and published free of charge. (Not yet attempted.)

### APP-001-AC05

- **Given** the built app, in English, Dutch or Turkish.
- **When** the About window is opened from the app menu.
- **Then** it shows the app icon, "Mac Print Queue View", the version and build with translated labels ("Version 1.0 (Build n)", "Versie 1.0 (Build n)", "Sürüm 1.0 (Derleme n)", n the build number of that build), the translated description, the version date as a long date in that language and the copyright.

## Observed, yet to be confirmed

- App Store metadata (description, screenshots, privacy policy, category) has not been prepared; App Store submission has not been attempted.
- One main window that quits the app when the last window closes is an implementation default.

## Related specifications

[I18N-001](I18N-001-localization.md), [validation plan](../getting-started/validation.md).

## Technical references

`MacPrintQueueView.entitlements`; build settings in `MacPrintQueueView.xcodeproj`; app icon in `Assets.xcassets`, generated by `Tools/make-icon.swift` and `Tools/update-app-icon.sh`; About window in `AboutPanel.swift` and the app menu in `MacPrintQueueViewApp.swift`; `MacPrintQueueView-Info.plist` (version date); `BUILD_NUMBER` and `Tools/increase-build-number.sh` (build number); `LICENSE.md`.

## Traceability

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| APP-001-AC01 | E16 (Info.plist values), E18 (icon, phase 00); phase 02 E01 (new icon), E05 (Info.plist values of the phase 02 Debug and Release builds) | Full for the inspected development-signed builds of phase 00 and phase 02 |
| APP-001-AC02 | E16 (codesign output) | Full for the inspected development-signed build; App Store distribution signing not yet done |
| APP-001-AC03 | E04, E06, E07, E20, E23 (sandboxed harness bundles with the app's entitlements file: reads, document fetch, cancel, restart, priority, hold, release, purge, state re-check before purge) | Partial: the harness bundles used the app's entitlements but another bundle identifier; `Restart-Job` only on a canceled job |
| APP-001-AC04 | — | None: not attempted |
| APP-001-AC05 | phase 02 E02 (About panel rendered from a copy of the built app, English, Dutch and Turkish, light and dark) | Rendered off screen with the app's options; after being asked to check the Dock and the About window of the installed build 2, the user reported "everything works" (2026-11-16); the real window in Dutch and Turkish remains part of practical check 19 |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | `xcodebuild`, `codesign -dvv`, `PlistBuddy` (see evidence) | See evidence items | Executor (Claude), phase 00 |
| 2026-11-16 | `xcodebuild` (Debug, Release), `PlistBuddy`, `codesign`, About panel rendering, build-number script harness (phase 02 E01–E05) | See phase 02 evidence items | Executor (Claude), phase 02 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the state reached in phase 00 |
| 2 | 2026-11-16 | Phase 02: new icon (D45), About window with version, build, description and version date (D46), AC05; build number raised with every build (D47) |
