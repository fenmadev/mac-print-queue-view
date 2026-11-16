# Phase 00 — report 12

- Start (UTC): 2026-11-16T17:10:19Z (modification time of `PreviewBuilder.swift` after the first edit of this round; the executor did not take a clock sample when the round began, after internal report 11 ended at 17:08:55Z).
- End (UTC): 2026-11-16T17:11:21Z (clock, before writing the report).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor's own chat (`claude-opus-5-5`, Claude Opus 5.5); no model change during the session.
- Scope: round 6 — findings L1 (should fix) and L2 (minor) of [internal review 11](11-internal-claude-Opus-5.5.md) (CHANGES REQUESTED). L3 (optional, Dutch wording) is left to the user.
- Revision: no version control (D33). Changed and new files are listed below; reviewers read them directly.
- Verdict: READY FOR REVIEW.

## Changes

| Finding | File | Change |
| --- | --- | --- |
| L1 | `MacPrintQueueView/PreviewBuilder.swift` | `tiffImageCount` reads at most 255 entries per directory and stops at the first tag of 254 or higher (entries are sorted by tag; NewSubfileType is 254), so the work per directory is bounded; the limit of 10,000 directories stays. `pdfFromImage` skips the TIFF count when ImageIO reports no image (the document cannot be displayed anyway) and when called for a thumbnail: `render` has a `checkCompleteness` parameter (default true), which `makeThumbnailPNG` sets to false. The preview path is unchanged. Doc comment rewrapped. |
| L1 | `_docs/phases/phase-00/evidence/E28/` (new), evidence register | Harness `main.swift` and `results.txt`; register row E28; `Date (UTC)`. |
| L2 | `_docs/phases/phase-00/evidence/E27/main.swift` | Comment: report 09 names and hashes `two.tiff` and `bad-compression.tiff`; `bad-second.tiff` comes from the same temporary folder of review 09. Report 10 is not rewritten; its statement that all three fixtures have SHA-256 values equal to report 09 is corrected here: only two are in report 09. |
| — | `_docs/phases/phase-00/plan.md`, `_docs/model-log.md` | Status, scope E01–E28, `Date (UTC)`; rows for report 11 and round 6. |

## Checks

| Check | Result |
| --- | --- |
| E28 (`-O`) | BigTIFF 20 MB, one directory claiming 1,000,000 entries → 0.001 s; classic TIFF 30.7 MB, 10,000 directories × 255 entries → 0.005 s (report 11 measured up to 7.8 s before the change). |
| E27 re-run | Output identical to `E27/results.txt`. |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` diagnostic. |
| String Catalog | Unchanged in this round (no new texts). |

No print jobs, printers or system settings were touched.

## Open points

- L3 (optional): the user may choose a different Dutch wording for "Slechts %1$lld van de %2$lld afbeeldingen … kunnen worden weergegeven."
- Practical checks, H1–H2 and J1–J4 as before.

## Handoff

```text
READY FOR REVIEW — _docs/phases/phase-00/12-executor-claude-Opus-5.5.md
Check: L1 bound in tiffImageCount and the skipped count for thumbnails/zero images (E28), L2 comment.
Next: internal review → report 13-internal-…; then a new external review (report 14).
```
