# Lifecycle and traceability

## Status and changes

A feature is `draft`, `approved` or `deprecated`. The user approves behaviour; an agent may record that explicit decision but does not approve anything itself. A draft is editable and is not by itself an instruction to build. An explicit build instruction can grant permission to elaborate a draft.

`version` is an integer and increases with changes to behaviour or acceptance criteria after the first version. IDs are never reused. Withdrawn criteria remain recognizable by being marked as withdrawn.

ADRs are `proposed`, `accepted`, `superseded by ADR-nnn` or `withdrawn`. Functional requirements describe what the user experiences; an ADR explains a technical choice.

## Fixed IDs

Features: `QUEUE-001`, `PREV-001`, `JOB-001`, `I18N-001`, `APP-001`. Criteria: for example `JOB-001-AC03`. Decisions: `D1`. ADRs: `ADR-001`. Evidence items per phase: `E01` (scoped to that phase's evidence file).

Automated tests carry the full criterion ID in their name, or a reference directly next to the test. The spec links each criterion to concrete tests, evidence items or practical checks. Do not invent tests or results.

Coverage (`Full`, `Partial`, `Indirect`, `None`) and execution are separate: record the date, the exact command or procedure, the environment, the result and who ran it. A check of a code path does not prove the behaviour in the real window or on paper.

## Review

Start from the spec, compare the code and check the evidence. Assess each criterion as `PASS`, `FAIL`, `NOT TESTED`, `NOT APPLICABLE` or `CANNOT VERIFY`, with an explanation. A missing practical check remains open, even when other checks pass.

Version control and reviews follow the working agreements and the [review guidelines](../agent-guidelines/reviewer.md).
