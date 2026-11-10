# Stock-Flow mobile

Flutter client for the existing Stock-Flow Next.js inventory API. The app uses Dio for HTTP, Riverpod for state and dependency injection, GoRouter for navigation, and Flutter Secure Storage for the Better Auth bearer token.

## Implemented today

- Email and password sign-in, session restoration, protected navigation, and sign-out.
- Product search, category and stock-status filters, pagination, create and edit forms, and admin-only activate/deactivate actions.
- Category search and category management screens.
- Purchase listing, search, details, draft editing, completion, and draft deletion.
- Sales listing, search and date filtering, details, and sale creation.
- Role-based navigation and action visibility.

The Home screen is still a placeholder. Inventory summaries, stock adjustments, stock movement history, and reports have no Flutter screens yet. See [User guide](docs/user-guide.md) for current behavior and role limits.

## Quick start

Start the backend in one terminal from this repository directory:

```powershell
cd ..\..\stock-flow
npm ci
npm run dev
```

Start Flutter Web in another terminal. The port is set to `5173` because the backend development CORS and Better Auth trusted-origin configuration allow `http://localhost:5173` by default.

```powershell
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000
```

The backend also needs a configured `DATABASE_URL`, a reachable PostgreSQL database, and its Prisma migrations applied. Follow [Setup](docs/setup.md) for the complete steps and native-device URLs.

## Documentation

1. [Architecture](docs/architecture.md)
2. [Setup](docs/setup.md)
3. [API integration](docs/api-integration.md)
4. [Deployment](docs/deployment.md)
5. [User guide](docs/user-guide.md)

## Project checks

```powershell
dart format lib
flutter analyze
flutter test
```

The test suite currently mixes Stock-Flow smoke/model checks with legacy workout-model coverage. A passing suite does not mean every screen or backend integration has been exercised.
