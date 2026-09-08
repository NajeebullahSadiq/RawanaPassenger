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

| Device | `API_URL` |
|--------|-----------|
| Android emulator | `http://10.0.2.2:7000/api` |
| Chrome / web | `http://localhost:7000/api` |
| Physical device | `http://YOUR_PC_IP:7000/api` |

## Run

```powershell
flutter run -d emulator-5554
```

Chrome:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:7000/api
```

`--dart-define` flags override `.env` values.

Create an account via **Sign up**. After sign-in the app calls `POST /api/auth/sync-profile` so the admin portal can list the user.

## Release

```powershell
flutter build appbundle --release
```

Firebase Android/iOS config can be generated from the backend repo (`npm run firebase:provision`) when this folder sits next to `backend_api`.
