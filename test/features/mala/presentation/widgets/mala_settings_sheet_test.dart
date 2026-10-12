import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_settings_sheet.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/recording_analytics_service.dart';
import '../../mala_fakes.dart';

/// share_plus forwards every share to this channel; holding its reply lets
/// the test close the sheet before the share result comes back.
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

const _shortUrl = 'https://short.example/mala-1';
const _shareMessage =
    "I've been using this digital mala on WeBuddhist and wanted to share it "
    "with you. It's an easy way to practice wherever you go.";

const _mantra = Mantra(presetId: 'tara-praises');

class _FakeShareUrlService implements ShareUrlService {
  @override
  Future<String> shorten(String longUrl) async => _shortUrl;
}

class _FakeLocal extends Fake implements MalaLocalDataSource {
  @override
  LocalMalaState read(String userId, String presetId) => const LocalMalaState();

  @override
  LocalGroupMalaState readGroup(String userId, String groupAccumulatorId) =>
      const LocalGroupMalaState();

  @override
  List<String> groupAccumulatorIdsForUser(String userId) => const [];
}

/// Offline: the counter seeds from its local total without the network.
class _OfflineRepository extends Fake implements MalaRepository {
  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(
    String parentId,
  ) async => const Left(NetworkFailure('offline'));
}

class _OnlineNotifier extends ConnectivityNotifier {
  @override
  bool build() => true;
}

/// Opens the sheet and taps Share. The share reply is held in [shareResult],
/// so the sheet pops and is disposed while the share is still in flight.
Future<RecordingAnalyticsService> _tapShare(
  WidgetTester tester, {
  required Completer<String> shareResult,
  required List<MethodCall> shareCalls,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shareChannel, (call) {
        shareCalls.add(call);
        return shareResult.future;
      });
  final service = RecordingAnalyticsService();
  late BuildContext hostContext;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shareUrlServiceProvider.overrideWithValue(_FakeShareUrlService()),
        analyticsServiceProvider.overrideWithValue(service),
        isBookmarkedProvider.overrideWith((ref, target) => false),
        connectivityNotifierProvider.overrideWith(_OnlineNotifier.new),
        localStorageServiceProvider.overrideWithValue(FakeUserStorage('user-1')),
        malaLocalDataSourceProvider.overrideWithValue(_FakeLocal()),
        malaRepositoryProvider.overrideWithValue(_OfflineRepository()),
        malaRemoteDataSourceProvider.overrideWithValue(FakeMalaRemote()),
        malaSyncManagerProvider.overrideWithValue(FakeMalaSync()),
        malaSoundPlayerProvider.overrideWithValue(SilentMalaSoundPlayer()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );

  // Not awaited: the sheet has to stay open so the test can drive it.
  unawaited(MalaSettingsSheet.show(hostContext, mantra: _mantra));
  await tester.pumpAndSettle();
  // Lets the counter's seed timeout run out so no timer is left pending.
  await tester.pump(const Duration(seconds: 4));
  expect(find.byType(MalaSettingsSheet), findsOneWidget);

  await tester.tap(find.text('Share'));
  await tester.pumpAndSettle();

  // The sheet is gone before the share sheet reports anything back.
  expect(find.byType(MalaSettingsSheet), findsNothing);
  expect(shareCalls, hasLength(1));
  expect(service.events, isEmpty);
  return service;
}

void main() {
  final shareCalls = <MethodCall>[];

  setUp(() {
    shareCalls.clear();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  testWidgets('shares the mala message with its short link', (tester) async {
    final shareResult = Completer<String>();
    await _tapShare(tester, shareResult: shareResult, shareCalls: shareCalls);
    shareResult.complete('dev.fluttercommunity.plus/share/success');
    await tester.pump();

    final args = shareCalls.single.arguments as Map<Object?, Object?>;
    expect(args['text'], '$_shareMessage\n\n$_shortUrl');
  });

  testWidgets('records one content_shared after the sheet is disposed', (
    tester,
  ) async {
    final shareResult = Completer<String>();
    final service = await _tapShare(
      tester,
      shareResult: shareResult,
      shareCalls: shareCalls,
    );

    shareResult.complete('dev.fluttercommunity.plus/share/success');
    await tester.pump();

    expect(service.eventNames, [AnalyticsEvents.contentShared]);
    expect(service.events.single.properties, {
      'surface': 'mala',
      'target_id': 'tara-praises',
      'language': 'en',
      'format': 'text',
      'method': null,
      'group_id': null,
    });
  });

  testWidgets('records nothing when the share sheet is dismissed', (
    tester,
  ) async {
    final shareResult = Completer<String>();
    final service = await _tapShare(
      tester,
      shareResult: shareResult,
      shareCalls: shareCalls,
    );

    // share_plus reports a dismissed sheet as an empty result.
    shareResult.complete('');
    await tester.pump();

    expect(service.events, isEmpty);
  });
}
