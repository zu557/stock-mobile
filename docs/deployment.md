# Build and deployment

## Before deploying

Deploy the existing Next.js backend and PostgreSQL database separately from the Flutter client. Configure the backend's production environment and apply its Prisma migrations. The Flutter app must use the public HTTPS API origin; do not ship a localhost URL or credentials in `--dart-define` values.

For Flutter Web, configure `MOBILE_WEB_ORIGIN` in the backend to the exact deployed Flutter site origin. The same value is used by API CORS and Better Auth trusted-origin configuration. Restart/redeploy the backend after changing it.

## Flutter Web

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
```

Publish the generated `build/web` directory to a static host. Configure that host to serve `index.html` for app routes such as `/products` and `/settings/categories`, so GoRouter URLs work after a page refresh. Replace `https://api.example.com` with the actual HTTPS backend origin.

## Android

Local release build commands:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Artifacts are written under `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/` respectively.

**The current Android project is not ready for a store release.** Before distributing it:

1. Add `android.permission.INTERNET` to `android/app/src/main/AndroidManifest.xml`. The repository currently adds it only to debug and profile manifests.
2. Replace the template `applicationId`/namespace `com.example.flutter_application_1` with the app's permanent unique ID.
3. Replace the release build's debug-key signing configuration with a protected release keystore and signing configuration. Never commit the keystore or its passwords.
4. Change the launcher label from `flutter_application_1` and review app icon/branding.
5. Use a deployed HTTPS API and test the signed release build on a physical device.

`pubspec.yaml` currently provides version `1.0.0+1`; update the version/build number for each release. Do not use local HTTP or development credentials in a store build.

## iOS

Build and signing require macOS with Xcode and an Apple signing identity. From macOS:

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```

Set the permanent bundle identifier and signing team in Xcode, use HTTPS, and test session storage and sign-in on an actual device before distribution. iOS release signing has not been configured or verified in this repository.

## Backend release checklist

- Set production `DATABASE_URL` and other backend-required environment settings in the hosting platform, not in source control.
- Apply Prisma migrations using `prisma7.config.ts` as documented in [Setup](setup.md).
- Configure `MOBILE_WEB_ORIGIN` to the Flutter Web origin when serving the web client. Native apps do not need CORS, but Better Auth and API URLs still need production configuration.
- Use a valid HTTPS certificate and verify auth, role checks, product activation, purchase completion, and sales against production-like data before release.
