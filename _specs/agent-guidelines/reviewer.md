# Guidelines for the reviewer

Assess specification → code → evidence. Give a verdict and evidence per criterion in accordance with the [traceability agreements](../getting-started/contributing.md).

In particular, check: only the user's own jobs are shown and changed; no action can print on paper unintentionally; state is re-checked with cupsd right before actions that depend on it (pause, reorder, permanent removal); error handling and messages; sandbox and entitlements; localization completeness; and that unverified behaviour is not presented as verified. Name unresolved product choices and technical assumptions. Do not change product requirements in order to approve an implementation.

## Roles and order

The order is implementation → independent internal Claude review → fixes and internal re-review until `APPROVED` → external Codex review (run by the user). The internal reviewer is a separate Claude agent with fresh context that did not implement the changes. Both reviewers review the actual code, specs and changed files of this project, including the phase documentation in `_docs/` (plans, evidence, reports), and read the working agreements directly because they are kept apart from the project files; they do not rely on the executor's report alone and do not implement fixes. State the actual model, the reviewed revision or scope, the checks, the findings and an explicit verdict: `APPROVED`, `CHANGES REQUESTED` or `BLOCKED`. `BLOCKED` means the review could not be carried out or completed — for example the internal gate is not met, required files are inaccessible, the model cannot be verified, or a user decision is missing — and names what is needed to continue. An approval covers the current material changes, including substantive documentation. Name pending practical (visual, hardware or paper) checks separately; software approval does not claim practical acceptance. Both applicable approvals are required for phase closure.

## Safe checks

Reviewers never print on paper, never change real print jobs, printers or system settings, never install, stage or commit. Reviewers may build the app and run read-only queries.

Every build of the app target raises the build number kept in the tracked file `BUILD_NUMBER` in the project root (D47). A check build — by a reviewer or by the executor for a check — notes the value of `BUILD_NUMBER` before building and writes that value back afterwards, so that the check leaves the project unchanged; the report says that this was done. Build into a temporary folder outside the project (`-derivedDataPath`).

## Naming reports

Store reports under `_docs/phases/phase-NN/` in this project with the file name `<NN>-<role>-<model>.md` (D26):

- `<NN>`: a two-digit sequence number that continues per phase across all roles and models; use the highest existing number plus one.
- `<role>`: `executor` (the executor's own report of a round), `internal` (the independent internal reviewer) or `external` (the external reviewer).
- `<model>`: the actual model, for example `claude-Opus-5.5` or `gpt-6.1-sol`.

Every executor round ends with an executor report, followed by the review of that round, for example:

- `01-executor-claude-Opus-5.5.md` — the executor's report of round 1.
- `02-internal-claude-Opus-5.5.md` — the independent internal review of round 1.
- `03-external-gpt-6.1-sol.md` — the external review.

Unknown model identity must be stated and clarified, not guessed.

## Report header

Every report — executor, internal and external — starts with this header, in this order (D29):

```text
# Phase <phase number> — report <report number>

- Start (UTC): <actual start of the round or review> (<source: session metadata or clock>).
- End (UTC): <actual time just before writing the report> (clock).
- Role: executor | internal | external.
- Agent/model: `<verified model, as in the file name>`.
- Model verification: <source and time>.
- Scope: <round, criteria and reports covered; what triggered it>.
- Revision: <project state: version control (none yet, or commit, baseline staging and round diff), files changed in the round>.
- Verdict: <READY FOR REVIEW (executor) | APPROVED | CHANGES REQUESTED | BLOCKED>.
```

A review report continues with one sentence stating that the reviewer did not implement or fix anything.

## Handoff message

At the end of every executor round and every review, the agent prepares a short message in the chat for the next role or the user (D30): the verdict or status, the report's path, what must happen (blocking and should-fix finding IDs with one line each, or the user decision needed; optional points only as a count) and the next step with the next free report number. At most about five lines; not a summary of the report.

## References in reports

Reports, like all project files, name nothing of the local working environment outside it: refer to the working agreements by role ("the executor agreement", "the external-reviewer agreement") and to the project folder, its other folders (local build output, editor settings) and home-folder paths by a neutral description, never by file name or path. System locations and temporary paths that belong to the technical content may be named (D25).

## Date and time

Reports (executor, internal, external) carry their times in the header: `Start (UTC)` and `End (UTC)`, as `YYYY-MM-DDTHH:mm:ssZ`, actual times with their source (D29). Plans, evidence registers and the roadmap carry a `Date (UTC)` line with the actual time of their last change. Never estimate a time.

## Language

Write reports and specs in English.
