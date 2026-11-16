# Phase 00 — record the existing app

Date (UTC): 2026-11-16T18:03:51Z (created 2026-11-16T13:21:00Z)
Status: **closed** — internal review APPROVED (report 15) and external review APPROVED (report 16, the last report of this phase). After closure the git repository was set up in the project folder as part of phase 00 (D35–D37), without separate reports or review. Not committed. Open points after closure are listed under "Known open items".
Baseline: no version control during rounds 4–7 (D33). After closure: git repository without commits (D35); the closed phase-00 state staged at 2026-11-16T17:55:10Z; at closure all phase changes are staged.

## Purpose

The app was built on 2026-11-16 before the review and specs method was introduced. The user decided (D19) that everything built so far is recorded as phase 00, in English, with Claude as the executor, an independent internal Claude reviewer and Codex as the external reviewer.

## Scope

1. The existing app as built: queue overview, print preview, job actions, localization, app identity and App Store preparation.
2. Specifications in `_specs/` for that behaviour, with acceptance criteria and honest traceability.
3. The explicit user decisions (D1–D34) and the implementation defaults that are not user decisions.
4. Architecture, four ADRs and the CUPS research.
5. The development-time evidence (E01–E28) with its limits.
6. Defects found while recording phase 00 are fixed within phase 00 (D21, D22).

Out of scope: new product behaviour, automated tests, App Store submission.

## Acceptance for this phase

- Every user-visible behaviour of the current app is described in a feature spec; nothing in the specs contradicts the code.
- Every explicit user decision is recorded; implementation defaults are marked as such.
- Evidence states exactly what was and was not checked; no claim of visual, paper or App Store acceptance.
- Both builds succeed with zero compiler warnings and zero errors; no translation is missing. The build tool diagnostic `appintentsmetadataprocessor: Metadata extraction skipped, no AppIntents.framework dependency found` is not a compiler warning and is accepted as harmless (the app does not use App Intents).
- Internal review `APPROVED`, then external review `APPROVED`.

## Known open items

- No automated test target; criteria are covered only by development-time harnesses.
- Practical checks listed in the [validation plan](../../../_specs/getting-started/validation.md).
- Known minor items: a job that someone else already removed gets the same "no longer completed, not removed" notice as a job that is back in the queue; if an error and a notice occur at the same moment, only the error is shown; the alert title may switch from "Action Failed" to "Not Removed" during the closing animation.
- App Store metadata and submission (roadmap RM-002).
- Open review points, accepted as non-blocking at closure: L3 of report 11 (Dutch wording of "Only x of the y images …", optional, user's choice); H1–H2 of report 06; J1–J4 of report 08, of which J2 is settled by D35 (working agreements and local editor settings ignored through the local exclude file) and J4 is moot.
- Recorded technical limits: damaged image data that macOS decodes without an error is not detected (D34); TIFF inspection searches at most 10,000 directories and 255 entries per directory.
