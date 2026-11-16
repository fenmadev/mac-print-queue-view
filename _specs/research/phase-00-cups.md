# Phase 00 research — CUPS on this Mac

Date: 2026-11-16. Machine: Apple Silicon Mac, macOS 27.2.1 (build 26B131), Xcode 27.2, Swift 6.4.2. One printer: `Brother_MFC_J6520DW` (default). One regular local user (`fenma`).

## Findings

1. **Spool directory not readable.** `/private/var/spool/cups` is `drwx--x--- root:_lp`. Document files cannot be read by a normal user, let alone a sandboxed app.
2. **`CUPS-Get-Document` works for the owner.** `/etc/cups/cupsd.conf` contains `<Limit CUPS-Get-Document> AuthType Default; Require user @OWNER @SYSTEM`. A request from the job owner over `/private/var/run/cupsd` succeeds without a password; the returned document was byte-identical to the submitted PDF (phase 00 evidence E01).
3. **Completed jobs keep their documents for a while.** Documents of completed jobs (for example jobs printed earlier the same day) could still be fetched (E02).
4. **Job operations for the owner without a password.** The default policy lists `Send-Document … Hold-Job Release-Job Restart-Job … Set-Job-Attributes …` under `Require user @OWNER @SYSTEM`, and `Cancel-Job` under `Require user @OWNER @AUTHKEY(system.print.operator) @admin @lpadmin`. `Promote-Job` and printer operations require operator/administrator authentication.
5. **Job privacy.** `JobPrivateAccess default` / `JobPrivateValues default`: other users' job names and owners are hidden. The app requests only its own jobs (`my-jobs`).
6. **The App Sandbox printing entitlement is enough.** Harness bundles signed with only `com.apple.security.app-sandbox` and `com.apple.security.print` could list printers and jobs and fetch documents (E04), and perform `Cancel-Job` (E06), `Restart-Job` (E07), `Set-Job-Attributes` (`job-priority`), `Hold-Job`, `Release-Job` and `Cancel-Job` with `purge-job` (E20).
7. **`Restart-Job` with `job-hold-until` is not honoured as expected.** On this cupsd, `Restart-Job` with `job-hold-until=indefinite` on a canceled job returned success but left the job canceled (with `job-hold-until=indefinite` recorded). A held reprint therefore cannot be used to test "Print Again" without paper (E07).
8. **An empty job is a safe test object.** `Create-Job` without `Send-Document` creates a job in state `pending-held` with reason `job-incoming`. Releasing it made cupsd abort it immediately without processing (0 sheets) (E14).
9. **Hold-Job is accepted by the owner.** `Hold-Job` with `job-hold-until=indefinite` on a held test job succeeded (E14).
10. **Priorities decide the order.** Changing `job-priority` of waiting jobs changed the order reported by cupsd accordingly (E08).
11. **PostScript conversion is not available.** macOS 14 and later no longer provide a PostScript-to-PDF converter, so PostScript jobs cannot be previewed.

## Limits

- Only one user and one printer were available; behaviour with other users' jobs, classes or several printers was not observed.
- No job was actually printed on paper during phase 00 checks; pausing a pending job, resuming a job with a document, canceling a printing job and a real reprint were not exercised.

## Sources

- `/etc/cups/cupsd.conf` on this Mac (read 2026-11-16).
- CUPS IPP operations and libcups headers in the macOS 27.2 SDK (`cups/cups.h`, `cups/ipp.h`).
