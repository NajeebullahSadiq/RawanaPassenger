# Changelog

## [1.0.0+6] - 2026-11-20

First production release of the Rawana passenger app.

### Added
- Redesigned booking flow and every screen on the shared Rawana design system, in English, Dari and Pashto with full right-to-left layout.
- Ride history, trip detail with receipt, scheduled rides, saved places, emergency contacts, notifications inbox and help.
- Permission rationale sheets before the system location and notification prompts.
- Offline banner, automatic retry of failed reads, and a clear message when a session expires.

### Changed
- Inter and Bahij Zar fonts are bundled, so text renders the same offline.
- Text scaling is capped at 1.3× so layouts stay usable at the largest system font size.
- Release builds read configuration from `--dart-define-from-file`; no `.env` file ships in the app.

### Security and stability
- Crash reporting with Firebase Crashlytics; obfuscated release builds with R8 shrinking.
- Demo login is available only in debug builds with `ENABLE_DEMO_LOGIN`.
- Release builds refuse to run without an https API and refuse to build without a signing key.
