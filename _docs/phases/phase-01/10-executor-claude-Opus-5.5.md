# Phase 01 — report 10

- Start (UTC): 2026-11-16T22:01:31Z (clock, when rounds 1–4 were staged as the baseline after receiving report 09).
- End (UTC): 2026-11-16T22:02:26Z (clock).
- Role: executor.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of the executor session (`claude-opus-5-5`, Claude Opus 5.5).
- Scope: round 5 — the findings of [internal review 09](09-internal-claude-Opus-5.5.md), which approved round 4 (R1–R4 of [external review 07](07-external-gpt-6.1-sol.md)): M1 (minor), O1 and O2 (optional). Requirements touched: RM-006 (documented limit), evidence E09.
- Revision: git, baseline commit `55933af`; rounds 1–4 staged as the review baseline at 2026-11-16T22:01:31Z (the review-07 script versions were copied out of the index just before); this round's changes are unstaged (`git diff`), plus the untracked folder `evidence/E09/review-07/` and this report. Changed: `Tools/install-release.sh` (comment only), README, E09 `run.sh`, evidence register, plan, model log.
- Verdict: READY FOR REVIEW.

## Changes per finding

| Finding | Change |
| --- | --- |
| M1 | The two script versions reviewed in external review 07 are kept unchanged in `evidence/E09/review-07/` (copied from the git index before rounds 1–4 were staged; not executable; SHA-256 `16a7ded80030c9ae41821ce4a61f56b68c6eeab2bd3c832869a45afb7181c2ef` for `test-printer.sh` and `b6d74a8d2a9d6b6db918235c1af3ee6a2714261f76d9ac1e75c8cc010616263c` for `install-release.sh`, also recorded in `run.sh` and the register). `run.sh` checks both SHA-256 values at the start and refuses if a copy is missing or changed; the negative controls copy these files instead of reading `git show :Tools/…`. |
| O1 | Evidence register, "Important limits": E09 is described as a shell harness that runs the actual scripts with stub commands, separate from the Swift harnesses compiled with the app sources. |
| O2 | Recorded as a known limit (not changed in behaviour): the install script compares the path a copy was started with; a copy started from Terminal through a symbolic link to the destination is not recognised. Stated in the script comment, the README (quit such a copy first) and the plan. |

## Checks

| Check | Result |
| --- | --- |
| E09 re-run after rounds 1–4 were staged (so the index now holds the new scripts) | 26 checks, ALL PASS; output identical to `E09/results.txt`; no dummy process left |
| SHA-256 of the copies against the index blobs extracted before staging | Equal (the copies are those blobs) |
| `zsh -n` on `Tools/install-release.sh`; `git diff --check` | Pass |

No app source changed in this round, so builds and E01/E02 were not repeated (last run in round 4). Nothing printed; no print job, printer, installed app or user process touched.

## Open points

Unchanged: pausing several pending jobs against cupsd not run; practical checks 12–17; optional O1–O2 of review 06; implementation defaults in the plan open for the user.
