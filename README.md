# WeBuddhist App

A modern Flutter app for learning, sharing, and live collaboration.

## 🚀 Project Goal
WeBuddhist App is designed to help users learn, live, and share knowledge interactively. It features a beautiful UI, supports both light and dark themes, and is built with best Flutter practices.

## 🛠 Features
- Light and Dark theme support with toggle
- Modern Flutter architecture
- Easy to customize and extend

## 📦 Getting Started

### 1. Clone the Repository
```sh
git clone https://github.com/your-username/flutter_pecha.git
cd flutter_pecha
```

### 2. Install Dependencies
```sh
flutter pub get
```

### 3. Environment Setup
Create environment files from the template:
```sh
cp .env.example .env.dev
cp .env.example .env.staging
cp .env.example .env.prod
```
Edit each file with the appropriate values for that environment.

Each flavor should use its own PostHog project token:

| Variable | Description |
|----------|-------------|
| `POSTHOG_API_KEY` | PostHog project API key for this flavor |
| `POSTHOG_HOST` | PostHog ingest host (default `https://us.i.posthog.com`) |
| `POSTHOG_ENABLED` | Set to `false` to disable analytics locally |

### 4. Run the App

**Android**
```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Build APK:
```sh
flutter build apk --flavor dev -t lib/main_dev.dart
flutter build apk --flavor staging -t lib/main_staging.dart
flutter build apk --flavor prod -t lib/main_prod.dart
```

Build App Bundle:
```sh
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

**iOS**
```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

**macOs**
```sh
flutter run -d macos --flavor dev --target lib/main_dev.dart                                                                                                                  
flutter run -d macos --flavor staging --target lib/main_staging.dart                                                                                                          
flutter run -d macos --flavor prod --target lib/main_prod.dart        
```

Build IPA:
```sh
flutter build ios --flavor prod -t lib/main_prod.dart
```

> **Note:**
> - For iOS, ensure you have Xcode installed and have granted the necessary permissions (see [Flutter macOS setup](https://docs.flutter.dev/get-started/install/macos)).
> - For Android, ensure Android Studio and an emulator/device are set up.

### 5. Adding Localizations

The app uses Flutter's built-in internationalization (l10n) with ARB files for translations.

**Localization files location:**
`lib/core/l10n/`

**To add a new translation string:**

1. Add the key to all ARB files (`app_en.arb`, `app_bo.arb`, `app_zh.arb`):

```json
// app_en.arb
"my_new_key": "My English text",

// app_bo.arb
"my_new_key": "My Tibetan text",

// app_zh.arb
"my_new_key": "My Chinese text",
```

2. Generate localization files:
```sh
flutter gen-l10n
dart run tool/generate_tolgee_bridge.dart
```

The second command regenerates the Tolgee bridge so the new key can also be
updated over the air. CI fails if it is skipped — see
[Over-the-air translations](#-over-the-air-translations-tolgee).

3. Use in your widget:
```dart
import 'package:flutter_pecha/core/extensions/context_ext.dart';

// Access translation via context.l10n
Text(context.l10n.my_new_key)
```

**For translations with parameters:**

```json
// app_en.arb
"greeting": "Hello {name}",
"@greeting": {
  "placeholders": {
    "name": {"type": "String"}
  }
}
```

Usage:
```dart
Text(context.l10n.greeting('John'))
```

## 🌍 Over-the-air translations (Tolgee)

Translation text can be corrected in [Tolgee](https://tolgee.io) and picked up
by installed apps without shipping a new release. Nothing changes at call
sites: `context.l10n.my_key` keeps working exactly as before.

### How it works

`tool/generate_tolgee_bridge.dart` reads the gen-l10n output and emits
`TolgeeAppLocalizations`, a subclass of `AppLocalizations` that overrides every
key. Each override asks Tolgee first and falls back to the bundled ARB value.
It is registered in `main.dart` in place of `AppLocalizations.delegate`.

The ARB files stay the source of truth in git and are the offline fallback;
Tolgee is an override layer on top of them.

```
context.l10n.my_key
  -> TolgeeAppLocalizations.my_key      (generated override)
     -> Tolgee CDN value                (if loaded and for the right language)
     -> bundled ARB value               (otherwise)
```

Because the bundled ARB is always the fallback, the app behaves exactly as it
did before Tolgee whenever the integration is disabled, offline, still
fetching, or missing a key.

The payload is fetched and parsed by the app rather than by the Tolgee SDK,
which cannot serve a multi-part language tag such as `bo-IN`. See
[docs/tolgee.md](docs/tolgee.md#why-the-sdk-is-not-used).

### Configuration

Set these in `.env.dev` / `.env.staging` / `.env.prod`:

| Variable | Purpose |
| --- | --- |
| `TOLGEE_API_URL` | No longer read by the app; safe to drop from `.env` |
| `TOLGEE_API_KEY` | Read-only scoped project key. Acts as a feature flag — Content Delivery itself is public |
| `TOLGEE_CDN_URL` | Content Delivery base URL |
| `TOLGEE_ENABLED` | Optional override; defaults to on when key and CDN URL are set |

Leaving `TOLGEE_API_KEY` empty disables the integration and the app uses the
bundled ARB only. This is also the kill switch if a bad translation ships.

> **The API key ships inside the app.** `.env` files are bundled as assets, so
> anything in them can be extracted from a release build. Use a project key
> scoped to `translations.view` and `languages.view` only — a leaked
> write-capable key would let anyone rewrite the app's copy.

### Tolgee project requirements

- App UI locales use bare codes (`en`, `bo`, `zh`, `hi`, `mn`, `ne`). Tolgee
  Content Delivery language tags (and CDN filenames) must be `en`, `bo-IN`,
  `zh-Hant-TW`, `hi`, `mn`, `ne` — the app maps `bo`/`zh` to those CDN tags
  via `TolgeeLocaleMap`. Publishing `bo.json` or `zh.json` will 404.
- Enable ICU placeholder support so plural strings are served as ICU source.
- Content Delivery must export **flat** JSON (nesting and arrays disabled),
  one file per language at `<TOLGEE_CDN_URL>/<tag>.json`. The SDK's CDN parser
  expects `{"key": "value"}` and cannot read nested objects.

### When updates apply

Translations are fetched on app start and on language change. An edit in
Tolgee reaches users on their next app launch; there is no live push. A cold
start with no network shows the bundled ARB text.

### ARB sync (manual and CI)

Bundled ARB files stay the offline fallback; the Tolgee CDN is the OTA
override. Sync uses a **second** key that must never live in `.env.*`:

| Key | Where | Role |
| --- | --- | --- |
| `TOLGEE_API_KEY` | `.env.*` (ships in app) | Read-only runtime OTA |
| `TOLGEE_SYNC_API_KEY` | shell env or GitHub Actions secret only | Local / CI ARB ↔ Tolgee sync (write) |

You can sync manually with `dart run tool/tolgee_sync.dart ...`, or let the
**Tolgee Sync** workflow do it on a schedule / via **Run workflow**. Keep both.
CI opens a reviewable PR — it does not merge to `develop` by itself.

Full command order, write-key creation (Tolgee → Project API Keys → + API Key),
rotate-after-exposure guidance, and CI auto-update risks are in
[Tolgee integration and sync](docs/tolgee.md).

## ⚙️ Project Structure

This project follows **Clean Architecture** principles with clear separation of concerns across three main layers.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  UI Components (Screens, Widgets)                       │   │
│  │  State Management (Riverpod Notifiers/Providers)        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Entities (Business Objects)                            │   │
│  │  Use Cases (Business Logic)                             │   │
│  │  Repository Interfaces (Contracts)                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Repository Implementations                             │   │
│  │  Data Sources (API, Local Storage)                      │   │
│  │  Models (DTOs for serialization)                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                            │
│         (Auth0, Firebase, HTTP, Storage, etc.)                 │
└─────────────────────────────────────────────────────────────────┘
```

### Folder Structure

```
lib/
├── core/                    # Shared infrastructure & utilities
│   ├── config/              # App configuration
│   ├── di/                  # Dependency injection
│   ├── error/               # Error handling (Failures)
│   ├── network/             # Network utilities
│   ├── services/            # External service integrations
│   ├── storage/             # Local storage utilities
│   └── theme/               # App theming
│
├── features/                # Feature-based modules
│   └── auth/                # ← Authentication feature example
│       ├── domain/          # Business logic (no dependencies)
│       ├── data/            # Data implementation
│       └── presentation/    # UI & state management
│
└── shared/                  # Cross-cutting concerns
    ├── data/                # Shared data layer utilities
    ├── domain/              # Shared domain logic
    ├── presentation/        # Shared UI components
    └── widgets/             # Reusable widgets
```

### Auth Flow Example

Here's how authentication follows clean architecture through all layers:

#### 1. Domain Layer (`features/auth/domain/`)
*Pure business logic with no framework dependencies*

```
domain/
├── entities/
│   └── user.dart                    # User business entity
├── repositories/
│   └── auth_repository.dart         # Repository interface (contract)
└── usecases/
    ├── login_usecase.dart           # Login business logic
    ├── get_current_user_usecase.dart
    └── logout_usecase.dart
```

**Key points:**
- `User` entity: Pure Dart class with business properties
- `AuthRepository`: Abstract interface defining data operations
- `LoginUseCase`: Orchestrates login logic, returns `Either<Failure, User>`

#### 2. Data Layer (`features/auth/data/`)
*Implements domain contracts, handles external dependencies*

```
data/
├── models/
│   └── user_model.dart              # DTO for JSON serialization
├── datasources/
│   └── auth_remote_datasource.dart  # API/Service calls
└── repositories/
    └── auth_repository_impl.dart    # Implements AuthRepository
```

**Key points:**
- `UserModel`: Handles JSON ↔ Dart conversion
- `AuthRemoteDataSource`: Makes actual API calls
- `AuthRepositoryImpl`: Implements domain interface, uses datasource

#### 3. Presentation Layer (`features/auth/presentation/`)
*UI and state management*

```
presentation/
├── providers/
│   ├── auth_notifier.dart           # State management
│   ├── auth_providers.dart          # DI setup
│   └── use_case_providers.dart      # Use case providers
├── screens/
│   └── login_page.dart              # Login UI
└── widgets/
    └── login_form.dart              # Reusable form widget
```

**Key points:**
- `AuthNotifier`: Manages auth state, calls use cases
- `authProviders`: Wire up dependencies using Riverpod
- `LoginPage`: UI that consumes state via providers

### Key Principles

| Layer | Responsibility | Dependencies |
|-------|---------------|--------------|
| **Domain** | Business rules & logic | None (pure Dart) |
| **Data** | Data sources & persistence | Domain, external services |
| **Presentation** | UI & state management | Domain (via use cases) |

### Benefits

- **Testable**: Each layer can be unit tested independently
- **Maintainable**: Changes in one layer don't break others
- **Scalable**: Easy to add new features following same pattern
- **Flexible**: Swap implementations (e.g., change API) without affecting business logic



## Dio Implementation
Dio is a powerful HTTP client for Dart. Think of it as a supercharged `http` package with built-in support for interceptors, retries, timeout handling, and request transformation.

### Why Dio Over `http` Package?

| Feature | `http` package | Dio |
|---------|----------------|-----|
| Interceptors | No | Yes (we use this heavily) |
| Global configuration | Limited | Full |
| Automatic retries | Manual | Built-in |

### Our DioClient Structure

**Location**: `lib/core/network/dio_client.dart`

```dart
class DioClient {
  DioClient({
    required AuthInterceptor authInterceptor,
    required RetryInterceptor retryInterceptor,
    // ... other interceptors
  }) : _dio = Dio(options) {
    // Interceptor order is critical
    _dio.interceptors.addAll([
      authInterceptor,      // 1. Add auth headers first
      cacheInterceptor,     // 2. Check cache
      retryInterceptor,     // 3. Handle 401 & network errors
      errorInterceptor,     // 4. Convert errors
      loggingInterceptor,   // 5. Log final result
    ]);
  }
}
```

**Why this order?** Each interceptor processes the request in sequence. Auth must run first to add tokens before the request goes out.

### Interceptor Chain: How Requests Flow

```
Request:  Auth → Cache → Retry → Error → Log → Server
Response: Log → Error → Retry → Cache → Auth → UI
```

### Interceptor 1: AuthInterceptor

**What it does**: Checks if the API endpoint requires authentication, adds the auth token.

```dart
// lib/core/network/interceptors/auth_interceptor.dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  // Only add auth for protected routes
  if (ProtectedRoutes.isProtected(options.path)) {
    final token = await _tokenProvider.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }
  handler.next(options);  // Pass to next interceptor
}
```

**Key point**: Uses `TokenProvider` abstraction so we can swap token sources without changing this code.

### Interceptor 2: RetryInterceptor

**What it does**: Handles 401 (token expired) errors by refreshing the token and retrying the request.

```dart
// lib/core/network/interceptors/retry_interceptor.dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  // Handle 401 - Token expired
  if (err.response?.statusCode == 401) {
    if (_isRefreshing) {
      // Already refreshing, queue this request
      _refreshQueue.add(_RetryRequest(err, handler));
      return;
    }

    _isRefreshing = true;
    final newToken = await _authService.refreshIdToken();

    // Retry all queued requests with new token
    for (final request in _refreshQueue) {
      request.error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      // Retry the request...
    }
  }

  // Retry network errors with exponential backoff
  if (_shouldRetry(err)) {
    await Future.delayed(Duration(milliseconds: 1000 * (1 << retryCount)));
    // Retry...
  }
}
```


## OAuth Implementation

### What is OAuth 2.0?

OAuth 2.0 is an authorization framework that lets users grant limited access to their accounts without sharing passwords.

**Real-world analogy**: Like giving a valet key to your car - it can only drive the car, not open the trunk.

### Why OAuth 2.0?

1. **Security**: User never shares password with your app
2. **Control**: User can revoke access anytime
3. **Standardization**: Industry-wide protocol
4. **Social Login**: Leverage existing accounts

### OAuth 2.0 Roles

```
┌─────────────┐                 ┌─────────────┐
│   User      │                 │ Auth0 Server │
│  (Resource  │                 │              │
│   Owner)    │                 │              │
└──────┬──────┘                 └──────┬──────┘
       │                                │
       │ 1. Tap "Login with Google"     │
       ├───────────────────────────────►│
       │                                │
       │ 2. Show Google login page      │
       │◄───────────────────────────────┤
       │                                │
       │ 3. User authenticates           │
       ├───────────────────────────────►│
       │                                │
       │ 4. Return tokens                │
       │◄───────────────────────────────┤
       │                                │
       │    (Access Token, ID Token,     │
       │     Refresh Token)              │
```

### Our Auth0 Implementation

**Location**: `lib/features/auth/auth_service.dart`

```dart
class AuthService {
  final Auth0 _auth0 = Auth0('YOUR_DOMAIN', 'YOUR_CLIENT_ID');

  Future<Credentials?> loginWithGoogle() async {
    final credentials = await _auth0.webAuthentication(scheme: 'org.pecha.app')
        .login(
          useHTTPS: true,
          parameters: {"connection": "google-oauth2"},
          scopes: {"openid", "profile", "email", "offline_access"},
        );

    // Auth0 SDK handles PKCE automatically
    // Credentials contain: accessToken, idToken, refreshToken, expiresIn

    await _auth0.credentialsManager.storeCredentials(credentials);
    return credentials;
  }
}
```

**What scopes mean**:
- `openid`: Enables OIDC protocol
- `profile`: Access to user profile data
- `email`: Access to user email
- `offline_access`: Enables refresh tokens

### Login Flow: Step by Step

**Step 1: UI - Login Button**
```dart
// lib/features/auth/presentation/widgets/auth_buttons.dart
ElevatedButton(
  onPressed: () {
    ref.read(authProvider.notifier).login(connection: 'google-oauth2');
  },
  child: Text('Login with Google'),
)
```

**Step 2: AuthNotifier - State Management**
```dart
// lib/features/auth/presentation/providers/auth_notifier.dart
Future<void> login({String? connection}) async {
  state = state.copyWith(isLoading: true);

  final result = await _loginUseCase(LoginParams(connection: connection));

  result.fold(
    (failure) => state = state.copyWith(errorMessage: failure.message),
    (credentials) => _handleSuccessfulLogin(credentials),
  );
}
```

**Step 3: UseCase - Orchestration**
```dart
// lib/features/auth/domain/usecases/login_usecase.dart
Future<Either<Failure, AuthCredentials>> call(LoginParams params) async {
  switch (params.connection) {
    case 'google-oauth2':
      return await _repository.loginWithGoogle();
    case 'apple':
      return await _repository.loginWithApple();
  }
}
```

**Step 4: Repository - Data Layer**
```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
Future<Either<Failure, AuthCredentials>> loginWithGoogle() async {
  try {
    final credentials = await _authService.loginWithGoogle();
    return Right(_toAuthCredentials(credentials));
  } catch (e) {
    return Left(AuthenticationFailure('Login failed'));
  }
}
```

**Step 5: AuthService - Auth0 Integration**
```dart
// lib/features/auth/auth_service.dart
Future<Credentials?> loginWithGoogle() async {
  return _loginWithConnection('google-oauth2');
}

Future<Credentials?> _loginWithConnection(String connection) async {
  final credentials = await _auth0.webAuthentication(scheme: 'org.pecha.app')
      .login(
        useHTTPS: true,
        parameters: {"connection": connection},
        scopes: {"openid", "profile", "email", "offline_access"},
      );

  await _auth0.credentialsManager.storeCredentials(credentials);
  return credentials;
}
```


### Auth State & Navigation

**Location**: `lib/core/config/router/go_router.dart`

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) async {
      final authState = ref.watch(authProvider);

      // Unauthenticated trying to access protected route
      if (!authState.isLoggedIn && RouteConfig.isProtectedRoute(currentPath)) {
        return RouteConfig.login;  // Redirect to login
      }

      // Authenticated user on login page
      if (authState.isLoggedIn && currentPath == RouteConfig.login) {
        return RouteConfig.home;  // Redirect to home
      }

      return null;  // No redirect
    },
  );
});
```

**How it works**:
- Router watches `authProvider` for state changes
- When auth state changes, router re-evaluates redirect logic
- Automatically redirects based on auth status

### Logout Flow

```dart
// lib/features/auth/presentation/providers/auth_notifier.dart
Future<void> logout() async {
  // 1. Clear credentials from storage
  await _localLogoutUseCase(const NoParams());

  // 2. Clear user data
  await ref.read(userProvider.notifier).clearUser();

  // 3. Update state
  state = state.copyWith(isLoggedIn: false);

  // 4. Router automatically redirects to login
}
```

### App Launch: Auth State Restoration

```dart
// lib/features/auth/presentation/providers/auth_notifier.dart
AuthNotifier(...) : super(const AuthState(isLoading: true)) {
  _restoreLoginState();  // Runs immediately on creation
}

Future<void> _restoreLoginState() async {
  // 1. Check for valid credentials
  final hasCredentials = await _hasValidCredentialsUseCase();

  if (hasCredentials) {
    // 2. Restore user data
    state = state.copyWith(isLoggedIn: true, isLoading: false);
    ref.read(userProvider.notifier).initializeUser();
  } else {
    // 3. Check for guest mode
    final isGuest = await _isGuestModeUseCase();
    state = state.copyWith(isLoggedIn: isGuest, isGuest: isGuest, isLoading: false);
  }
}
```


### Complete Flow Diagram
#### End-to-End: From Login to API Call

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION & API CALL FLOW                      │
└─────────────────────────────────────────────────────────────────────────┘

                        APP LAUNCH
                            │
                            ▼
              ┌─────────────────────────┐
              │   AuthNotifier created  │
              │   (isLoading: true)     │
              └───────────┬─────────────┘
                          │
                          ▼
              ┌─────────────────────────┐
              │  Check stored creds     │
              │  (CredentialsManager)   │
              └───────────┬─────────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
        Has Creds              No Creds
              │                       │
              ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐
    │ isLoggedIn=true │    │ Check guest mode │
    │ isLoading=false │    └────────┬────────┘
    └────────┬────────┘             │
             │              ┌───────┴───────┐
             │         Was Guest?  Not Guest
             │              │             │
             ▼              ▼             ▼
    ┌─────────────┐  ┌──────────┐  ┌──────────┐
    │ Show Home   │  │Show Home │  │Show Login│
    └──────┬──────┘  └──────┬───┘  └──────────┘
           │                │
           │                │
           ▼                ▼
    ┌──────────────────────────────────┐
    │     USER TAPS LOGIN BUTTON       │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ AuthNotifier.login() called      │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ LoginUseCase called              │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ AuthRepository.loginWithGoogle() │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ AuthService.loginWithGoogle()    │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Auth0 Web Auth opens             │
    │ (PKCE flow handled by SDK)       │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ User authenticates with Google   │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Credentials returned             │
    │ (access, id, refresh tokens)     │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Stored in CredentialsManager     │
    │ (Keychain/Keystore)              │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ AuthNotifier state updated       │
    │ (isLoggedIn: true)               │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ GoRouter redirects to Home       │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ User fetches their plans         │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ UserPlansNotifier.fetchPlans()   │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ GetPlansUseCase called           │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Repository.getUserPlans()        │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ DataSource calls Dio.get()       │
    │ URL: /users/me/plans             │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ REQUEST INTERCEPTOR CHAIN        │
    │                                  │
    │ 1. AuthInterceptor               │
    │    - Path is protected? YES      │
    │    - Get token from Provider     │
    │    - Provider calls AuthService  │
    │    - AuthService checks expiry   │
    │    - If expired, refreshes       │
    │    - Returns valid token         │
    │    - Adds Authorization header   │
    │                                  │
    │ 2. CacheInterceptor              │
    │    - Not in cache, proceed       │
    │                                  │
    │ 3. RetryInterceptor              │
    │    - No error, proceed           │
    │                                  │
    │ 4. Send to server                │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ SERVER RESPONSE: 200 OK          │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ RESPONSE INTERCEPTOR CHAIN       │
    │                                  │
    │ 1. RetryInterceptor              │
    │    - No 401, proceed             │
    │                                  │
    │ 2. CacheInterceptor              │
    │    - Store in cache              │
    │                                  │
    │ 3. ErrorInterceptor              │
    │    - No error, proceed           │
    │                                  │
    │ 4. LoggingInterceptor            │
    │    - Log success                 │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ DataSource parses JSON           │
    │ Returns List<UserPlanModel>      │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Repository maps to entities      │
    │ Returns Either<Failure, Plans>   │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ UseCase returns Either            │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Notifier folds Either            │
    │ Updates state with data          │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ UI rebuilds with plans data      │
    └──────────────────────────────────┘
```

### 401 Error Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      401 TOKEN EXPIRED FLOW                             │
└─────────────────────────────────────────────────────────────────────────┘

    API Request with expired token
                  │
                  ▼
    ┌──────────────────────────────────┐
    │ Server returns 401 Unauthorized  │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ RetryInterceptor.onError()       │
    └──────────────┬───────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ Check: Has valid credentials?    │
    └──────────────┬───────────────────┘
                   │
          ┌────────┴────────┐
          │                 │
         YES               NO
          │                 │
          ▼                 ▼
    ┌──────────────┐  ┌──────────────┐
    │ Check if     │  │ Pass error   │
    │ already     │  │ through      │
    │ refreshing? │  └──────────────┘
    └──────┬───────┘
           │
     ┌─────┴─────┐
     │           │
  Refreshing   Not refreshing
     │           │
     ▼           ▼
┌─────────┐  ┌──────────────────┐
│ Queue   │  │ Set refreshing = │
│ request │  │ true             │
└─────────┘  └────────┬─────────┘
                      │
                      ▼
            ┌──────────────────────┐
            │ Call AuthService     │
            │ .refreshIdToken()    │
            └──────────┬───────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │ Auth0 API renews     │
            │ using refresh token  │
            └──────────┬───────────┘
                       │
              ┌────────┴────────┐
              │                 │
         Success           Failure
              │                 │
              ▼                 ▼
    ┌───────────────┐  ┌────────────────┐
    │ Store new     │  │ onAuthExpired  │
    │ credentials   │  │ callback       │
    └───────┬───────┘  │ → Logout      │
            │          └────────────────┘
            ▼
    ┌───────────────┐
    │ Retry queued  │
    │ requests      │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ Retry original│
    │ request       │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ Set refreshing│
    │ = false       │
    └───────────────┘
```

## 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📄 License
[MIT](LICENSE)





**Table of Contents Screen**
- Browse through organized text content lists with ease
- View all available versions of each text in one convenient location

**Reader Screen**
- Immersive reading experience with optimized formatting

