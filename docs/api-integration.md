# API integration

## Shared client configuration

Feature services receive the shared `Dio` instance from `dioProvider`. The API base URL is configured by `--dart-define=API_BASE_URL=...`; do not include `/api` at the end. Defaults:

| Target | Default base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:3000` |
| Chrome, iOS simulator, other targets | `http://localhost:3000` |

Use `API_BASE_URL` for a physical device, custom local host, or production HTTPS URL. Timeouts are 10 seconds for connect, send, and receive. The client sends JSON `Accept` and `Content-Type` headers.

## Authentication contract

The backend uses Better Auth with its bearer plugin. The Flutter service calls:

| Method and path | Behavior |
| --- | --- |
| `POST /api/auth/sign-in/email` | Sends `{ "email": "…", "password": "…", "rememberMe": true }`; response must include `user`. The bearer token is read from the `set-auth-token` response header. |
| `GET /api/auth/get-session` | Reads the current session; the app expects an object containing `user`. |
| `POST /api/auth/sign-out` | Sends `{}` as JSON and clears local token state after the request. |

The interceptor stores the token through Flutter Secure Storage and attaches it to requests as `Authorization: Bearer <token>`. A session token is not assumed to be returned in the JSON response body. The backend must keep the bearer plugin enabled and expose the `set-auth-token` response header to Flutter Web.

## Implemented feature endpoints

Dynamic IDs below are URL-encoded by the Flutter service.

### Products

| Method and path | Request/query | Response used by Flutter |
| --- | --- | --- |
| `GET /api/products` | `search`, `page`, `limit`, `categoryId`, `status` query parameters | `{ data: Product[], total, page, limit, totalPages }` |
| `POST /api/products` | `{ code, name, description, unit, reorderLevel, categoryId }` | Product object |
| `PATCH /api/products/:id` | Same product fields as create | Product object |
| `POST /api/products/:id/deactivate` | Empty JSON object `{}` | `{ isActive: false }` |
| `POST /api/products/:id/activate` | Empty JSON object `{}` | `{ isActive: true }` |

Product units are `PIECE`, `BOX`, `PACK`, `KG`, `LITER`, and `METER`. Stock status values are `OUT_OF_STOCK`, `LOW`, and `IN_STOCK`. The backend calculates current stock and status. Activate and deactivate actions require an admin on the backend as well as in the UI.

### Categories

| Method and path | Request/query | Response used by Flutter |
| --- | --- | --- |
| `GET /api/categories` | Optional `search` query | Array of categories |
| `POST /api/categories` | `{ name, description }` | Category object |
| `PATCH /api/categories/:id` | `{ name, description }` | Category object |
| `DELETE /api/categories/:id` | No body | Success response; Flutter does not parse the body |

### Purchases

| Method and path | Request/query | Response used by Flutter |
| --- | --- | --- |
| `GET /api/purchases` | Optional `search` (reference number) | `{ data: Purchase[] }` |
| `GET /api/purchases/:id` | — | `{ data: Purchase }` |
| `POST /api/purchases` | `{ purchasedAt, status, notes, items: [{ productId, quantity, unitCost }] }` | `{ data: Purchase }` |
| `PATCH /api/purchases/:id` | Purchase fields and items | Flutter ignores the response body |
| `POST /api/purchases/:id/complete` | No body | Flutter ignores the response body |
| `DELETE /api/purchases/:id` | No body | Flutter ignores the response body |

Purchases are created as drafts by the mobile model. Completing a draft invokes backend stock-movement/business logic; the client does not calculate stock changes.

### Sales

| Method and path | Request/query | Response used by Flutter |
| --- | --- | --- |
| `GET /api/sales` | Optional `q`, `from`, and `to` (`YYYY-MM-DD`) query parameters | Array of sales |
| `POST /api/sales` | `{ soldAt, status, notes, items: [{ productId, quantity, unitPrice }] }` | Sale object |

## Error and authorization behavior

- Backend endpoints enforce authentication and role permissions; hiding a button in Flutter is only a UI convenience.
- Backend error responses commonly contain an `error` field; Better Auth or other handlers may return `message`. `ApiException.messageFor` extracts these when Dio receives a JSON error response.
- Protected API 401 responses clear the stored token and notify auth state. Authentication endpoint 401s remain available to the sign-in/session flow.
- Product deactivate/activate use explicit admin checks in the API routes. Other permissions follow the backend's ABAC policies.

## Flutter Web CORS

The backend's `next.config.ts` sets API CORS headers. In development its origin defaults to `http://localhost:5173`; `lib/auth.ts` also uses that as Better Auth's trusted origin. For another web origin, configure `MOBILE_WEB_ORIGIN` on the backend to the exact origin and restart it. Native Android/iOS requests do not use browser CORS.

## Backend routes not yet integrated in Flutter

The backend also exposes dashboard, inventory summary/movements, stock adjustments, reports, and user-management routes. No Flutter service/screen currently consumes these APIs. Add each integration after checking its current backend schema and permission rules; do not infer a contract from this list alone.
