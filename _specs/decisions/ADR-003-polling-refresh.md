---
id: ADR-003
title: Refresh the queue by polling every 2 seconds
type: adr
status: proposed
date: 2026-11-16
---

# ADR-003 — Refresh the queue by polling every 2 seconds

## Status

`proposed`

## Context

The queue must update when jobs appear or disappear (D1). CUPS offers event subscriptions, but their notifiers (`rss`, `dbus`, mail) do not deliver push events to a sandboxed app on macOS without additional infrastructure.

## Decision

We poll cupsd every 2 seconds while the window is open: printers, the user's active jobs on all printers and the completed jobs of the selected printer. The UI is only updated when the data changed.

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| CUPS subscriptions with `Get-Notifications` polling | Still polling, more complex, subscriptions expire. |
| Watching the spool directory | Not readable (see ADR-001). |

## Consequences

- Changes appear within about 2 seconds.
- A small, constant load on the local cupsd while the app is open; the completed-job request grows with the size of the history.

## References

[QUEUE-001](../functional/QUEUE-001-queue-overview.md), `QueueStore.run()`.
