# Locale Provider Tests

This section covers `locale_provider_test.dart`, the unit tests for UI locale
persistence (`LocaleNotifier` in `lib/core/config/locale/locale_notifier.dart`).
The directory also holds content-language analytics, `Env` library-key, and
protected-route tests.

## Test Coverage

The test suite includes **21 test cases** covering:

### Valid Scenarios (6 tests)

- Loading valid stored locales
- Setting and persisting new locale
- Default locale on first launch
- Locale persistence verification

### Invalid Scenarios (7 tests)

- Unsupported locale codes (fr, de, es, etc.)
- Null/empty stored values
- Invalid characters in stored locale
- Setting null locale

### Edge Cases (5 tests)

- Storage service failures
- Concurrent locale changes
- Storage set failures
- State consistency across multiple changes

### Integration Scenarios (3 tests)

- App restart simulation
- App update with unsupported locale
- Clear data scenario

## When Locally Stored Locale is Invalid

The locally stored locale becomes **invalid** in the following scenarios:

1. **Unsupported language code** - Locale not in `L10n.all` (`en`, `bo`, `zh`, `hi`, `mn`, `ne`)
2. **First app launch** - No stored value exists
3. **Corrupted data** - Wrong type or malformed data
4. **Storage cleared** - User clears app data/cache
5. **App updates** - Supported locales change between versions
6. **Storage service failure** - SharedPreferences unavailable

### Fallback Behavior

- First launch, null/empty stored values and storage read failures fall back
  to the default `en` locale without crashing.
- `setLocale` validates against `L10n.all` and throws for unsupported codes.
- Loading does **not** validate: an unsupported code already in storage (e.g.
  `fr`) is applied as-is, and the tests assert that behaviour.

## Running Tests

```bash
# Run all locale provider tests
flutter test test/core/config/locale_provider_test.dart

# Generate mock files (if needed)
dart run build_runner build --delete-conflicting-outputs
```

## Dependencies

- `mockito`: For mocking the local storage service
- `build_runner`: For generating mock classes
- `flutter_test`: Flutter testing framework

## Implementation Details

The `LocaleNotifier` class:

- Validates stored locale against supported locales
- Handles storage failures gracefully with try-catch
- Maintains UI state even if persistence fails
- Persists through the injected local storage service
