import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_composer_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _languages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'bo', name: 'Tibetan', nativeName: 'བོད་ཡིག'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
];

const _practices = [
  GroupEventPracticePick(
    id: 'p1',
    kind: GroupEventPracticeKind.plan,
    title: '21 Days of the 21 Taras',
  ),
  GroupEventPracticePick(
    id: 's1',
    kind: GroupEventPracticeKind.series,
    title: 'Lamrim teachings',
  ),
  GroupEventPracticePick(
    id: 'c1',
    kind: GroupEventPracticeKind.collection,
    title: 'Praises to Tara',
  ),
  GroupEventPracticePick(
    id: 'a1',
    kind: GroupEventPracticeKind.accumulator,
    title: 'Green Tara mantra',
  ),
];

class _FakeComposerRepository extends Fake
    implements GroupEventComposerRepositoryInterface {
  CreateGroupEventRequest? created;
  CreateGroupEventRequest? updated;
  CreateGroupEventRequest? updatedOriginal;
  String? updatedId;
  CreateGroupLocationRequest? location;
  bool failCreate = false;

  @override
  Future<Either<Failure, GroupEvent>> updateEvent(
    String eventId,
    CreateGroupEventRequest request, {
    CreateGroupEventRequest? original,
  }) async {
    updatedId = eventId;
    updated = request;
    updatedOriginal = original;
    return Right(
      GroupEvent(
        id: eventId,
        groupId: 'g1',
        title: request.metadata.first.name,
      ),
    );
  }

  @override
  Future<Either<Failure, List<GroupEventIntention>>> getIntentions() async =>
      const Right([
        GroupEventIntention(id: 'i1', slug: 'peace', label: 'Peace'),
        GroupEventIntention(id: 'i2', slug: 'healing', label: 'Healing'),
      ]);

  @override
  Future<Either<Failure, String>> createLocation(
    String groupId,
    CreateGroupLocationRequest request,
  ) async {
    location = request;
    return const Right('loc-1');
  }

  @override
  Future<Either<Failure, GroupEvent>> createEvent(
    CreateGroupEventRequest request,
  ) async {
    if (failCreate) return const Left(ServerFailure('Validation failed'));
    created = request;
    return Right(
      GroupEvent(id: 'ev-1', groupId: 'g1', title: request.metadata.first.name),
    );
  }
}

final _composerRepository = _FakeComposerRepository();

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage(super.code);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  String contentLanguage = 'bo',
  GroupEventEditSource? existing,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        availableContentLanguagesProvider.overrideWith(
          (ref) async => _languages,
        ),
        contentLanguageProvider.overrideWith(
          (ref) => _FixedContentLanguage(contentLanguage),
        ),
        groupEventPracticeOptionsProvider.overrideWith(
          (ref, groupId) async => _practices,
        ),
        groupEventComposerRepositoryProvider.overrideWithValue(
          _composerRepository,
        ),
        chatLinkPreviewProvider.overrideWith(
          // No thumbnail: a network image would keep pumpAndSettle waiting.
          (ref, url) async =>
              ChatLinkPreview(url: url, title: 'Guided sitting — introduction'),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Launcher(
          existing: existing,
          profile: const GroupProfile(
            id: 'g1',
            title: 'Lodhen Warlord',
            socialLinks: [
              GroupProfileSocialLink(
                id: 's1',
                platform: 'youtube',
                url: 'https://youtube.com/@lodhenwarlord',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

GroupEventComposerResult? _lastResult;

/// Opens the composer through its `show` so the pop result can be read.
class _Launcher extends StatelessWidget {
  const _Launcher({required this.profile, this.existing});

  final GroupProfile profile;
  final GroupEventEditSource? existing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            _lastResult = await GroupEventComposerScreen.show(
              context,
              profile,
              existing: existing,
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

ElevatedButton _continueButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Continue'),
      matching: find.byType(ElevatedButton),
    ),
  );
}

void main() {
  testWidgets('step one preselects English and the content language', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('New event'), findsOneWidget);
    expect(find.text('Step 1 of 4 · About'), findsOneWidget);
    expect(find.text('Lodhen Warlord'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('བོད་ཡིག'), findsOneWidget);
    expect(find.text('中文'), findsNothing);
  });

  testWidgets('continue waits for an event name in some language', (
    tester,
  ) async {
    await _pump(tester);

    expect(_continueButton(tester).onPressed, isNull);
    expect(find.text('Add an event name to continue'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
      'Wednesday group practice',
    );
    await tester.pump();

    expect(_continueButton(tester).onPressed, isNotNull);
    expect(find.text('Add an event name to continue'), findsNothing);

    // The name belongs to the active language only.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday group practice'), findsNothing);
    expect(_continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('བོད་ཡིག'));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday group practice'), findsOneWidget);
  });

  testWidgets('the plus chip adds languages from the sheet', (tester) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('Add language'));
    await tester.pumpAndSettle();

    expect(find.text('Event languages'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(4));

    await tester.tap(find.widgetWithText(InkWell, '中文').last);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Event languages'), findsNothing);
    expect(find.text('中文'), findsOneWidget);
    expect(find.text('हिन्दी'), findsNothing);
  });

  testWidgets('continue moves to step two and back returns', (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
      'Wednesday',
    );
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 4 · About'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
  });

  whenWhereTests();
  practicesTests();
  reviewTests();
  draftTests();
}

Future<void> _goToStepTwo(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
    'Wednesday',
  );
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void whenWhereTests() {
  testWidgets('step two asks for a date, then a venue', (tester) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);
    expect(find.text('Pick a date to continue'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
    expect(find.text('Asia/Kolkata (IST)'), findsOneWidget);
    expect(find.text('Add venue location'), findsOneWidget);

    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    expect(find.text('Date'), findsWidgets);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.pumpAndSettle();

    expect(find.text('Pick a date to continue'), findsNothing);
    expect(find.text('Choose a venue to continue'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
  });

  testWidgets('live format needs a valid link and offers the channel', (
    tester,
  ) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    await tester.tap(find.text('Live'));
    await tester.pumpAndSettle();
    expect(find.text('Add venue location'), findsNothing);
    expect(find.text('Use channel link'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'youtube.com/… or a meeting link'),
      'meet google abc',
    );
    await tester.pump();
    expect(find.text("That doesn't look like a link yet"), findsOneWidget);

    await tester.ensureVisible(find.text('Use channel link'));
    await tester.tap(find.text('Use channel link'));
    await tester.pump();
    expect(
      find.text('https://www.youtube.com/@lodhenwarlord/live'),
      findsOneWidget,
    );
    expect(find.text('Use channel link'), findsNothing);
    expect(find.textContaining('plays inside WeBuddhist'), findsOneWidget);
  });

  testWidgets('recurring shows repeats and duration instead of multi-day', (
    tester,
  ) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    await tester.tap(find.text('Recurring'));
    await tester.pumpAndSettle();

    expect(find.text('First date'), findsOneWidget);
    expect(find.text('Repeats'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('Multi-day event'), findsNothing);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Start time'), findsNothing);
    expect(find.text('Shown as all day on the event page.'), findsOneWidget);
  });
}

Future<void> _goToStepThree(WidgetTester tester) async {
  await _goToStepTwo(tester);
  await tester.tap(find.text('Live'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'youtube.com/… or a meeting link'),
    'https://youtube.com/@lodhenwarlord/live',
  );
  await tester.pump();
  await tester.ensureVisible(find.text('Choose a date'));
  await tester.tap(find.text('Choose a date'));
  await tester.pumpAndSettle();
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  await tester.tap(find.text('${tomorrow.day}').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void practicesTests() {
  testWidgets('step three can be skipped until something is added', (
    tester,
  ) async {
    await _pump(tester);
    await _goToStepThree(tester);

    expect(find.text('Step 3 of 4 · Practices & videos'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.text('Add practice'));
    await tester.pumpAndSettle();
    expect(find.text('Add practices'), findsOneWidget);

    await tester.tap(find.text('21 Days of the 21 Taras'));
    await tester.tap(find.text('Green Tara mantra'));
    await tester.pump();
    expect(find.text('Add 2 practices'), findsOneWidget);

    // A series takes the plan's single slot.
    await tester.tap(find.text('Lamrim teachings'));
    await tester.pump();
    expect(find.text('Add 2 practices'), findsOneWidget);
    expect(
      find.text('Choosing Lamrim teachings replaced 21 Days of the 21 Taras.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Add 2 practices'));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Lamrim teachings'), findsOneWidget);
    expect(find.text('21 Days of the 21 Taras'), findsNothing);
    expect(find.text('Admin adds'), findsOneWidget);

    await tester.tap(find.text('Admin adds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendees add in app'));
    await tester.pumpAndSettle();
    expect(find.text('Attendees add in app'), findsOneWidget);
    expect(find.text('Admin adds'), findsNothing);
  });

  testWidgets('a youtube link becomes an About video', (tester) async {
    await _pump(tester);
    await _goToStepThree(tester);

    await tester.tap(find.text('Add video'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'https://youtu.be/…'),
      'https://example.org/talk',
    );
    await tester.pump();
    expect(
      find.textContaining("doesn't look like a YouTube link"),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'https://youtu.be/…'),
      'https://youtu.be/8sN0mLpQdT4',
    );
    await tester.pumpAndSettle();
    expect(find.text('Guided sitting — introduction'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add video'));
    await tester.pumpAndSettle();

    expect(find.text('Guided sitting — introduction'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}

void reviewTests() {
  testWidgets('review reads the draft back and publishes it', (tester) async {
    _lastResult = null;
    _composerRepository.created = null;
    await _pump(tester);
    await _goToStepThree(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 4 · Review & publish'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('བོད་ཡིག'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('YouTube live · @lodhenwarlord'), findsOneWidget);
    expect(
      find.text('Chat on · Notifications on · All intentions'),
      findsOneWidget,
    );
    expect(find.text('Members are notified when you publish.'), findsOneWidget);

    await tester.ensureVisible(find.text('Event settings'));
    await tester.tap(find.text('Event settings'));
    await tester.pumpAndSettle();
    expect(find.text('Peace'), findsOneWidget);
    await tester.tap(find.text('Peace'));
    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chat on · Notifications off · 1 intention'),
      findsOneWidget,
    );
    expect(find.text('Members are notified when you publish.'), findsNothing);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    final created = _composerRepository.created!;
    expect(created.status, 'published');
    expect(created.metadata.map((m) => m.language), ['BO']);
    expect(
      created.youtube.single.url,
      'https://youtube.com/@lodhenwarlord/live',
    );
    expect(created.eventFormat, 'online');
    expect(created.notificationsEnabled, isFalse);
    expect(created.intentionIds, ['i1']);
    expect(_composerRepository.location, isNull);

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Wednesday is live'), findsOneWidget);
    expect(
      find.text('You can edit it any time from the event page.'),
      findsOneWidget,
    );

    await tester.tap(find.text('View event'));
    await tester.pumpAndSettle();
    expect(_lastResult?.event.id, 'ev-1');
    expect(_lastResult?.openEvent, isTrue);
  });

  testWidgets('a review row jumps back to its step', (tester) async {
    await _pump(tester);
    await _goToStepThree(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 4 · About'), findsOneWidget);
  });
}

void draftTests() {
  testWidgets('closing with a name and date saves a draft', (tester) async {
    _lastResult = null;
    _composerRepository.created = null;
    await _pump(tester);
    await _goToStepThree(tester);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(_composerRepository.created?.status, 'draft');
    expect(_lastResult?.isDraft, isTrue);
    expect(_lastResult?.event.id, 'ev-1');
  });

  testWidgets('step one only asks to discard; step two insists on a date', (
    tester,
  ) async {
    _lastResult = null;
    _composerRepository.created = null;
    await _pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
      'Wednesday',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard event?'), findsOneWidget);
    expect(_composerRepository.created, isNull);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    await _goToStepTwo(tester);
    expect(find.byTooltip('Cancel'), findsOneWidget);
    expect(find.text('Pick a date to continue'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);
    expect(find.text('Discard event?'), findsNothing);
    expect(find.text('Pick a date to continue'), findsNWidgets(2));
    expect(_composerRepository.created, isNull);
    expect(_lastResult, isNull);

    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.pumpAndSettle();
    expect(find.text('Pick a date to continue'), findsNothing);
  });

  testWidgets('closing a later step without a date returns to step two', (
    tester,
  ) async {
    _lastResult = null;
    _composerRepository.created = null;
    await _pump(tester);
    await _goToStepThree(tester);
    // Go back and clear the schedule by switching to recurring with no rule.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recurring'));
    await tester.pumpAndSettle();
    expect(find.text('Choose how it repeats to continue'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard event?'), findsNothing);
    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);
    expect(_composerRepository.created, isNull);
  });

  testWidgets('a refused draft falls back to the discard dialog', (
    tester,
  ) async {
    _lastResult = null;
    _composerRepository.created = null;
    _composerRepository.failCreate = true;
    addTearDown(() => _composerRepository.failCreate = false);
    await _pump(tester);
    await _goToStepThree(tester);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Validation failed'), findsOneWidget);
    expect(find.text('Discard event?'), findsOneWidget);
    expect(_lastResult, isNull);
  });

  testWidgets('a draft opens prefilled and publishes through update', (
    tester,
  ) async {
    _lastResult = null;
    _composerRepository.updated = null;
    await _pump(
      tester,
      existing: GroupEventDraftMapper.fromJson({
        'id': 'ev-9',
        'status': 'draft',
        'timezone': 'Asia/Kolkata',
        'start_date': '2099-10-07T12:30:00Z',
        'end_date': '2099-10-07T13:30:00Z',
        'event_format': 'online',
        'metadata': [
          {'language': 'EN', 'name': 'Saved draft'},
        ],
        'youtube': [
          {'url': 'https://www.youtube.com/@x/live', 'display_order': 1},
        ],
      }),
    );

    expect(find.text('Edit draft'), findsOneWidget);
    expect(find.text('Saved draft'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('བོད་ཡིག'), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(i == 2 ? 'Skip' : 'Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Step 4 of 4 · Review & publish'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(_composerRepository.updatedId, 'ev-9');
    expect(_composerRepository.updated?.status, 'published');
    // Nothing else was touched, so only the status goes out.
    expect(
      _composerRepository.updated!.toUpdateJson(
        _composerRepository.updatedOriginal!,
      ),
      {'status': 'published'},
    );
    expect(_composerRepository.created, isNull);
    expect(find.text('Saved draft is live'), findsOneWidget);
  });
}
