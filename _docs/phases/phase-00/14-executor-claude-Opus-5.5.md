# Phase 00 — report 14

- Start (UTC): 2026-11-16T17:16:19Z (clock, after receiving internal report 13).
- End (UTC): 2026-11-16T17:17:03Z (clock, before writing the report).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor's own chat (`claude-opus-5-5`, Claude Opus 5.5); no model change during the session.
- Scope: round 7 — findings M1 (minor) and M2 (optional) of [internal review 13](13-internal-claude-Opus-5.5.md), which approved round 6. M1 was introduced by round 6, so it is fixed before the external review.
- Revision: no version control (D33). Changed files are listed below; reviewers read them directly.
- Verdict: READY FOR REVIEW.

## Changes

| Finding | File | Change |
| --- | --- | --- |
| M1 | `MacPrintQueueView/PreviewBuilder.swift` | `tiffImageCount` no longer stops at the first tag ≥ 254: it searches the first 255 entries of each directory for NewSubfileType (254) and stops when found. The work stays bounded (10,000 directories × 255 entries). Doc comment updated. |
| M2 | `MacPrintQueueView/PreviewBuilder.swift` | NewSubfileType of type LONG8 (16) in a BigTIFF is read as 8 bytes; SHORT 2 bytes, other types 4 bytes as before. |
| M1, M2 | `_docs/phases/phase-00/evidence/E27/main.swift`, `E27/results.txt` | Two hand-built cases added (unsorted thumbnail directory; big-endian BigTIFF with LONG8); results re-run. |
| — | `_docs/phases/phase-00/evidence/E28/results.txt`, evidence register | E28 re-run; E27 and E28 rows note the round-7 re-runs; `Date (UTC)`. |
| — | `_docs/phases/phase-00/plan.md`, `_docs/model-log.md` | Status, `Date (UTC)`; rows for report 13 and round 7. |

## Checks

| Check | Result |
| --- | --- |
| E27 | Both new cases → 1 image (no false warning); all 19 earlier lines identical to the previous results. |
| E28 (`-O`) | 0.002 s and 0.005 s. |
| Debug and Release builds | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings; only the accepted `appintentsmetadataprocessor` diagnostic. |

No print jobs, printers or system settings were touched.

## Open points

- L3 (optional, Dutch wording) left to the user; practical checks, H1–H2 and J1–J4 as before.

## Handoff

```text
READY FOR REVIEW — _docs/phases/phase-00/14-executor-claude-Opus-5.5.md
Check: M1/M2 in tiffImageCount, E27 additions, E28 timing.
Next: internal review → report 15-internal-…; then a new external review (report 16).
```
