---
id: PREV-001
title: Print preview of a job's content
type: feature
status: draft
version: 4
---

# PREV-001 — Print preview of a job's content

## Purpose

Show what is actually being printed: when the user selects a print job, the app immediately shows a preview of the job's document (D1).

## Behaviour for the user

1. The user selects a job in the queue or in the completed list. Without a selected job, the preview column says "No Job Selected — Select a print job to see what is being printed." and the window title is the app name.
2. The preview column shows "Fetching document from the queue…" and then the document.
3. Multi-page documents can be paged through (toolbar, ⌘↑/⌘↓ or scrolling) and zoomed (⌘= zoom in, ⌘- zoom out, ⌘0 zoom to fit, or pinch). The toolbar shows "Page x of y".
4. The window title shows the job title; the subtitle shows the job number, state and printer.
5. If no preview is possible, the preview column says "Print Preview Not Available" with the reason.

## Functional rules

1. The preview shows the original document as it was sent to the queue, fetched from macOS's printing service; the app does not read the spool directory itself.
2. Only the owner's own jobs can be previewed; macOS refuses other users' documents.
3. A job with several documents is shown as one continuous document. Every document is rendered separately; if one or more documents cannot be rendered, the readable pages are shown with a warning above the preview that names each missing document and why ("Part of this job cannot be displayed: Document 2 of 3: …") (D22). A partial preview is never shown as if it were complete. This also applies within one image document: if an image of a multi-image document cannot be decoded, or a TIFF file contains more images than macOS reports, the readable images are shown with the warning "Only x of the y images in this document can be displayed." Completeness is established as far as macOS reports it (D34): image data that macOS decodes without reporting an error — for example a damaged image that macOS returns as an empty image — cannot be detected and may appear as an empty page without a warning. If no document can be rendered, no preview is shown and the reasons are listed. This applies to rendering only: if fetching any document of the job from the printing service fails, no preview is shown and the error is reported.
4. Supported formats: PDF (recognized by content or label), images (JPEG, PNG, TIFF, GIF, HEIC and other ImageIO formats; multi-frame images become multiple pages; a document with any other, unrecognized label — for example `application/octet-stream` — is recognized as an image by its content) and text (any `text/*` type, decoded as UTF-8 or Latin-1 and laid out on A4 pages in a monospaced font). Content starting with `%PDF` is always treated as PDF; otherwise a `text/*` label wins over the PostScript signature `%!`.
5. PostScript and printer-specific data (for example CUPS raster) are not rendered; the app says so.
6. No copy of the document is left on disk: the temporary file used for the transfer is unlinked immediately.
7. Page and zoom controls stay in place (disabled) while a new document loads, so the toolbar does not jump when switching jobs.

## User interface

PDFKit view, continuous single pages, auto-scaling by default. Exact layout may change.

## Permissions

App Sandbox printing entitlement only; the user must own the job. No administrator password.

## Edge cases

- The document of a completed job has been removed by macOS: "The document is no longer available in the queue."
- A job without a document yet: "This job does not contain a document (yet)."
- Password-protected PDF, unreadable PDF: a specific message.
- An empty document (zero bytes): "The document is empty."
- A document that cannot be decoded in its format (for example an `image/*` label with undecodable data, such as `image/urf`): "Document format “…” cannot be displayed."
- Switching jobs while a document loads: only the last selected job's preview is shown.
- A multi-image document (for example a multi-page TIFF) of which some images cannot be read: the readable images are shown with "Only x of the y images in this document can be displayed."; if none can be read, "Document format “…” cannot be displayed." A TIFF whose chain of images is broken so badly that macOS rejects the whole file gets the latter message as well.

## Error handling

All failures are shown in the preview column with a translated explanation followed by the untranslated technical detail from CUPS where available.

## Acceptance criteria

### PREV-001-AC01

- **Given** the user's own job whose document macOS still retains.
- **When** the user selects it.
- **Then** the preview shows the job's original document content.

### PREV-001-AC02

- **Given** a multi-page document is shown.
- **When** the user uses the page and zoom controls or their shortcuts.
- **Then** the view pages and zooms accordingly and shows "Page x of y".

### PREV-001-AC03

- **Given** a job whose document is PDF, an image or plain text.
- **When** it is previewed.
- **Then** it is rendered as pages; a job with several documents is rendered as one sequence of pages.

### PREV-001-AC04

- **Given** a job whose document is unavailable, in an unsupported format (such as PostScript) or not readable.
- **When** the user selects it.
- **Then** the preview column clearly states that the preview is not available and why.

### PREV-001-AC05

- **Given** the app runs in the App Sandbox as a normal user.
- **When** it fetches a document.
- **Then** it does so through the printing service without root access, password or helper tool, and leaves no copy on disk.

### PREV-001-AC06

- **Given** a job with several documents, some of which cannot be rendered (unreadable, empty or unsupported).
- **When** the user selects it.
- **Then** the readable pages are shown with a warning that names each missing document and the reason; if no document can be rendered, the preview column states that none can be displayed, with the reasons.

## Observed, yet to be confirmed

- Plain text is laid out on A4 in a 10 pt monospaced font (implementation choice).

## Related specifications

[QUEUE-001](QUEUE-001-queue-overview.md), [JOB-001](JOB-001-job-actions.md), [ADR-001](../decisions/ADR-001-documents-through-cupsd.md).

## Technical references

IPP `CUPS-Get-Document` and `Get-Job-Attributes` (`number-of-documents`) over `/private/var/run/cupsd`; see [phase 00 CUPS research](../research/phase-00-cups.md).

## Traceability

| Criterion | Evidence | Coverage |
| --- | --- | --- |
| PREV-001-AC01 | E01 (byte-identical document), E02, E03 | Partial: preview in the real window not visually checked |
| PREV-001-AC02 | — | None: page/zoom controls not exercised by a check |
| PREV-001-AC03 | E05 (text, PNG, PNG without label, multiple documents), E22 (current `makePreview` with several documents), E26 (format detection), E03 (PDF), E27 (two-page TIFF, three-frame GIF, single TIFF, PNG, JPEG) | Partial: HEIC not individually checked; real window not visually checked |
| PREV-001-AC04 | E03 (non-existent job), E05 (PostScript, CUPS raster), E22 (empty document, undecodable image, none readable), E27 (TIFF rejected as a whole) | Partial: messages in the window not visually checked |
| PREV-001-AC05 | E04 (sandboxed harness), E01 | Partial: on-disk absence checked by code review only |
| PREV-001-AC06 | E22 (text + undecodable image, text + empty + text, none readable), E27 (TIFF with an unreadable second image, alone and after a text document) | Partial: rendering logic checked with synthetic documents; the warning banner in the real window not visually checked; image data that macOS decodes without an error is not detectable (D34) |

### Last run

| Date | Procedure | Outcome | By |
| --- | --- | --- | --- |
| 2026-11-16 | Ad hoc Swift harnesses (see evidence) | See evidence items | Executor (Claude), phase 00 |

## History

| Version | Date | Change |
| --- | --- | --- |
| 1 | 2026-11-16 | First version, recording the behaviour built in phase 00 |
| 2 | 2026-11-16 | Review finding: partial previews show a warning (D22); empty documents get their own message; AC06 added |
| 3 | 2026-11-16 | Review finding: a `text/*` document starting with `%!` is shown as text; empty state described |
| 4 | 2026-11-16 | External review finding K1: missing or unreadable images within one image document produce a warning; the completeness limit is recorded (D34) |
