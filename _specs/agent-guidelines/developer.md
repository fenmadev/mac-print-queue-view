# Guidelines for the developer (executor)

Read the relevant specs and all acceptance criteria before you build. Follow the phase assigned by the user. Incorporate explicit user decisions (`D<n>` in the [inventory](../inventory.md)); treat other proposals as draft and mark them as such.

Build per phase, add meaningful checks that carry the criterion ID, and update the evidence and documentation. Validate macOS and CUPS claims against current primary sources and the target machine. Report missing evidence concretely. Do not change requirements to make deviating code fit after the fact.

The executor is Claude, the primary assistant in the user's chat. It performs analysis, implementation, documentation, fixes, builds, checks and final verification itself and does not delegate implementation. The working agreements for role separation, the review gate and version control are kept apart from the project files.

## Safety

- Never print on paper as a side effect of a check. Use held test jobs (`lp -H hold -t "MPQV …"`) or empty jobs without a document (IPP `Create-Job`), and remove them afterwards, including from the completed-job history.
- Never cancel, pause, reorder or purge real print jobs of the user in a check.
- No installation, printer configuration, account actions or commits as an implicit side effect. Do not commit unless explicitly requested.
- Keep the app read-only towards the queue except for actions the user explicitly triggers.

## Mandatory internal review before Codex

After the primary checks, obtain a review from a separate Claude agent with fresh context that did not implement the changes. It inspects the specs, the actual files and the evidence, may run safe checks, and writes its report without implementing fixes. Fix its findings and obtain an internal re-review until the current material changes receive an explicit `APPROVED`. Only then hand off to the user for the external Codex review. Both approvals are required for phase closure. Changes after the Codex review pass this gate again.

Version control within review rounds follows the working agreements.

## Language and identifiers

Write all project files in English: specs, reports, code, comments and commit messages. Reports carry actual ISO 8601 UTC times in their fixed header (`Start (UTC)`, `End (UTC)`); plans, evidence registers and the roadmap carry a `Date (UTC)` line. ID letters are English abbreviations (for example D = Decision); preserve existing IDs and historical references.
