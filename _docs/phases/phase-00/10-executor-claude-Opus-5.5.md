# Phase 00 — report 10

- Start (UTC): 2026-11-16T16:52:49Z (clock, when the executor started on external report 09).
- End (UTC): 2026-11-16T17:03:36Z (clock, before writing the report).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor's own chat (`claude-opus-5-5`, Claude Opus 5.5); no model change during the session.
- Scope: round 5 — finding K1 (should fix) of [external review 09](09-external-gpt-6.1-sol.md) (CHANGES REQUESTED), and the product disposition it asked for, decided by the user (D34).
- Revision: no version control (D33). Changed and new files are listed below; reviewers read them directly.
- Verdict: READY FOR REVIEW.

## Changes

| File | Change |
| --- | --- |
| `MacPrintQueueView/PreviewBuilder.swift` | `pdf(for:)` renamed to `render(_:)` and returns the PDF plus a description of missing content. `pdfFromImage` no longer skips a frame silently: it compares the pages rendered with the images expected and returns "Only x of the y images in this document can be displayed." when pages are missing. Expected images = ImageIO's count, or for `public.tiff` the higher count from the new `tiffImageCount`, which follows the TIFF directory chain itself (classic and BigTIFF, both byte orders; thumbnails and transparency masks excluded; a directory outside the file counts as a claimed image; loops and more than 10,000 directories stop the walk). `makePreview` adds that description to `problems` (prefixed "Document n of m:" for jobs with several documents), so the existing warning banner shows it. Thumbnails are unchanged apart from the call. |
| `MacPrintQueueView/Localizable.xcstrings` | New key `Only %lld of the %lld images in this document can be displayed.` with Dutch and Turkish (positional placeholders). Added with `Tools/sync-strings.sh`; the file was then written back in its existing formatting, so the only difference is the new key. |
| `_specs/functional/PREV-001-print-preview.md` | Version 4: rule 3 extended to images within one document and the completeness limit (D34); new edge case; traceability AC03, AC04, AC06 with E27; history row. |
| `_specs/inventory.md` | Decision D34. |
| `_docs/phases/phase-00/evidence/README.md` | E27; `Date (UTC)`. |
| `_docs/phases/phase-00/evidence/E27/` (new) | `main.swift` (harness), `results.txt` (its output), and the three fixtures of report 09 (`two.tiff`, `bad-compression.tiff`, `bad-second.tiff`; SHA-256 equal to report 09). |
| `_docs/phases/phase-00/plan.md` | `Date (UTC)`, status, scope D1–D34 and E01–E27. |
| `_docs/model-log.md` | Rows for external review 09 and round 5. |

## Product disposition (D34)

ImageIO returns the second image of `bad-second.tiff` as an all-zero image with status complete and no error; this cannot be told apart reliably from a real image (an all-black image without alpha looks the same). The user was told the scenario (only image print jobs, which macOS apps rarely send, that are also damaged) and accepted the recommendation: record the limit, no heuristic. PREV-001 rule 3 no longer promises more than macOS reports.

## Checks

| Check | Result |
| --- | --- |
| E27 harness (no CUPS, no printing) | K1 fixture → 1 page plus the warning (also with label `application/octet-stream` and after a text document); valid two-page TIFF, single TIFF, three-frame GIF, PNG, JPEG, text → complete without problems; E22 case unchanged; broken TIFF chain (beyond end of file, loop) → macOS rejects the file → existing error; `tiffImageCount` hand-built cases as expected. `bad-second.tiff` → 2 pages without a warning (D34). See E27. |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` diagnostic. |
| String Catalog | 87 keys, 86 translatable, none without Dutch or Turkish translation; keys still sorted. |
| New message in the built bundles | Debug and Release: nl "Slechts 1 van de 2 afbeeldingen in dit document kunnen worden weergegeven."; tr "Bu belgedeki 2 görüntüden yalnızca 1 tanesi görüntülenebilir." English comes from the source key. |
| Date lines | Plan and evidence register carry the modification time of their last content change. |

No print jobs, printers or system settings were touched.

## Open points

- Turkish wording of the new message awaits the pending native-language review (practical check).
- The warning banner in the real window is still not visually checked.
- H1–H2 of report 06 and J1–J4 of report 08 remain open as before.

## Handoff

```text
READY FOR REVIEW — _docs/phases/phase-00/10-executor-claude-Opus-5.5.md
Check: K1 fix in PreviewBuilder.swift, E27 (harness, fixtures, results), D34 and PREV-001 v4, catalog.
Next: internal review → report 11-internal-…; then a new external review (report 12).
```
