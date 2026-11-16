# Architecture

## Overview

A single-window SwiftUI app for macOS 14+ written in Swift 6, sandboxed, without helper tools or extensions. It talks only to the local CUPS scheduler (`cupsd`) over the Unix socket `/private/var/run/cupsd`, using the public libcups API (`import CUPS`).

```
SwiftUI views ──► QueueStore (@MainActor, @Observable) ──► CUPSClient (blocking libcups calls, off the main thread)
      │                     │                                        │
      │                     └──► PreviewBuilder (document → PDF / thumbnail)       └──► cupsd (IPP over the local socket)
      └──► PDFPreview (PDFKit view + controller)
```

## Components

| File | Responsibility |
| --- | --- |
| `CUPSClient.swift` | Thin synchronous layer over libcups: printers, own jobs (`my-jobs`), documents, and the job operations. Defines `Printer`, `PrintJob`, `JobStatus`, `JobDocument`, `CUPSError`. Opens one connection per call. |
| `PreviewBuilder.swift` | Converts job documents (PDF, images, plain text) into PDF data and first-page thumbnails; reports unsupported formats. |
| `QueueStore.swift` | App state: printers, queue, completed jobs, selection (one or several jobs), preview and the blocks of the grid preview, thumbnails, pending confirmations and errors; 2-second refresh loop; action logic for one or several jobs with re-checks against cupsd. |
| `QueueLayout.swift` | Pure logic without CUPS or views: thumbnail size steps and job column widths, grid layout for several jobs, selection rules, gathered moves and reordering in the grid. |
| `ContentView.swift` | Three-column window, job list sections, toolbars, context menus, confirmation dialogs, single preview and the grid preview of several jobs with drag and drop; column support (thick, visible divider through AppKit's split view; job column width following the thumbnail step; widening the window when the columns no longer fit). |
| `JobRows.swift` | Row views for queued and completed jobs, thumbnail, status badge, section header, row action buttons. |
| `PDFPreview.swift` | PDFKit wrapper and a controller for paging and zooming; a fitted single-page view for the grid blocks. |
| `LanguageSettings.swift`, `SettingsView.swift` | Language choice stored as `AppleLanguages`, Settings window, relaunch. |
| `MacPrintQueueViewApp.swift` | App entry point, main window, Settings scene, the app menu's About item (opens `AboutPanel`), quit after the last window closes. |
| `AboutPanel.swift` | The About window: options for the standard AppKit About panel (name, version and build with translated labels, description, version date as a long date in the app's language); pure `options(info:locale:)`. |
| `Localizable.xcstrings` | String Catalog with English (source), Dutch and Turkish. |
| `Assets.xcassets` | App icon (full-bleed, drawn by `Tools/make-icon.swift`; macOS applies the icon shape). |

## Version and build number

- Version: build setting `MARKETING_VERSION`; version date: build setting `MPQV_VERSION_DATE` (`yyyy-MM-dd`), put in the Info.plist as `MPQVVersionDate` by `MacPrintQueueView-Info.plist` (beside the project, merged with the generated Info.plist).
- Build number: the build phase "Increase Build Number" (after Resources, always run, the built Info.plist as input so it runs after the Info.plist is written, before signing) runs `Tools/increase-build-number.sh`, which raises the last number in `BUILD_NUMBER` (project root, tracked) and sets `CFBundleVersion` in the built app. `CURRENT_PROJECT_VERSION` stays 1 and is overwritten. Script sandboxing is off for the app target because the script writes `BUILD_NUMBER` (D47).

## CUPS operations used

| Purpose | IPP operation / API | Allowed for |
| --- | --- | --- |
| List printers | `CUPS-Get-Printers`, `cupsGetDefault2` | everyone |
| List jobs | `cupsGetJobs2(…, my-jobs = 1, …)` | own jobs |
| Number of documents | `Get-Job-Attributes` (`number-of-documents`) | owner |
| Fetch a document | `CUPS-Get-Document` via `cupsDoIORequest` | owner (or administrator) |
| Cancel | `Cancel-Job` (`cupsCancelJob2`, purge = 0) | owner |
| Remove from history | `Get-Job-Attributes` (`job-state`) re-check, then `Cancel-Job` with `purge-job` (`cupsCancelJob2`, purge = 1) only if the job is still finished | owner |
| Pause / resume | `Hold-Job` (`job-hold-until=indefinite`) / `Release-Job` | owner |
| Print again | `Restart-Job` | owner |
| Reorder | `Set-Job-Attributes` (`job-priority`) | owner |

The owner is identified by cupsd through the peer credentials of the local socket; no password is needed. See [phase 00 CUPS research](../research/phase-00-cups.md).

## Concurrency

All libcups calls are blocking and run in detached tasks; results cross to the main actor as `Sendable` values (`Data`, value types). `PDFDocument` objects are created on the main actor from PDF data. The refresh loop runs while the window's task is alive.

## Safety properties

- Read-only towards the queue except for explicit user actions.
- State-dependent actions (pause, reorder, permanent removal) re-read the current job state from cupsd immediately before acting. The re-check and the action are separate requests; a state change in between cannot be excluded.
- A preview that misses part of a job says so (warning with the missing documents).
- Documents are transferred through a private temporary file that is unlinked right after creation.

## Decisions

See [decisions](../decisions/index.md).
