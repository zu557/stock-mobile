# Development setup

## Requirements

- Flutter SDK with Dart `3.13.2` or newer, as constrained by `pubspec.yaml`.
- Chrome for the documented Flutter Web development workflow.
- Node.js and npm for the Next.js backend. Use a Node version supported by the installed Next.js 16 release.
- PostgreSQL reachable by the backend.
- Android Studio and an Android SDK for Android emulator/device builds. iOS builds require macOS and Xcode.

Check local tools before starting:

```powershell
flutter doctor -v
flutter --version
node --version
npm --version
```

## Configure and run the backend

The backend is the sibling `stock-flow` repository. From the Flutter project root:

```powershell
cd ..\..\stock-flow
npm ci
```

Create or update the backend's local `.env` without committing it. `DATABASE_URL` is required by `lib/prisma.ts`; provide a PostgreSQL connection string for your local database. The backend does not currently include a checked-in `.env.example`, so inspect its runtime configuration before deploying.

Apply database migrations and generate the Prisma client with the repository's Prisma 7 config:

```powershell
npx prisma migrate deploy --config prisma7.config.ts
npx prisma generate --config prisma7.config.ts
```

For a local database, the project has an optional seed script:

```powershell
npm run db:seed
```

Review `prisma/seed.ts` and set your own local seed credentials before running it. Do not use seed defaults in a shared or production environment.

Start the backend:

```powershell
npm run dev
```

The documented local API URL is `http://localhost:3000`.

## Run Flutter Web in Chrome

Open a second terminal at the Flutter project root:

```powershell
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000
```

The web origin must be exactly `http://localhost:5173` for the backend's development CORS and Better Auth trusted-origin defaults. `localhost` and `127.0.0.1`, or different ports, are distinct browser origins. If you change the Flutter port, set `MOBILE_WEB_ORIGIN` to that exact origin in the backend environment and restart Next.js.

## Run on Android

List available devices and launch on an emulator:

```powershell
flutter devices
flutter run -d <emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` is the Android emulator's route to the host computer. For a physical Android device, use the computer's LAN address instead, for example `http://192.168.1.20:3000`. The backend must be reachable from the LAN (you may need `npm run dev -- --hostname 0.0.0.0` and an appropriate firewall rule). Use the actual address for your network.

The Android debug and profile manifests include Internet permission; the main/release manifest currently does not. Add Internet permission to the main manifest before relying on a release build to access the API. Local HTTP can also be blocked by Android cleartext-traffic policy; production must use HTTPS.

## Useful checks

```powershell
dart format lib
flutter analyze
flutter test
```

The test file currently covers a dashboard smoke test and product parsing, alongside a legacy workout-model test. It does not replace testing each screen against a running backend.
