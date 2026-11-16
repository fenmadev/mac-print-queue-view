# Phase 00 — report 15

- Start (UTC): 2026-11-16T17:17:25Z (clock, at the start of the review).
- End (UTC): 2026-11-16T17:21:51Z (clock, before writing the report).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: the reviewer's own session metadata (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the review; new agent with fresh context that did not implement round 7.
- Scope: round 7 as described in [executor report 14](14-executor-claude-Opus-5.5.md): the answer to findings M1 (minor) and M2 (optional) of [internal review 13](13-internal-claude-Opus-5.5.md), which approved round 6. Both working agreements were read directly.
- Revision: no version control (D33). Files modified after report 13 (by modification time, excluding the local build output, editor settings and Finder `.DS_Store` files): exactly those listed in report 14 — `PreviewBuilder.swift`, `E27/main.swift`, `E27/results.txt`, `E28/results.txt`, the evidence register, the plan, the model log and report 14. All were read directly.
- Verdict: APPROVED.

I did not implement or fix anything; the only project file I wrote is this report.

## Findings

None. No blocking, should-fix, minor or optional findings.

## Checks

| Check | Result |
| --- | --- |
| M1 | `PreviewBuilder.swift:225`–`:233`: the loop now skips every tag other than 254 (`continue`) and stops only when tag 254 is found, within the first 255 entries. Own probes (classic and BigTIFF, little- and big-endian, full 2×2 images): page plus mask or thumbnail with tag 254 placed last (LONG and SHORT), and two pages with unsorted tags → count equal to ImageIO's, preview complete, no warning. Resolved. |
| M2 | `:230`: LONG8 (16) is read as 8 bytes only when `big` is true; SHORT 2 bytes, other types 4 bytes. Big-endian BigTIFF with a LONG8 thumbnail (sorted and unsorted) → 1 image; LONG8 value 2 → 2 images; little-endian BigTIFF LONG8 unchanged; type 16 in a classic file (invalid) still reads 4 bytes and gives the right count. The 8-byte read at `at + 12` lies inside the 20-byte entry. Resolved. |
| Rest of the file | The loop still starts at line 224, as referenced in report 13; the doc comment (lines 177–180) describes the new search correctly. The rest of `PreviewBuilder.swift` was read: nothing else changed in substance (no diff is available without version control). Only this source file changed after report 13. |
| Bound, own `-O` timing harness (PreviewBuilder only) | Classic file, 10,000 overlapping directories each claiming 65,535 entries, all tags 0 (full 255-entry scan each): 0.004 s. BigTIFF, 10,000 overlapping directories claiming 1,000,000 entries each (20 MB): 0.0045 s. Big-endian BigTIFF chain of 10,000 × 255 entries with LONG8 tag 254 as the 255th entry (51 MB): 0.0066 s. Valid one-image TIFF continued by a 10,000 × 255 chain (30.7 MB, ImageIO reports 1): `makePreview` 0.010 s in total (ImageIO then rejects the file: "cannot be displayed"), count alone 0.006 s. Unoptimized build: about 0.65 s for the same worst cases (development only). The bound of 10,000 directories × 255 entry reads holds for any input: `visited` stops loops and long chains, and the entry count is not used beyond the range check. |
| Malformed input | 300,000 random mutations (byte changes, extreme values, truncation, appended bytes) of small classic and BigTIFF files, every prefix of each seed, and offsets set to `Int.max`, `Int.min`, −1, 2^62 and `UInt32.max`, in `-O` and `-Onone` builds: no trap. Arithmetic: `next` ≤ `bytes.count` after the first read, `entries` ≤ `bytes.count`, so `start`, `end` and `at + valueOffset` cannot overflow; every entry lies before the readable next pointer, so all reads inside the loop are in range. |
| Residual case | Tag 254 after the 255th entry of an unsorted directory is not seen (documented bound). In probes with 250 or more extra tags ImageIO rejected or did not render the file, so no false warning appeared. Not a finding. |
| False warnings on valid files | ImageIO-written single, three-page LZW and two-page with embedded thumbnail, EXIF and GPS; `tiffutil -cat`, `-cathidpicheck`, `-lzw`, `-none`; `sips` TIFF (uncompressed and LZW) → `tiffImageCount` equal to ImageIO's count, preview complete without problems, thumbnail made. |
| E27 harness | Output identical to `E27/results.txt` (21 lines, including the two round-7 cases, both `Optional(1)`); no stderr output. Fixture SHA-256 values equal to the evidence register. |
| E28 harness (`-O`, three runs) | 0.001–0.002 s and 0.004–0.005 s, counts 1 and 10,000 — matches `E28/results.txt`. |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; one `warning:` line each, the accepted `appintentsmetadataprocessor` diagnostic. |
| Evidence register | E27 and E28 rows describe the round-7 cases and timings correctly. The re-run time 17:16:41Z lies between the modification of `E27/main.swift` (17:16:37Z) and of the results files (17:16:47Z–17:16:48Z), so it is the start of the re-run. `Date (UTC)` 17:17:03Z equals the file's modification time. |
| Plan | Status (round 7, report 14, awaiting review 15, then a new external review; L3 to the user; H1–H2, J1–J4 open) correct; `Date (UTC)` equals its modification time; scope D1–D34, E01–E28 unchanged and correct. |
| Model log | Row for report 13 (17:11:55Z–17:15:31Z, APPROVED, M1 minor, M2 optional) and row for round 7 (17:16:19Z–17:17:03Z) match the reports' headers; earlier history preserved. |
| Report 14 | Accurate: changes, checks and open points match the files and my re-runs. Its start (17:16:19Z) precedes the modification of `PreviewBuilder.swift` (17:16:25Z). |
| Relative links and D25 | 44 Markdown files, no broken relative links; no working-agreement file names, local editor or build folders or home-folder paths in the changed files (temporary `/tmp` paths only). |

No print jobs, printers or system settings were touched; no harness made a CUPS call; nothing installed; no version-control action. The temporary folder under `/private/tmp` (harnesses, generated TIFF files, derived data) was removed before this report was written.

## Pending practical checks

Unchanged: the warning banner in the real window and the native-language review of the Turkish text. L3 (Dutch wording) awaits the user.
