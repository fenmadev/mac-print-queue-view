# Phase 01 — report 11

- Start (UTC): 2026-11-16T22:03:05Z (clock, at the start of the review).
- End (UTC): 2026-11-16T22:04:56Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (model Claude Opus 5.5, ID `claude-opus-5-5`), checked at the start of the review; new agent with fresh context that did not implement the changes.
- Scope: phase 01 round 5 — the executor's response ([report 10](10-executor-claude-Opus-5.5.md)) to [internal review 09](09-internal-claude-Opus-5.5.md) (M1 minor, O1–O2 optional), which approved round 4 (R1–R4 of [external review 07](07-external-gpt-6.1-sol.md)): evidence E09 (`run.sh`, the pinned copies in `E09/review-07/`), evidence register, `Tools/install-release.sh` (comment), README, plan and model log; continued validity of the round-4 approval. Both working agreements were read directly.
- Revision: git, HEAD `55933af` (phase 00); rounds 1–4 staged as the review baseline (`git diff --cached`, 53 files); round 5 unstaged (`git diff`): README, `Tools/install-release.sh`, model log, E09 `run.sh`, evidence register, plan; untracked: report 10 and `evidence/E09/review-07/` (`test-printer.sh`, `install-release.sh`), read directly.
- Verdict: APPROVED.

I did not implement or fix anything; the only project file I wrote is this report.

## Assessment of M1, O1, O2 of review 09

| Finding | Assessment |
| --- | --- |
| M1 | Resolved. `run.sh` no longer calls `git show`; both negative controls copy the files from `E09/review-07/`, and the run refuses (exit 1, before the temporary folder is created) when either copy is missing or its SHA-256 differs from the value in the script. The copies are genuinely the versions external review 07 examined: their git blob IDs (`5713b10…`, `ac368f6…`) exist in the repository's object store (they were index blobs) and differ from the currently staged scripts; review 07's line references match them exactly — `test-printer.sh:83` is `grep -q "accepting requests"` (R2), `:112`–`:115` is `remove` with only `exists` before `sudo lpadmin -x` (R1), `install-release.sh:42`/`:45`–`:47` is `pgrep -f "^$TARGET/Contents/MacOS/"` and `kill $PIDS` (R3). The copies are non-executable; the SHA-256 values in `run.sh`, report 10 and the register agree with the files. |
| O1 | Resolved. The register's first limit now separates the Swift harnesses E01–E08 from E09, a shell harness that runs the actual scripts with stub commands. |
| O2 | Recorded as a known limit in the script comment (comment only, verified in the diff), the README and the plan RM-006; behaviour unchanged. Wording is accurate for the case named but narrower than the real limit; see O2 below (optional). |

Regression and continuity checks:

- No app source, spec or behaviour changed in round 5; the only change to a tool is a comment. The round-4 approval therefore still holds for the unchanged material: the staged `E09/run.sh` has the SHA-256 review 09 recorded (`13ff222…`), `E01/main.swift` matches the register, and the staged scripts are the ones E09 runs.
- `run.sh` part 1 and part 2 are otherwise unchanged; the negative controls still run under the same stubs and against the compiled dummies only.
- Model log: the rows for internal review 09 (21:57:18–22:00:30, APPROVED, M1/O1/O2) and executor round 5 (22:01:31–22:02:26) match the reports' headers and content. Plan: status, baseline line, RM-006 limit and round table are accurate, except for the omission in M1 below.

## Findings

### M1 — minor — external report 09 (BLOCKED gate check) is not recorded

**Location:** `_docs/model-log.md` (no row), `_docs/phases/phase-01/plan.md` (status line and the reports/rounds table), executor report 10 (scope/revision).

The phase folder contains `09-external-gpt-6.1-sol.md` (22:00:32–22:01:17, external reviewer `gpt-6.1-sol`, verdict BLOCKED, G1: internal approval of round 4 missing — it was written while internal review 09 was finishing). It is staged in the round-5 baseline but appears nowhere in the model log or the plan, and report 10 does not mention it. The executor agreement requires roles, models, findings and verdicts to be recorded in the model log with its history preserved. The report also shares number 09 with internal review 09 (both created concurrently), which the reviewer guideline's "highest number plus one" rule does not foresee.

**Required (non-blocking, record-keeping only):** add a model-log row and a row in the plan's table for external report 09 (gate check, BLOCKED, G1; superseded by internal approval 09), and note the duplicate number 09 and its cause there instead of renaming either report. This is pure record-keeping; in my view it does not need another internal review if nothing else changes, but it should be done before the external handoff.

### O1 — optional — `run.sh` now only works when called by a relative path

**Location:** `E09/run.sh` line 25, `HERE="$ROOT/$(dirname "$0")"`.

Called by an absolute path (from the project root), `HERE` becomes `<project>//<project>/…/E09` and the run refuses with "the review-07 copies … are missing or changed", which is misleading; before round 5 an absolute call worked. It fails closed and the documented usage is relative, so this is cosmetic. Consider `HERE="${0:A:h}"`.

### O2 — optional — the recorded limit is narrower than the real one

**Location:** `Tools/install-release.sh` comment above `running_copies`, README (install paragraph), plan RM-006.

The comparison uses the command line as started, so not only a start through a symbolic link but any non-canonical spelling is missed — for example a copy started in Terminal by a relative path (`./Mac Print Queue View.app/Contents/MacOS/…`); my probe with an own dummy confirmed `ps` shows the relative path. Consider wording such as "a copy started from Terminal by another path than the real absolute one (a relative path or a symbolic link) is not recognised".

## Checks performed

| Check | Result |
| --- | --- |
| Read both working agreements, reviewer guideline, plan, reports 07, 09 (internal and external), 10, all round-5 diffs and the untracked `review-07/` copies | Done |
| SHA-256 of both pinned copies; `git hash-object` + `git cat-file -t` | Match `run.sh`, report 10 and the register; both are existing blobs, different from the staged scripts |
| Pinned copies against review 07's cited lines (R1 `:112`–`:115`, R2 `:83`–`:85`, R3 `:42`, `:45`–`:47`) | Match exactly |
| E09 `run.sh` from the project root in a new empty temporary folder outside the project (read first: stubs only, own compiled dummies, destination inside the temporary folder) | Exit 0, ALL PASS (26 checks); output identical to `E09/results.txt` after replacing the temporary path; no dummy process left |
| Refusal probes on an isolated copy of `Tools/` and `E09/` in a temporary folder: changed install copy, changed test-printer copy, missing test-printer copy, restored copies | Exit 1 with "Refusing", temporary folder not created, for the three changed/missing cases; ALL PASS with the restored copies |
| Absolute-path invocation of `run.sh` | Refuses (O1) |
| `zsh -n` on both scripts and `run.sh`; `git diff --check` | Pass |
| SHA-256 of `E09/run.sh` (working tree and index) and `E01/main.swift` | `0bbb505…` as in the register (round 5); index `13ff222…` as review 09; E01 as in the register |
| Own probe: a dummy started by a relative path, shown by `ps -o command=` | Relative path shown (O2) |

Not run (no app source changed, or by instruction): builds, E01/E02, E04/E07 run scripts, the real test-printer commands, the install script against real locations. Nothing printed; no print job, printer, installed app, system setting or user process touched.

## Pending practical checks

Unchanged: validation items 12–17 — including pausing several pending jobs against cupsd, the administrator-driven test-printer commands on a real queue and the real install into the user's Applications folder — and the earlier phase-00 practical checks. This approval does not claim practical acceptance.

## Verdict

APPROVED. M1, O1 and O2 of review 09 are handled, the pinned copies are the review-07 versions and the SHA check refuses on mismatch, and round 5 introduces no regression; the round-4 approval still holds. M1 (minor, record-keeping) should be fixed before the external handoff; O1–O2 are optional. Next: record this approval (and external report 09) and hand phase 01 to the user for the external re-review (next report 12).
