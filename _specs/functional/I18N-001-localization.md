---
id: I18N-001
title: English, Dutch and Turkish with an in-app choice
type: feature
status: draft
version: 1
---

# I18N-001 — English, Dutch and Turkish with an in-app choice

## Purpose

Make the app usable in English, Dutch and Turkish (D12). English is the base language of the app and the code (D7).

## Behaviour for the user

1. By default the app follows the macOS language preferences: it uses the first language in the user's preferred-language list that it supports (English, Dutch or Turkish). If none of the listed languages is supported, it uses English. For example, "German, Dutch, English" gives Dutch.
2. In **Settings… (⌘,)** the user can choose **System Language**, **English**, **Nederlands** or **Türkçe**. Each language is listed in its own language.
3. After a change, the settings window says that the new language is used after a restart and offers **Restart Now**.
4. The choice is the same setting as the per-app language in System Settings → General → Language & Region → Applications.

## Functional rules

1. Every user-facing text of the app is translated into Dutch and Turkish; no translation may be missing.
2. Placeholders (numbers, names) are preserved in every translation.
3. The app name "Mac Print Queue View" and the copyright owner are not translated.
4. Technical details from CUPS in error messages are shown untranslated after the translated explanation.
5. Dates and times follow the effective language.
6. The language choice is stored as `AppleLanguages` in the app's own preferences; "System Language" removes that override.

## User interface

A Settings window with a language picker and a footer that either explains "System Language" or shows the restart notice with "Restart Now".

## Permissions

None.

## Edge cases

- No supported language in the preference list: English. A supported language further down the list wins over English as the fallback.
- The user changes the language twice before restarting: the last choice applies.
- The user sets a per-app language in System Settings: the picker shows it.

## Error handling

If the app cannot be relaunched automatically, it stays open and the user can restart it manually.

## Acceptance criteria

### I18N-001-AC01

- **Given** the effective language is English, Dutch or Turkish.
- **When** the user uses the app.
- **Then** all app-owned texts are in that language, with placeholders and meanings preserved and no raw keys.

### I18N-001-AC02

- **Given** "System Language" is selected.
- **When** the app resolves its language from macOS's preferred-language list.
- **Then** it uses the first supported language in that list (English, Dutch or Turkish), or English if the list contains none of them.

### I18N-001-AC03

- **Given** the user selects a language in Settings.
- **When** the app is restarted (with "Restart Now" or manually).
- **Then** the app uses the selected language; choosing "System Language" again returns to following macOS.

### I18N-001-AC04

- **Given** the String Catalog of the app.
- **When** the translations are checked.
- **Then** every translatable key has a Dutch and a Turkish translation.

## Observed, yet to be confirmed

- The language change taking effect only after a restart is an implementation choice ([ADR-004](../decisions/ADR-004-language-override.md)).
- The Turkish translations were written by the executor and have not yet been reviewed by a native speaker.
- Rule 5 (dates and times follow the effective language) relies on the system's locale handling and has not been checked.

## Related specifications

[QUEUE-001](QUEUE-001-queue-overview.md), [PREV-001](PREV-001-print-preview.md), [JOB-001](JOB-001-job-actions.md), [APP-001](APP-001-app-identity-and-distribution.md).

## Technical references

String Catalog `MacPrintQueueView/Localizable.xcstrings`; `Tools/sync-strings.sh [derived-data-path]`; [ADR-004](../decisions/ADR-004-language-override.md).

## Traceability

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| I18N-001-AC01 | E11 (compiled translations per language, placeholders formatted) | Partial: real window not checked in each language |
| I18N-001-AC02 | E11 (single-language lists), E21 (multi-language lists) | Full for the bundle's language selection; the running app was not started under each preference list |
| I18N-001-AC03 | E12 (choice stored and applied after restart in a harness bundle) | Partial: "Restart Now" relaunch not exercised |
| I18N-001-AC04 | E11 (catalog completeness check) | Full at the time of the check; must be repeated after text changes |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | Ad hoc Swift harnesses and catalog checks (see evidence) | See evidence items | Executor (Claude), phase 00 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the behaviour built in phase 00 |
