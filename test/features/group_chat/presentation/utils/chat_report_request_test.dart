import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_analytics.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

/// Answers every report with [result]; nothing else is called.
class _ReportRepository implements GroupChatRepository {
  _ReportRepository(this.result);

  Either<Failure, Unit> result;
  int reportCalls = 0;

  @override
  Future<Either<Failure, Unit>> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  }) async {
    reportCalls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RecordingAnalyticsService service;

  setUp(() => service = RecordingAnalyticsService());

  /// Pumps a scaffold and sends one report through its messenger.
  Future<ChatReportRequest> send(
    WidgetTester tester,
    _ReportRepository repository, {
    bool online = true,
  }) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    final request = ChatReportRequest(
      repository: repository,
      analytics: GroupChatAnalytics(service),
      isOnline: () async => online,
      messenger: ScaffoldMessenger.of(hostContext),
      l10n: AppLocalizations.of(hostContext)!,
      roomId: 'room-1',
      messageId: 'm1',
      reason: 'SPAM',
      description: null,
    );
    await request.send();
    await tester.pump();
    return request;
  }

  testWidgets('an accepted report fires group_message_reported', (
    tester,
  ) async {
    await send(tester, _ReportRepository(const Right(unit)));

    expect(service.eventNames, [AnalyticsEvents.groupMessageReported]);
    expect(service.events.single.properties, {
      'room_id': 'room-1',
      'message_id': 'm1',
      'reason': 'SPAM',
    });
  });

  testWidgets('a refused report fires nothing', (tester) async {
    await send(tester, _ReportRepository(const Left(NotFoundFailure('gone'))));

    expect(service.events, isEmpty);
  });

  testWidgets('a failed report fires nothing, and its retry fires once', (
    tester,
  ) async {
    final repository = _ReportRepository(const Left(NetworkFailure('timeout')));
    final request = await send(tester, repository, online: false);
    expect(service.events, isEmpty);

    repository.result = const Right(unit);
    await request.send();

    expect(repository.reportCalls, 2);
    expect(service.eventNames, [AnalyticsEvents.groupMessageReported]);
  });
}
