---
id: ADR-004
title: Store the language choice as the per-app AppleLanguages setting
type: adr
status: proposed
date: 2026-11-16
---

# ADR-004 — Store the language choice as the per-app `AppleLanguages` setting

## Status

`proposed`

## Context

The user wants to choose the app language inside the app (D12). Text comes from SwiftUI views, `String(localized:)` in non-UI code, and system-provided menus.

## Decision

We store the choice as `AppleLanguages` in the app's own preferences (the same setting macOS uses for a per-app language) and remove it for "System Language". The choice takes effect after a restart; the Settings window offers "Restart Now", which launches a new instance and quits the current one.

## Alternatives considered

| Alternative | Why not chosen |
| --- | --- |
| SwiftUI `\.locale` environment override | Changes only SwiftUI-localized text; `String(localized:)` messages and system menus would stay in the old language. |
| Custom bundle lookup for every string | Large change and still does not cover system menus. |

## Consequences

- All texts, including system menus, follow the choice consistently.
- A restart is needed after a change.
- The setting is shared with System Settings' per-app language.

## References

[I18N-001](../functional/I18N-001-localization.md), `LanguageSettings.swift`.
