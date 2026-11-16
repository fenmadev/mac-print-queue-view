# MacPrintQueueView — living specification

MacPrintQueueView ("Mac Print Queue View") shows what is actually being printed from the existing macOS print queue. The user selects a print job and immediately sees a preview of the document, and can manage their own jobs: cancel, pause, resume, reorder, print again and remove completed jobs.

This folder describes the intended behaviour: functional requirements, acceptance criteria, architecture, decisions and traceable evidence. All features are currently **draft**. Phase 00 records the behaviour that was built before this method was introduced. Phase plans, evidence (items `E01`, `E02`, …) and review reports are in [`_docs/`](../_docs/phases/phase-00/plan.md) in this project.

## Reading order

1. [Scope, decisions and research](inventory.md).
2. [Scenario overview](scenarios.md): job states and what the user can do in each.
3. [Queue overview](functional/QUEUE-001-queue-overview.md).
4. [Print preview](functional/PREV-001-print-preview.md).
5. [Job actions](functional/JOB-001-job-actions.md).
6. [Localization](functional/I18N-001-localization.md).
7. [App identity and distribution](functional/APP-001-app-identity-and-distribution.md).
8. [Architecture](architecture/index.md) and [decisions](decisions/index.md).
9. [Phases and practical checks](getting-started/validation.md).
10. [Phase 00 CUPS research](research/phase-00-cups.md).

## Way of working

- The user determines the intended behaviour. Explicit new instructions take precedence over earlier agreements.
- Approved specs are the implementation contract. The [scenario overview](scenarios.md) summarizes the behaviour; the features and criteria elaborate it.
- Draft choices are visibly marked and do not silently become product behaviour.
- [Lifecycle and traceability](getting-started/contributing.md) govern the links between requirements, code, checks and reviews.
- Use the templates for a [feature](templates/feature.md) or [decision](templates/adr.md).
- Guidelines: [developer](agent-guidelines/developer.md), [reviewer](agent-guidelines/reviewer.md).
