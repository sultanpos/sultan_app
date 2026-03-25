# Sultan POS

A Flutter Point of Sale (POS) application targeting Android (primary), Linux desktop, and web. On Android the app embeds a Rust backend (`libsultan_android.so`) as a foreground service via JNI and communicates with it over HTTP at `http://localhost:8721/api`.

## Features

- JWT authentication with silent token refresh
- Secure, per-device JWT secret generated on first launch and stored in encrypted storage
- Android foreground service keeps the backend alive when the app is backgrounded
- Responsive layout (mobile / desktop breakpoint at 900 px)
- Material 3 theme (seed colour: dark green `#1B5E20`)
- Riverpod 2 state management with sealed state classes
- GoRouter navigation with auth guard

## Requirements

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.11.3 |
| Dart | ≥ 3.11.3 |
| Java (Android builds) | 17 (Temurin recommended) |
| Android SDK | API 21+ |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on a connected device / emulator
flutter run

# Run on Linux desktop
flutter run -d linux
```

## Building

```bash
# Android debug APK
flutter build apk --debug

# Android release APK (requires signing config)
flutter build apk --release

# Linux desktop
flutter build linux
```

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Static analysis (must pass before committing)
flutter analyze --fatal-infos
```

## Project Structure

```
lib/
  main.dart                        # Entry point — ProviderScope + App
  app/
    app.dart                       # GoRouter + MaterialApp.router
  core/
    constants/api_constants.dart   # Base URL (configurable) + all API paths
    services/api_client.dart       # HTTP client, Bearer auth, 401 silent refresh
    services/auth_service.dart     # Secure token + JWT secret storage
    theme/app_theme.dart           # Material 3 light/dark themes
    widgets/responsive_page.dart   # Mobile/desktop layout wrapper
  features/
    auth/                          # Login, AuthController, AuthRepository
    server/                        # Server start/stop control page
    splash/                        # Splash + initialisation
```

## Architecture

```
UI (pages)
  ↓
Controller (Riverpod Notifier + sealed states)
  ↓
Repository
  ↓
ApiClient / AuthService
  ↓
Backend (HTTP · localhost:8721)
```

See [.github/copilot-instructions.md](.github/copilot-instructions.md) for full coding conventions.

## Default Credentials

| Field | Value |
|-------|-------|
| Username | `sultan` |
| Password | `sultan` |

> Change these in the backend configuration before deploying to production.

## Backend URL

The base URL defaults to `http://localhost:8721`. To point the app at a different host (e.g. for development over LAN):

```dart
ApiConstants.setBaseUrl('http://192.168.1.100:8721');
```

## CI / CD

The GitHub Actions workflow at [.github/workflows/ci.yml](.github/workflows/ci.yml) runs on every pull request:

1. `flutter analyze --fatal-infos`
2. `flutter test --coverage`
3. SonarQube scan (requires `SONAR_TOKEN` and `SONAR_HOST_URL` secrets)
4. `flutter build apk --debug` — artifact uploaded for 14 days

## License

GNU General Public License v2.0 — see [LICENSE](LICENSE).
