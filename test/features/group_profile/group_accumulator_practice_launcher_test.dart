import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_accumulator_practice_launcher.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _detail = GroupAccumulatorDetail(
  id: 'acc-1',
  presetAccumulatorId: 'preset-1',
  textId: 'text-1',
  groupId: 'group-1',
  title: 'Green Tara',
  isJoined: true,
);

/// Opens the practice inside an embedded scope so the navigation context
/// handed to the reader can be read back from the controller.
Future<PlanEmbeddedController> _openPractice(
  WidgetTester tester, {
  String? eventId,
}) async {
  final controller = PlanEmbeddedController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        groupAccumulatorDetailProvider.overrideWith(
          (ref, id) async => const Right(_detail),
        ),
        groupProfileProvider.overrideWith(
          (ref, id) async => const Left(NetworkFailure('test')),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlanEmbeddedScope(
            controller: controller,
            child: Consumer(
              builder:
                  (context, ref, _) => TextButton(
                    onPressed:
                        () => openGroupAccumulatorPractice(
                          context,
                          ref,
                          accumulatorId: _detail.id,
                          eventId: eventId,
                        ),
                    child: const Text('Recite'),
                  ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Recite'));
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('a practice opened from an event follows its live recitation', (
    tester,
  ) async {
    final controller = await _openPractice(tester, eventId: 'event-1');

    expect(controller.isOpen, isTrue);
    expect(controller.item?.textId, 'text-1');
    final context = controller.navigationContext;
    expect(context?.source, NavigationSource.groupAccumulatorChant);
    expect(context?.isGroupAccumulatorChant, isTrue);
    expect(context?.eventId, 'event-1');
    expect(context?.isLiveRecitation, isTrue);

    // Unmount first so the launcher sees a dead context when it resumes.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('a practice opened outside an event does not follow', (
    tester,
  ) async {
    final controller = await _openPractice(tester);

    expect(controller.isOpen, isTrue);
    expect(controller.navigationContext?.isGroupAccumulatorChant, isTrue);
    expect(controller.navigationContext?.isLiveRecitation, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
