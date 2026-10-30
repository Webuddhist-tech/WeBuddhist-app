import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/screen_cache_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  Future<int> pump(
    WidgetTester tester,
    AsyncValue<Either<Failure, String>> value,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScreenCacheBuilder<String>(
            value: value,
            skeleton: const Text('skeleton'),
            onRetry: () => retries++,
            data: (data) => Text('data:$data'),
          ),
        ),
      ),
    );
    await tester.pump();
    return retries;
  }

  testWidgets('shows the skeleton while nothing is loaded', (tester) async {
    await pump(tester, const AsyncLoading());
    expect(find.text('skeleton'), findsOneWidget);
  });

  testWidgets('renders data', (tester) async {
    await pump(tester, const AsyncData(Right('x')));
    expect(find.text('data:x'), findsOneWidget);
  });

  testWidgets('keeps data while reloading', (tester) async {
    await pump(
      tester,
      const AsyncLoading<Either<Failure, String>>().copyWithPrevious(
        const AsyncData(Right('x')),
      ),
    );
    expect(find.text('data:x'), findsOneWidget);
    expect(find.text('skeleton'), findsNothing);
  });

  testWidgets('shows the skeleton when retrying after a failure',
      (tester) async {
    await pump(
      tester,
      const AsyncLoading<Either<Failure, String>>().copyWithPrevious(
        const AsyncData(Left(NetworkFailure('offline'))),
      ),
    );
    expect(find.text('skeleton'), findsOneWidget);
    expect(find.byType(ErrorStateWidget), findsNothing);
  });

  testWidgets('a Left shows the error widget and retry calls back',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScreenCacheBuilder<String>(
            value: const AsyncData(Left(NetworkFailure('offline'))),
            skeleton: const Text('skeleton'),
            onRetry: () => retries++,
            data: (data) => Text('data:$data'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(retries, 1);
  });

  testWidgets('a stream error shows the error widget', (tester) async {
    await pump(tester, AsyncError(Exception('boom'), StackTrace.empty));
    expect(find.byType(ErrorStateWidget), findsOneWidget);
  });
}
