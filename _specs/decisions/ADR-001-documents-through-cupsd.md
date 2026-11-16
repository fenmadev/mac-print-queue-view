---
id: ADR-001
title: Fetch job documents through cupsd, not from the spool directory
type: adr
status: proposed
date: 2026-11-16
---

# ADR-001 — Fetch job documents through cupsd, not from the spool directory

## Status

`proposed`

## Context

Print job documents are stored by cupsd in `/private/var/spool/cups` (`d<job>-<doc>` files). On this Mac that directory is `drwx--x--- root:_lp`, so a normal user cannot read it. The app must work as a normal, sandboxed user app suitable for the Mac App Store, without root access, an administrator password or a privileged helper.

## Decision

We fetch documents with the standard CUPS operation `CUPS-Get-Document` over the local cupsd socket. cupsd allows it for the job owner (policy `<Limit CUPS-Get-Document> Require user @OWNER @SYSTEM`) and identifies the owner through the socket's peer credentials. The response is written by `cupsDoIORequest` to a private temporary file (0600) that is unlinked immediately after creation and read into memory.

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| Read the spool directory directly | Not readable without root; impossible in the App Sandbox. |
| Privileged helper tool (SMJobBless / launch daemon) | Needs an administrator password, enlarges the attack surface and is not allowed in the Mac App Store. |
| Virtual printer / PDF capture | Not the existing queue; excluded by D1. |

## Consequences

- Only the user's own jobs can be previewed; this matches D6.
- Preview depends on cupsd retaining the document; macOS keeps documents of completed jobs for some time.
- Only the App Sandbox printing entitlement is needed.

## References

[PREV-001](../functional/PREV-001-print-preview.md), [phase 00 CUPS research](../research/phase-00-cups.md), `CUPSClient.documents(jobID:)`.
