# Xcode 26 + macOS Tahoe Migration Status

## Current Baseline (Implemented)

- App target is Apple silicon-first (`ARCHS = arm64`) with Intel excluded for the app target in project build settings.
- App deployment target is macOS 26.0 (Tahoe baseline) for the main target.
- Unified design adoption is explicit via `UIDesignRequiresCompatibility = NO` in generated Info.plist build settings.
- Liquid Glass visual system is used across primary app surfaces.
- App and website focus enforcement uses a blocklist model.
- Website blocking supports:
  - Browser-level active-tab enforcement for Safari/Chrome-family browsers.
  - Optional system-wide `/etc/hosts` enforcement (admin prompt when needed).

## Runtime Controls

- `enableSystemWideHostsBlocking` controls hosts-based enforcement.
- Default behavior is enabled when no user preference is stored.
- If hosts enforcement cannot be applied, browser-level domain blocking still runs.

## Platform Readiness Surface

The Settings screen now shows:

- Architecture (Apple Silicon vs Intel)
- Runtime mode (Native vs Rosetta)
- Operating system and support window
- App version/build

## Recommended Next Upgrades

1. Move Swift language mode from `SWIFT_VERSION = 5.0` to Swift 6 in a staged branch and resolve strict concurrency diagnostics.
2. Introduce string catalogs (`.xcstrings`) for user-facing text and progressively localize UI copy.
3. Add UI regression tests for key focus flows (task activation, app blocking, domain blocking alerts).
4. Add a release checklist for Tahoe+ including notarization, sandbox validation, and Apple silicon runtime smoke tests.

## Notes

This migration status is focused on practical readiness for Xcode 26/Tahoe-era app behavior while preserving incremental modernization paths for Swift language mode and localization.
