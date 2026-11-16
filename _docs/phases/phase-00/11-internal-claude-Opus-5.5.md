# Phase 00 — report 11

- Start (UTC): 2026-11-16T17:04:16Z (clock, at the start of the review).
- End (UTC): 2026-11-16T17:08:55Z (clock, before writing the report).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: the reviewer's own session metadata (`claude-opus-5-5`, Claude Opus 5.5), read at the start of the review; new agent with fresh context that did not implement round 5.
- Scope: round 5 as described in [executor report 10](10-executor-claude-Opus-5.5.md): the answer to finding K1 of [external review 09](09-external-gpt-6.1-sol.md) and user decision D34. Both working agreements were read directly.
- Revision: no version control (D33). Compared the current files with the SHA-256 manifest the external reviewer made during review 09 (temporary file under `/private/tmp`): exactly the files listed in report 10 changed (`PreviewBuilder.swift`, `Localizable.xcstrings`, PREV-001, inventory, evidence register, plan, model log) plus the new E27 folder and report 10. All were read directly.
- Verdict: CHANGES REQUESTED.

I did not implement or fix anything; the only project file I wrote is this report.

## Findings

### L1 — should fix — `tiffImageCount` does unbounded work on crafted TIFF files

`MacPrintQueueView/PreviewBuilder.swift:202`–`:223`. The walk visits up to 10,000 directories and, in each, scans every entry; directories may overlap, so the total work is about 10,000 × (file size / entry size). Classic TIFF is capped by its 16-bit entry count (65,535), BigTIFF only by the file size. Measured with `-O` (as in Release), harness calling only `tiffImageCount`/`makePreview`:

- classic TIFF of 0.87 MB, 10,000 overlapping directories of 65,535 entries: 0.5 s;
- BigTIFF of 20 MB, 10,000 overlapping directories of 1,000,000 entries: 7.8 s (ImageIO itself reports 0 images and the preview fails anyway, so all that work is wasted). The time grows linearly with file size.

No crash, and the work runs off the main thread, but `render` is also used for the list thumbnails, a failed thumbnail is retried after 5 s, and thumbnails are built one job at a time. A crafted TIFF job in the queue therefore keeps a core busy for as long as it is queued and delays the other thumbnails. This is new in round 5 (ImageIO alone rejects such files in milliseconds). Suggested direction, the executor's choice: TIFF requires entries sorted by tag, so stop scanning a directory at the first tag ≥ 254, and/or cap the total number of entries read; optionally skip the count when ImageIO reports 0 images or for thumbnails, where the result is not used.

### L2 — minor — fixture provenance overstated

Report 10 ("the three fixtures of report 09 … SHA-256 equal to report 09") and the comment in `E27/main.swift` ("created by the external reviewer (report 09)") attribute all three fixtures to report 09. Report 09 names and hashes only `two.tiff` and `bad-compression.tiff`. `bad-second.tiff` is identical (SHA-256 `14409ded…bda2`) to the file in the external reviewer's temporary folder, but report 09 does not mention it. The evidence register's wording ("Fixtures from the external reviewer") is correct; adjust the other two sentences.

### L3 — optional — Dutch verb agreement

"Slechts 1 van de 2 afbeeldingen … kunnen worden weergegeven": with the most likely value 1 the singular "kan" reads more naturally. Plural variants in the catalog or a rephrasing would settle it; the user can judge.

## Checks

| Check | Result |
| --- | --- |
| K1 required result | Met together with D34. `bad-compression.tiff` (also labelled `application/octet-stream`, and after a text document with the "Document 2 of 2:" prefix) → readable page plus warning; the per-frame `continue` path now lowers `shown` below `reported` and is reported for every image format; `bad-second.tiff` stays undetected, as recorded in D34 and PREV-001 rule 3. PDF and text paths unchanged; the thumbnail path only adapts the call. |
| Code inspection of `tiffImageCount` | Bounds check in `read` safe (`bytes.count ≥ 8`, `size ≤ 8`, offset ≥ 0); `next ≤ Int.max` before conversion; `entries ≤ bytes.count` prevents overflow in `entries * entrySize`; the whole directory and its next pointer are checked to lie in the file before the entry loop; byte order and SHORT/LONG value placement correct for both orders; loops and long chains stop. Only weakness found: L1. |
| E27 harness, own build under `/private/tmp` | Output identical to `E27/results.txt`; no stderr output. |
| Fixture SHA-256 | `two.tiff` and `bad-compression.tiff` equal report 09; `bad-second.tiff` equal to the external reviewer's temporary file (L2). |
| Malformed-TIFF probes (own harness, PreviewBuilder only) | Truncated classic/BigTIFF headers → nil; first-directory offsets `0xFFFFFFFF`, `Int.max − 1`, `Int.max`, `Int.max + 1`, `2^62`, `UInt64.max`; entry counts `0xFFFF` in a small file, `2^60`, `Int.max`, `UInt64.max`; next pointer `Int.max`/`UInt64.max`; NewSubfileType value beyond the end; chain of 12,000 empty directories (stops at 10,000) — all without a crash, preview → existing error. 20,000 random mutations/truncations of `two.tiff` through `makePreview` and 200,000 random 0–64-byte headers through `tiffImageCount`, built with `-Onone` (overflow traps active): no crash. Work amplification: L1. |
| False warnings on valid files | ImageIO-written TIFF with EXIF/GPS dictionaries, with embedded-thumbnail option, three-page LZW, grey without alpha, CMYK, 16-bit RGBA; `NSBitmapImageRep` LZW TIFF; `NSImage` with two representations; `tiffutil -cat`, `-cathidpicheck` and `-lzw` output; `sips` TIFFs; HEIC; two-frame GIF → all complete, no problems, `tiffImageCount` equal to ImageIO's count (nil for non-TIFF). |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` diagnostic. |
| String Catalog | 87 keys, sorted, every translatable key has nl and tr. Compiled nl/tr `Localizable.strings` of both configurations compared with the external reviewer's review-09 build: the only difference is the new key; placeholders positional and matching (`%1$lld`, `%2$lld`; Turkish reorders correctly). |
| PREV-001 v4, D34, E27 row, plan, model log, report 10 | Consistent with the code and with each other; rule 3 no longer promises more than macOS reports; edge case and traceability (AC03, AC04, AC06 with E27) accurate; history row present; plan status, scope D1–D34/E01–E27 and Date lines match file times; model-log rows for report 09 and round 5 match the reports' headers. Report 10 accurate apart from L2. |
| Relative links and D25 | 40 Markdown files, no broken relative links; no local-environment paths or working-agreement file names in the changed files (temporary `/tmp` paths only). |

No print jobs, printers or system settings were touched; no CUPS call was made by any harness; nothing installed; no version-control action. Temporary files under `/private/tmp` were removed after the review.

## Pending practical checks

Unchanged from report 10: the warning banner in the real window and the native-language review of the Turkish text.
