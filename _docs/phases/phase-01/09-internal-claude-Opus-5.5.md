# Phase 01 — report 09

- Start (UTC): 2026-11-16T21:57:18Z (clock, at the start of the review).
- End (UTC): 2026-11-16T22:00:30Z (clock).
- Role: internal.
- Agent/model: `claude-Opus-5.5`.
- Model verification: session metadata of this reviewer session (model Claude Opus 5.5, ID `claude-opus-5-5`), checked at the start of the review; new agent with fresh context that did not implement the changes.
- Scope: phase 01 round 4 — the executor's response ([report 08](08-executor-claude-Opus-5.5.md)) to findings R1–R4 of [external review 07](07-external-gpt-6.1-sol.md): RM-008 (`Tools/test-printer.sh`), RM-006 (`Tools/install-release.sh`), JOB-001 rule 9 / AC11 and D17 (pausing several jobs), evidence E01 and E09, README, JOB-001 v4, evidence register, plan and model log. Both working agreements were read directly.
- Revision: git, HEAD `55933af` (phase 00); rounds 1–3 staged as the review baseline (`git diff --cached`); round 4 unstaged (`git diff`): `CUPSClient.swift`, `QueueLayout.swift`, `QueueStore.swift`, both scripts, README, JOB-001, E01 (`main.swift`, results), evidence register, plan, model log; untracked: report 08 and `evidence/E09/` (`run.sh`, `results.txt`), read directly.
- Verdict: APPROVED.

I did not implement or fix anything; the only project file I wrote is this report.

## Assessment of R1–R4

| Finding | Required by review 07 | Assessment |
| --- | --- | --- |
| R1 | Read-only identity check before deletion; legacy URI handling specified; isolated test with an unrelated URI | Resolved. `remove` calls `is_test_printer` (reads `lpstat -v` only, exact line for `MPQV_Testprinter`, literal `[[ == "$URI" ]]` comparison) before `sudo lpadmin -x`; another, empty or unreadable address returns 1 and the script exits 1 without any administrator command. It does not reuse `check_printer` (no migration before deletion). The legacy `ipp://127.0.0.1:9/ipp/print` is accepted for removal only, and this is stated in the usage text, README and plan. E09 covers other / empty / unreadable / prefix-only addresses (refused), both test addresses (removed) and an absent printer; negative control reproduces review 07's defect with the review-07 script. |
| R2 | Exact positive/negative acceptance, fail closed, isolated accepting/rejecting/error cases | Resolved. `accepting` distinguishes `"$PRINTER accepting requests"*` and `"$PRINTER not accepting requests"*` on the first line; a failing `lpstat` or unknown text returns failure; `check_printer` refuses on an unreadable state, runs `cupsaccept` only for "no" and re-reads, refusing unless now "yes". I confirmed in an isolated probe that the first-line extraction works on the real multi-line "not accepting" layout (`…since … -` followed by a tabbed reason line). E09 covers accepting, not accepting, accept without effect, unreadable, unknown text and another address; negative control reproduces the defect. |
| R3 | Literal path comparison or full escaping; query failure ≠ no match; stop before replacement; tests with regex-significant and similar names | Resolved. `pgrep -f` is gone; `running_copies` reads `ps -axww -o pid= -o command=` and compares with `"$TARGET/Contents/MacOS/"*`, whose quoted part is literal in zsh. A failing or empty `ps` stops before `rm -rf`, also inside the wait loop. My probe confirmed literal matching for `*`, `?`, `[…]`, `\`, `(…|…)` and double spaces in the path, that `read -r pid cmdline` keeps internal whitespace and strips the right-aligned PID padding, and that `${(f)PIDS}` yields one argument per PID. The additional multi-PID defect (`kill $PIDS` with an unsplit newline list) found by the executor is real and fixed. E09 runs the actual script with compiled dummies in `install [x](y)+.v1/dest.v1` (two copies, both quit) and `…/destXv1` (untouched), and with a failing `ps` (exit 1, nothing replaced). |
| R4 | Re-check each job right before its own hold; skip/report printing jobs; continue after failure; keep the honest limit; fake-client test where B turns printing while A is processed | Resolved. `BulkPause.run` checks each candidate immediately before its hold, counts printing jobs as started, ignores other states, records the first error and continues. `QueueStore.pause(_:)` drives it with `CUPSClient.jobStatus(id:)` (Get-Job-Attributes through the existing `jobState`; a gone job → `.other`) and `holdJob`; the started count now comes from the per-job checks. JOB-001 rule 9 (v4) describes the per-job check and keeps the limit that query and hold of one job are separate requests. E01's fake client changes B to printing during A's hold: B is checked again and never held, C is still held; the same after A's hold fails; an unreadable B is not held; a negative control with the single-snapshot approach holds B. |

Regression checks:

- D17 / JOB-001-AC03, single-job pause: `pause(jobID:)` routes through `pause([id])`; one pending job is re-checked and held, a printing one gives the unchanged single-job message, a gone or non-pending one is left alone. The only behavioural difference to round 3 / phase 00 is that a failing state query now shows an error instead of silently doing nothing — stricter, consistent with D17.
- Message precedence: a failure message overrides the started count, as in round 3 (where `run` overwrote it); acceptable and unchanged.
- Swift 6 concurrency: the detached task captures only `[Int32]`; the non-`Sendable` `any Error` is converted to a `String` inside the task before crossing back. Both builds have 0 compiler warnings.
- `JobStatus.init(ipp_jstate_t)`: the mapping moved unchanged from `PrintJob.status`.
- Scripts: function return statuses are explicit (`local` declared before the assignment, `|| return 1`, `return 0` after the loop); top-level `case` propagates the function status as exit code; usage `sed -n '9,20p'` matches the extended usage block.
- Docs: README, plan RM-006/RM-008, JOB-001 rule 9 and AC11 traceability describe the new behaviour as stub/fake-client verified and keep "Partial" for real multi-pending pause; nothing unverified is presented as verified.

## Findings

### M1 — minor — E09 negative controls depend on the current git index

**Location:** `_docs/phases/phase-01/evidence/E09/run.sh` lines 117–130 and 195–212 (`git show ":Tools/…"`); evidence register row E09.

The negative controls take "the review-07 versions" from the index. As soon as round 4 is staged (the baseline for a next round, or `git add -A` at phase closure) the index holds the new scripts, the controls' expectations no longer hold, and `run.sh` prints `FAILURES` and exits 1 — a later re-run (for example by the external reviewer after another round) would look like a regression although the scripts are correct. The harness does not detect this; report 08 discloses it only as an open point.

**Required (non-blocking):** pin the control inputs, e.g. keep fixed copies of the two review-07 scripts in `E09/` (or verify the index blob's SHA-256 and report the controls as not applicable instead of FAIL when it differs), and note the dependency in the register row.

### O1 — optional — evidence register wording for E09

**Location:** evidence register, "Important limits", first item: "E01–E08 are Swift harnesses and E09 is a shell harness, kept in this folder and compiled together with the app's own source files; the build command is at the top of each `main.swift`". E09 is not compiled with the app sources and has no `main.swift`; it runs the actual scripts. Reword.

### O2 — optional — pre-existing limit of the install script's process match (not a regression)

**Location:** `Tools/install-release.sh` `running_copies`. The match uses the process's command line (argv), compared with the canonical destination. A copy started through a non-canonical spelling (a symbolic-link path) is not recognised, so the script would replace it while it runs. This was the same with the earlier `pgrep -f`; copies started by Finder/LaunchServices use the real path. Consider recording it as a known limit (or matching by the executable's real path).

## Checks performed

| Check | Result |
| --- | --- |
| Read both working agreements, reviewer guideline, plan, reviews 06/07, report 08, all round-4 diffs and the untracked E09 files | Done |
| Debug and Release builds, Swift 6, derived data in a temporary folder outside the project | Both `BUILD SUCCEEDED`, 0 errors, 0 compiler warnings (only the accepted `appintentsmetadataprocessor` line) |
| E01 compiled (`swiftc -O QueueLayout.swift E01/main.swift`) and run | ALL PASS, 68 checks; output identical to `E01/results.txt` |
| E02 compiled and run | ALL PASS; output identical to `E02/results.txt` |
| E09 `run.sh` in a new empty temporary folder (read first: part 1 puts stubs first on a PATH without `/usr/sbin`, `sudo` only logs; part 2 stubs `xcodebuild`/`codesign`, signals only its own compiled dummies, destination inside the temporary folder) | ALL PASS, 26 checks; output identical to `E09/results.txt` after replacing the temporary path |
| SHA-256 of `E01/main.swift` and `E09/run.sh` | Match the evidence register |
| `zsh -n` on both scripts and E09 `run.sh`; `git diff --check` | Pass |
| Own isolated zsh probes (no processes signaled, no system command): first-line acceptance parsing of a multi-line "not accepting" text; literal `[[ == "…"* ]]` with `* ? [ ] \ ( | )` and double spaces; `read -r` whitespace handling; `${(f)…}` splitting | All as expected |

Not run (by instruction or because they would touch the scheduler): E04/E07 run scripts, the real test-printer commands, the install script against real locations.

## Pending practical checks

Unchanged: validation items 12–17 — including pausing several pending jobs against cupsd (not run: a pending job with a document would print), the administrator-driven test-printer commands (`create`, `printing`, `complete`, `remove` on a real queue) and the real install into the user's Applications folder — and the earlier phase-00 practical checks. This approval does not claim practical acceptance.

## Verdict

APPROVED. R1–R4 are resolved as review 07 required, with discriminating isolated evidence and no regression found. M1 (minor) and O1–O2 (optional) are non-blocking. Next: record this approval and hand phase 01 to the user for the external re-review (next report 10).
