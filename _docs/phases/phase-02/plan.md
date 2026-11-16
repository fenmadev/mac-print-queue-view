# Phase 02 — new app icon, About window and build number

Date (UTC): 2026-11-16T23:21:44Z (created 2026-11-16T22:22:00Z)
Status: **closed** — [external review 05](05-external-gpt-6.1-sol.md) APPROVED after [internal review 04](04-internal-claude-Opus-5.5.md) APPROVED round 2 (round 2 resolved S1, M1–M3 and O1–O3 of [internal review 02](02-internal-claude-Opus-5.5.md)). Left open: N1 (minor, APP-001-AC02 traceability does not cite E05) and N2 (optional, script comment wording) of internal review 04, practical checks 18–19 (partly), the implementation defaults below and the open questions for the user.
Baseline: git commit `0d6a388` (phase 01). At closure all phase changes are staged (after report 05); commit on the user's instruction.

## Requests

1. **RM-009 — New app icon** ([roadmap](../../roadmap.md); user, 2026-11-16): the icon should look more like the macOS Print Center icon (a printer on a graphite rounded square). Four proposals were made; the user chose **A** (**D45**, [inventory](../../../_specs/inventory.md)), which replaces D13. The user asked to keep all proposals in this phase to see the alternatives.
2. **RM-010 — About window with version number** (user, 2026-11-16): the macOS About window, laid out as in the user's other app BlueClap: icon, name, "Version … (Build …)", a one-line description, the version date and the copyright (**D46**).

3. **RM-011 — Build number goes up with every build** (user, 2026-11-16): also when deploying to production (**D47**).
## Icon proposals

All in [icon-proposals/](icon-proposals/): [overview](icon-proposals/proposals-overview.png) (current icon and A–D at 256, 96, 64, 48, 32 and 16 points, on light and dark) and each proposal at 1024 pixels; [proposals.swift](icon-proposals/proposals.swift) draws them.

| | Proposal | Idea |
| --- | --- | --- |
| **A** (chosen) | Graphite printer + magnifying glass | Close to Print Center; the magnifying glass over the printed sheet stands for what the app does. |
| B | Graphite printer + queue | Three sheets with coloured headers stand in the paper tray as the queue; less legible at small sizes. |
| C | Blue printer + magnifying glass | The blue background of the phase 00 icon with a printer; continuity with the earlier icon. |
| D | Graphite printer, preview sheet | Minimal, blue status light; closest to Print Center. |

Proposals A and C were recommended because App Review guideline 5.2.5 rejects apps whose icon is confusingly similar to an Apple product; the magnifying glass gives A its own feature.

## Scope

### RM-009 (D45)

- `Tools/make-icon.swift` draws proposal A; `Tools/update-app-icon.sh` regenerated all sizes in `Assets.xcassets/AppIcon.appiconset`. No other change to the asset catalog.
- Full-bleed (reported by the user after installing, 2026-11-16: the Dock and the About window did not show the right icon): macOS 26 and later show an icon with its own rounded outline, transparent margin and drop shadow reduced on a grey plate. The icon now fills the whole canvas (the light rim to the edges, no outline or shadow of its own) so that macOS applies its own shape; the printer and magnifying glass are scaled 1.1 so the handle stays inside that shape. The proposal files show the earlier, pre-shaped drawing of the same design.

### RM-010 (D46)

- The app menu's "About Mac Print Queue View" opens the standard macOS About panel with options set by `AboutPanel.options` (`MacPrintQueueView/AboutPanel.swift`): the name, "Version 1.0" and "(Build 1)" with the labels in the app's language, a one-line description ("Shows what is actually being printed from the macOS print queue.") and "Version date: November 16, 2026" (long date in the app's language), followed by the copyright from the Info.plist.
- The version date is the build setting `MPQV_VERSION_DATE` (`yyyy-MM-dd`), next to `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; `MacPrintQueueView-Info.plist` (beside the project, outside the synchronized source folder) puts it in the Info.plist as `MPQVVersionDate`, merged with the generated Info.plist. A value that is not a valid date is shown as it is.
- New strings ("About %@", "Version %@", "Build %@", the description, "Version date: %@") translated into Dutch and Turkish.

### RM-011 (D47)

- Build phase "Increase Build Number" (after Resources, always run, the built Info.plist declared as input so it runs after the Info.plist is written) calls `Tools/increase-build-number.sh`: reads the last number from `BUILD_NUMBER` (repository root, tracked; refuses anything but a whole number), adds one, sets `CFBundleVersion` in the built Info.plist and writes the new number back. Signing comes after it. Script sandboxing is off for the app target (`ENABLE_USER_SCRIPT_SANDBOXING = NO`), as the script writes `BUILD_NUMBER` in the source folder. `CURRENT_PROJECT_VERSION` stays 1 and is overwritten in every built app.
- Consequence: every build, also the executor's check builds, changes `BUILD_NUMBER`.
- A new build number also makes macOS refresh its icon cache, which the user needed: after the full-bleed fix the Dock still showed the old icon. Build 2 was installed with `Tools/install-release.sh`, the user's icon cache was cleared and the Dock restarted.

### Round 2 (internal review 02)

- S1: the reviewer guideline and the README say that a check build notes `BUILD_NUMBER` and writes the value back afterwards.
- M1–M3: inventory phase sentence, APP-001 traceability and last run (new E05), architecture overview and README layout.
- O1–O3: archive recorded in E03 (from internal review 02); the build-number script ignores spaces only around the number and drops leading zeros (E04); README notes on gaps, simultaneous builds and `CURRENT_PROJECT_VERSION`; `NSApp.activate()`.

### Out of scope

App Store work (RM-002); changing the version number or the copyright text (open questions below).

## Implementation defaults (not user decisions; to be confirmed)

- Check builds (reviewers, and the executor when building only to check) write `BUILD_NUMBER` back afterwards; builds meant for use (the user's builds in Xcode, `Tools/install-release.sh`, an archive) keep the raised number.
- A failed build may use up a number; two simultaneous builds can get the same number.
- For the App Store (RM-002): Xcode's distribution option to manage the build number would change `CFBundleVersion` in the exported app; to decide when publishing.

## Acceptance checks for this phase

- APP-001 updated (icon, About window, version date).
- The icon generator draws proposal A full-bleed; the asset catalog compiles (`AppIcon.icns` in the built app); the user sees the new icon in the Dock and the About window (confirmed by the user, 2026-11-16).
- The About panel rendered from a copy of the built app in English, Dutch and Turkish, light and dark ([evidence E02](evidence/E02/about-panels.png)).
- Debug and Release builds with zero errors and zero compiler warnings; no untranslated string.
- Practical checks 18–19 of the [validation plan](../../../_specs/getting-started/validation.md) for the user.
- Internal review `APPROVED`, then external review `APPROVED`.

## Rounds

| Round | Report | Status |
| --- | --- | --- |
| 1 | [01 executor](01-executor-claude-Opus-5.5.md), [02 internal](02-internal-claude-Opus-5.5.md) | CHANGES REQUESTED (S1 should fix; M1–M3 minor; O1–O3 optional) |
| 2 | [03 executor](03-executor-claude-Opus-5.5.md), [04 internal](04-internal-claude-Opus-5.5.md) | APPROVED (N1 minor, N2 optional; left open) |
| — | [05 external](05-external-gpt-6.1-sol.md) | APPROVED — phase closed |

## Open questions

Asked on 2026-11-16, not answered; not blocking, the current values stay.

1. Version number: it stays 1.0 for now (the build number follows D47). BlueClap uses three parts (0.3.0); the user may choose another number or scheme.
2. Copyright: the About window shows "Copyright © 2026 Fenma IT" (APP-001 behaviour 3); BlueClap shows "© 2026 FENMA". Kept unless the user decides otherwise.
