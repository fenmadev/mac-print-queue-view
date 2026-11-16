# Phase 00 — report 13

- Start (UTC): 2026-11-16T17:11:55Z (clock, at the start of the review).
- End (UTC): 2026-11-16T17:15:31Z (clock, before writing the report).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: the reviewer's own session metadata (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the review; new agent with fresh context that did not implement round 6.
- Scope: round 6 as described in [executor report 12](12-executor-claude-Opus-5.5.md): the answer to findings L1 (should fix) and L2 (minor) of [internal review 11](11-internal-claude-Opus-5.5.md); L3 (optional) is left to the user. Both working agreements were read directly.
- Revision: no version control (D33). Files modified after report 11 (by modification time, excluding the local build output): exactly those listed in report 12 — `PreviewBuilder.swift`, `E27/main.swift`, the new `E28/main.swift` and `E28/results.txt`, the evidence register, the plan, the model log and report 12. All were read directly.
- Verdict: APPROVED.

I did not implement or fix anything; the only project file I wrote is this report.

## Findings

### M1 — minor — the early stop gives a false warning for TIFF files with unsorted tags

`MacPrintQueueView/PreviewBuilder.swift:224`–`:233`. The loop stops at the first tag ≥ 254. In a file whose directory entries are not sorted (a violation of the TIFF specification that ImageIO and libtiff tolerate) and whose NewSubfileType tag comes after, for example, ImageWidth (256), a reduced-resolution or mask directory is counted as a full image. Probe (hand-built little-endian TIFF, full image plus a reduced-resolution directory with tag 254 placed after 256, or last): ImageIO reports 1 image, `tiffImageCount` 2, and the preview shows 1 page with "Only 1 of the 2 images in this document can be displayed." A variant of the loop that scans every entry, as in round 5 (reconstructed from report 11's description), returns 1 for the same files. Only malformed files are affected and the error is a spurious warning, not hidden content. The early stop is not needed for the bound: the cap of 255 entries per directory alone limits the work to 10,000 × 255 reads. Suggested direction, the executor's choice: keep the 255 cap but skip over tags other than 254 instead of stopping at 255 or higher, so tag order inside the first 255 entries no longer matters.

### M2 — optional — NewSubfileType of type LONG8 in a big-endian BigTIFF

`PreviewBuilder.swift:229` reads 4 bytes for every type other than SHORT. For a LONG8 (type 16) value in a big-endian BigTIFF, those are the high bytes, so the value reads as 0 and a reduced-resolution directory is counted (probe: ImageIO 1, count 2, false warning). This was already the case in round 5, little-endian files are not affected, and common writers store NewSubfileType as LONG. Reading 8 bytes for type 16 would settle it.

## Checks

| Check | Result |
| --- | --- |
| Bound of `tiffImageCount` | For any input: at most 10,000 directories (`visited` set; loops and long chains stop), at most 255 entries read per directory, O(1) reads per entry and per directory; the remaining cost is the single copy of the data. No path depends on the claimed entry count apart from the range check of the next pointer (`entries ≤ bytes.count` prevents overflow in `entries * entrySize`). Overlapping or crafted chains cannot exceed 2.55 million entry reads. |
| Early stop on valid files | Correct for files that follow the TIFF specification: tags are unique and ascending, so at most 254 tags (0–253) can precede tag 254, which therefore lies within the first 255 entries. Tags below 254 (for example private tag 11) are skipped. The old SubfileType tag 255 is not interpreted, as before; ImageIO counts a directory with SubfileType 2 as an image as well, so no warning results. Unsorted files: M1. |
| `checkCompleteness` and zero images | `makeThumbnailPNG` passes `false` and uses only `.pdf`, so the skipped count changes nothing visible; `makePreview` uses the default `true`. When ImageIO reports 0 images, no page can be rendered and `render` throws the same "cannot be displayed" error as before, so skipping the count changes no result. No new force unwraps, traps or unchecked conversions. |
| Adversarial timing, own harness built with `-O`, PreviewBuilder only | BigTIFF of 21 MB, 10,000 overlapping directories each claiming 1,048,576 entries with all tags 0 (defeats the early stop): `tiffImageCount` 0.006 s, `makePreview` 0.04 s (ImageIO rejects the file), `makeThumbnailPNG` 0.0001 s. Report-11 style classic file of 0.85 MB with 10,000 overlapping directories of 65,535 entries: 0.0001 s. Valid one-image TIFF followed by a 10,000-directory chain of 255 entries (30.7 MB; ImageIO reports 1, so the count runs on the preview path): `makePreview` 0.004 s, thumbnail 0.0001 s. Report 11 measured up to 7.8 s for comparable files. |
| E28 harness (`-O`) | BigTIFF 0.001 s, count 1; classic chain 0.004 s, count 10,000 — matches `E28/results.txt` (0.005 s). |
| E27 harness | Output identical to `E27/results.txt`; no stderr output. Fixture SHA-256 values equal to the evidence register. |
| False warnings on valid files | Hand-built sorted TIFFs (two full images; reduced-resolution and mask directories with LONG and SHORT values; classic big-endian; BigTIFF little- and big-endian with LONG; three pages with SubfileType 3; SubfileType 2 only); ImageIO-written single, three-page LZW and two-page with embedded thumbnail, EXIF and GPS; `tiffutil -cat`, `-cathidpicheck`, `-lzw`; `sips` TIFF → `tiffImageCount` equal to ImageIO's count, preview complete without problems, thumbnail made. Exceptions only M1 and M2. |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` diagnostic. |
| L2 | `E27/main.swift` comment now says report 09 names and hashes `two.tiff` and `bad-compression.tiff` and that `bad-second.tiff` comes from the same temporary folder; the register row is unchanged and correct; report 12 records the correction of report 10. Resolved. |
| Evidence register, plan, model log, report 12 | E28 row matches the harness and its results; its time equals the modification time of `E28/results.txt`. `Date (UTC)` lines of the register and plan (17:11:21Z) equal their modification times. Plan status (round 6, awaiting review 13, L3 to the user) and scope D1–D34, E01–E28 correct. Model-log rows for report 11 (17:04:16Z–17:08:55Z) and round 6 (17:10:19Z–17:11:21Z) match the reports' headers; the round-6 start is the modification time of `PreviewBuilder.swift`, which still holds that time, and report 12 states that no clock sample was taken. Report 12 accurate. |
| Relative links and D25 | 42 Markdown files, no broken relative links; no working-agreement file names, local editor or build folders or home-folder paths in the changed files (temporary `/tmp` paths only). |

No print jobs, printers or system settings were touched; no harness made a CUPS call; nothing installed; no version-control action. The temporary folder under `/private/tmp` (harnesses, generated TIFF files, derived data) was removed before this report was written.

## Pending practical checks

Unchanged: the warning banner in the real window and the native-language review of the Turkish text. L3 (Dutch wording) awaits the user.
