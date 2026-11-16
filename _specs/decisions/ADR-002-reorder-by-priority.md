---
id: ADR-002
title: Reorder the queue by changing job priorities
type: adr
status: proposed
date: 2026-11-16
---

# ADR-002 — Reorder the queue by changing job priorities

## Status

`proposed`

## Context

The user wants to change the order of the queue (D4, D15). CUPS has no "move to position N" operation. cupsd prints waiting jobs by priority (1–100, highest first) and then by job number. `Promote-Job` (print next) requires operator or administrator authentication. The job owner may change `job-priority` with `Set-Job-Attributes` without a password.

## Decision

We change the priorities of the user's own waiting jobs so that cupsd's order equals the requested order. Priorities are assigned from the bottom of the queue upwards, using the smallest value that keeps the order (equal priority keeps the lower job number first), but never below the default 50 and never above 100. Right before applying, the current queue is re-read from cupsd; if a moved job is no longer waiting, nothing is changed (D15).

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| `Promote-Job` | Requires administrator authentication and only moves a job to the front. |
| Cancel and resubmit jobs | Changes job identity and loses history; risky. |

## Consequences

- Reordered jobs may get priorities above 50; jobs submitted later (priority 50) still print after them.
- More than about 50 jobs above the baseline cannot all be distinguished (cap at 100).
- Other users' jobs keep their priority; the requested order may then not be fully achievable (not visible to the user, because other users' jobs are not shown).

## References

[JOB-001](../functional/JOB-001-job-actions.md), `QueueStore.apply(order:moved:)`, `CUPSClient.setPriority(_:jobID:)`.
