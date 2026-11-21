# Rawana Passenger App

Flutter passenger ride-hailing app for Rawana (Afghanistan). This folder is a standalone repo.

Shared UI, API client, auth, maps, and l10n live in `packages/rawana_core` (vendored in this repo).

## Prerequisites

- Flutter 3.x (SDK ^3.11.0)
- Android Studio and/or Chrome
- A running Rawana backend (`backend_api` on port 7000)

## Setup

```powershell
copy .env.example .env
flutter pub get
```

Edit `.env` with your API URL and public Supabase keys. Never put service-role keys or FCM private keys here.
Config is compiled in with `--dart-define-from-file`; nothing is bundled as an asset.

| Device | `API_URL` |
|--------|-----------|
| Android emulator | `http://10.0.2.2:7000/api` |
| Chrome / web | `http://localhost:7000/api` |
| Physical device | `http://YOUR_PC_IP:7000/api` |

### Google Maps key (not tracked in git)

- Android: add `MAPS_API_KEY=...` to `android/local.properties` (or set the `MAPS_API_KEY` env var).
- iOS: copy `ios/Flutter/Secrets.xcconfig.example` to `ios/Flutter/Secrets.xcconfig` and fill it in.

## Run

```powershell
flutter run -d emulator-5554 --dart-define-from-file=.env
```

Chrome:

```powershell
flutter run -d chrome --dart-define-from-file=.env --dart-define=API_URL=http://localhost:7000/api
```

`APP_ENV` defaults to `dev` for debug builds and `prod` for release builds. Demo login (`ENABLE_DEMO_LOGIN`)
and OTP hints (`DEV_MODE_HINT`) only work in debug builds or builds with `APP_ENV=dev`.

Create an account via **Sign up**. After sign-in the app calls `POST /api/auth/sync-profile` so the admin portal can list the user.

## Release

```powershell
copy env\prod.example.json env\prod.json   # fill in, git-ignored
flutter build appbundle --release --dart-define-from-file=env/prod.json --obfuscate --split-debug-info=build/symbols
```

- Release builds refuse to start unless `API_URL` is `https` and Supabase keys are set.
- Gradle refuses to build a release without `android/key.properties` (see `key.properties.example`).
  For a local smoke build only, set `RAWANA_ALLOW_DEBUG_SIGNING=true`.
- Crash reports go to Firebase Crashlytics when `google-services.json` / `GoogleService-Info.plist` are present.
- Upload `build/symbols` to Crashlytics after each release build, and keep it with the release tag.
- Store submission, owner actions and the device test matrix: `backend_api/Docs/RELEASE_CHECKLIST.md` and `backend_api/Docs/DEVICE_TEST_MATRIX.md`.
- Changes per version: `CHANGELOG.md`.

Firebase Android/iOS config can be generated from the backend repo (`npm run firebase:provision`) when this folder sits next to `backend_api`.
