# Error Message Mapper Implementation

## Overview

`ErrorMessageMapper` is a static helper that turns a `Failure` / `Exception` /
arbitrary error into a string for the UI, plus a few classification helpers.

> **Status (Oct 2026):** this doc originally described a January 2026 version
> with per-type friendly copy, context-specific prefixes (`context: 'chat'`…)
> and an integration into an "AI feature". That AI feature no longer exists in
> the app and the mapper was simplified. The sections below describe the
> current code. In the app it is currently used only by
> `lib/features/more/presentation/edit_profile_screen.dart`
> (`isNetworkError`). Most user-facing messages come straight from
> `Failure.message`, which `ExceptionMapper` / the repositories build.

---

## Implementation Details

### 1. Core Utility: `ErrorMessageMapper`

**Location**: `lib/core/error/error_message_mapper.dart`

**Key Methods**:

```dart
static String mapFailure(Failure failure)      // returns failure.message
static String mapException(Exception e)        // fixed English string per AppException type
static String map(dynamic error)               // Failure → mapFailure, Exception → mapException
static String getDisplayMessage(dynamic error, {String? context}) // `context` is unused

static bool isNetworkError(dynamic error)
static bool isTimeoutError(dynamic error)
static bool isAuthError(dynamic error)
static bool isRetryable(dynamic error)
```

### 2. Error Types Handled

#### Failure objects (`lib/core/error/failures.dart`)

Every known `Failure` subtype (`NetworkFailure`, `ServerFailure`,
`CacheFailure`, `ValidationFailure`, `AuthenticationFailure`,
`AuthorizationFailure`, `NotFoundFailure`, `PairingFailure`,
`RateLimitFailure`, `UnknownFailure`) is passed through as `failure.message`
— there is no per-type rewording.

#### Exceptions

- `TimeoutException` → "Request timed out. Please try again."
- `SocketException` → "No internet connection. Please check your network settings."
- `FormatException` → "Invalid data format. Please try again."
- `HttpException` → "Service error. Please try again later."
- App exceptions from `lib/core/error/exceptions.dart` (`NetworkException`,
  `ServerException`, `AuthenticationException`, …) → one fixed English
  message each via `mapException` (`ValidationException` keeps its own message).

There is no HTTP-status-code or free-form error-string mapping any more, and
the strings are **not localized**.

### 3. Classification helpers

`isNetworkError`, `isTimeoutError`, `isAuthError` and `isRetryable` check the
type first and then fall back to substring matching on `toString()`
(e.g. `'timeout'`, `'socket'`, `'401'`, `'503'`).

### Where HTTP errors are converted

- `ErrorInterceptor` (`lib/core/network/interceptors/error_interceptor.dart`)
  turns `DioException`s into typed app exceptions (400/409 → `ValidationException`
  with the server `code`, 401 → `AuthenticationException`, 403 →
  `AuthorizationException`, 404 → `NotFoundException` keeping the server reason,
  429 → `RateLimitException`, 5xx → `ServerException`).
- `ExceptionMapper` (`lib/core/error/exception_mapper.dart`) maps those
  exceptions to `Failure`s in repositories.

---

## Testing

**Location**: `test/core/utils/error_message_mapper_test.dart`

> ⚠️ This test file still asserts the old behaviour (friendly per-type copy,
> HTTP-status strings, context prefixes). As of Oct 2026 **34 of 54 tests
> fail** against the current mapper. Either rewrite the tests for the current
> pass-through behaviour or delete the unused API surface together with them.

---

## Usage Examples

```dart
// Show whatever the repository put in the failure.
final message = ErrorMessageMapper.map(failure);

// Branch on connectivity.
if (ErrorMessageMapper.isNetworkError(error)) {
  showOfflineMessage();
}
```

---

## Best Practices

- Prefer surfacing `Failure.message` (already user-oriented where the
  repository wrote it) and localize copy at the widget level via `context.l10n`.
- Don't show raw `error.toString()` or stack traces to users.
- Don't rely on `getDisplayMessage(..., context:)` — the parameter is ignored.
