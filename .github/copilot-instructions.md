# Sultan POS — Copilot Instructions

## Project Overview

Sultan is a Flutter Point of Sale (POS) application that runs on Android (primary), desktop, and web. On Android it embeds a Rust backend (`libsultan_android.so`) as a foreground service via JNI. The Flutter app communicates with the backend over HTTP at `http://localhost:8721/api`.

---

## Architecture

### Layer Order (dependency direction)

```
UI (pages)
  ↓
Controller (Riverpod Notifier)
  ↓
Repository
  ↓
ApiClient / AuthService
  ↓
Backend (HTTP)
```

### Feature-Based Folder Structure

```
lib/
  main.dart                        # ProviderScope + App
  app/
    app.dart                       # GoRouter + MaterialApp.router
  core/
    constants/api_constants.dart   # Base URL, all API paths
    services/api_client.dart       # HTTP client, auth header, 401 refresh
    services/auth_service.dart     # Secure token storage
    theme/app_theme.dart           # Light/dark Material 3 theme
    widgets/responsive_page.dart   # Mobile/desktop layout wrapper
  features/
    <feature>/
      domain/
        models/                    # Immutable data classes
      data/
        repositories/              # API calls, data access
      presentation/
        controllers/               # Riverpod Notifiers
        <page>.dart                # UI entry point
        mobile/                    # Mobile-specific UI (if needed)
        desktop/                   # Desktop-specific UI (if needed)
        widgets/                   # Shared widgets for this feature
```

---

## Coding Rules

1. **No business logic in widgets.** Controllers manage all state; widgets are dumb.
2. **Domain models are immutable.** Use `final` fields, `const` constructors, `fromJson` factories, `toJson` methods.
3. **One feature = one folder** under `lib/features/`. Never mix feature code.
4. **Use `package:` imports** (not relative) only when crossing feature boundaries. Within a feature, use relative imports.
5. **Repository interfaces** must be the only thing controllers depend on — not `ApiClient` directly.
6. **Responsive pages** use `ResponsivePage` from `core/widgets/responsive_page.dart`. Breakpoint: 900px.

---

## State Management — Riverpod

- Use `Notifier<State>` + `NotifierProvider` for all controllers.
- Use **sealed classes** for state types (e.g., `AuthState`).
- State classes follow the pattern: `FeatureInitial`, `FeatureLoading`, `FeatureLoaded(data)`, `FeatureError(message)`.
- Providers are defined at the **bottom** of the controller file.
- Never use `StateNotifier` — use `Notifier` (Riverpod 2+).

```dart
sealed class ExampleState { const ExampleState(); }
class ExampleInitial extends ExampleState { const ExampleInitial(); }
class ExampleLoading extends ExampleState { const ExampleLoading(); }
class ExampleLoaded extends ExampleState {
  final List<Item> items;
  const ExampleLoaded(this.items);
}
class ExampleError extends ExampleState {
  final String message;
  const ExampleError(this.message);
}

class ExampleController extends Notifier<ExampleState> {
  @override
  ExampleState build() => const ExampleInitial();
}

final exampleControllerProvider = NotifierProvider<ExampleController, ExampleState>(
  ExampleController.new,
);
```

---

## Routing — GoRouter

- All routes are defined in `lib/app/app.dart`.
- Route paths: `/`, `/login`, `/home`, `/<feature>`.
- Navigation: use `context.go('/path')` (replaces stack) or `context.push('/path')` (adds to stack).
- Auth guard: unauthenticated users redirect to `/login` in the `redirect` callback.
- Listen for auth state changes in pages with `ref.listen<AuthState>(authControllerProvider, ...)`.

---

## API Client

- **Singleton:** `ApiClient.instance`
- All paths are defined in `ApiConstants` — never hardcode URLs.
- To change the server URL at runtime: `ApiConstants.setBaseUrl('http://192.168.x.x:8721')`.
- The client auto-attaches `Authorization: Bearer <token>` to every request.
- On `401`, it triggers a silent token refresh then retries once.
- Throws `ApiException(statusCode, message)` on error — catch in repositories, translate to user messages in controllers.

```dart
// In a repository:
final json = await ApiClient.instance.get(ApiConstants.somePath);
// Throws ApiException on 4xx/5xx
```

---

## Authentication Flow

1. **Splash** (`/`) → starts Android server (if on Android) → checks `AuthService.hasTokens()` → routes to `/home` or `/login`.
2. **Login** (`/login`) → `POST /api/auth` → saves `access_token` + `refresh_token` → routes to `/home`.
3. **Silent refresh** → handled automatically by `ApiClient` on 401, transparent to all callers.
4. **Logout** → `DELETE /api/auth` (best-effort) → `AuthService.clearTokens()` → routes to `/login`.

Tokens are stored in `FlutterSecureStorage` (Android encrypted SharedPreferences). On web, fallback is in-memory.

---

## Android Native (JNI)

The native Rust library is loaded via `SultanServer.kt` (`package com.sultan.android`).

Flutter communicates with Android via `MethodChannel('com.sultan.android/server')`:

| Method | Description |
|--------|-------------|
| `start({jwtSecret, port})` | Starts the foreground service + Rust server |
| `stop()` | Sends stop intent to the service |
| `isRunning()` | Returns `bool` from JNI |

Always wrap MethodChannel calls in `try/catch` for `MissingPluginException` (non-Android platforms) and `PlatformException`.

---

## Theme

- Material 3, seed color `Color(0xFF1B5E20)` (dark green).
- `AppTheme.light` / `AppTheme.dark` from `core/theme/app_theme.dart`.
- `FilledButton` minimum height: 48px, border radius: 8px.
- `InputDecoration`: outlined border with 8px radius, filled background.

---

## API Endpoints Reference

Base URL: `http://localhost:8721` (configurable via `ApiConstants.setBaseUrl()`).

| Resource | Path | Notes |
|----------|------|-------|
| Login | `POST /api/auth` | Returns `access_token`, `refresh_token` |
| Refresh | `POST /api/auth/refresh` | Body: `{refresh_token}` |
| Logout | `DELETE /api/auth` | Body: `{refresh_token}` |
| Branch | `/api/branch` | CRUD |
| Category | `/api/category` | CRUD |
| Product | `/api/product` | POST, GET by id, DELETE |
| Customer | `/api/customer` | CRUD + pagination |
| Supplier | `/api/supplier` | CRUD + pagination |
| User | `/api/user` | CRUD + permissions + password |

All endpoints except login require `Authorization: Bearer <token>`.

Default credentials: username `sultan`, password `sultan`.

---

## Testing

All new code must have **>80% test coverage**. Tests live under `test/` mirroring the `lib/` structure.

### Test file locations

| Source file | Test file |
|---|---|
| `lib/features/<name>/domain/models/<model>.dart` | `test/features/<name>/domain/models/<model>_test.dart` |
| `lib/features/<name>/data/repositories/<name>_repository.dart` | `test/features/<name>/data/repositories/<name>_repository_test.dart` |
| `lib/features/<name>/presentation/controllers/<name>_controller.dart` | `test/features/<name>/presentation/controllers/<name>_controller_test.dart` |
| `lib/features/<name>/presentation/<name>_page.dart` | `test/features/<name>/presentation/<name>_page_test.dart` |
| `lib/core/...` | `test/core/...` |

### What to test per layer

- **Models**: `fromJson` round-trip, optional fields, edge cases.
- **Repositories**: mock `ApiClient` (via constructor injection) — test success path, `ApiException` handling.
- **Controllers**: override the repository provider — test each state transition (`Initial → Loading → Loaded`, error path).
- **Pages**: pump with `ProviderScope` overrides — assert key widgets render for each state.

### Mocking conventions

- Use `mocktail` — no code generation required.
- Mock `http.Client` via `package:http/testing.dart` `MockClient` for `ApiClient` tests.
- Inject dependencies via constructor (all repositories and `ApiClient`/`AuthService` support this).

```dart
// Repository test pattern
final mockClient = MockApiClient();
final repo = FeatureRepository(apiClient: mockClient);

// Controller test pattern
final container = ProviderContainer(
  overrides: [featureRepositoryProvider.overrideWithValue(mockRepo)],
);
addTearDown(container.dispose);
```

### Running tests with coverage

```bash
flutter test --coverage
# Check coverage for a specific file:
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

CI enforces coverage via SonarQube — the gate fails if new code drops below 80%.

---

## Code Quality Rule

After **every** file modification, always run:

```bash
flutter analyze --fatal-infos
```

Fix all reported issues before considering the change done. This catches lint warnings (`unnecessary_underscores`, `unused_import`, etc.) that would fail CI.

---

## Adding a New Feature Checklist

1. Create `lib/features/<name>/domain/models/<model>.dart` — immutable model with `fromJson`/`toJson`.
2. Create `lib/features/<name>/data/repositories/<name>_repository.dart` — calls `ApiClient`.
3. Add path to `ApiConstants` in `core/constants/api_constants.dart`.
4. Create `lib/features/<name>/presentation/controllers/<name>_controller.dart` — `Notifier` with sealed state.
5. Create `lib/features/<name>/presentation/<name>_page.dart` — uses `ResponsivePage` if needed.
6. Add route to `GoRouter` in `lib/app/app.dart`.
7. Write tests (see **Testing** section above):
   - `test/features/<name>/domain/models/<model>_test.dart` — model `fromJson`/`toJson`.
   - `test/features/<name>/data/repositories/<name>_repository_test.dart` — success + error paths.
   - `test/features/<name>/presentation/controllers/<name>_controller_test.dart` — all state transitions.
   - `test/features/<name>/presentation/<name>_page_test.dart` — key widget assertions per state.
8. Run `flutter test --coverage` and verify >80% coverage on new files.
9. Run `flutter analyze --fatal-infos` and fix any issues.
