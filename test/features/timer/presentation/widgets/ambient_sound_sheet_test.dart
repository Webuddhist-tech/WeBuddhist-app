import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/ambient_sound_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Empty urls: the preview player returns before touching the audio plugin.
const _rain = AmbientSound(id: 'rain', name: 'Rain', url: '');
const _wind = AmbientSound(id: 'wind', name: 'Wind', url: '');

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ambientSoundsFutureProvider.overrideWith((ref) async => [_rain, _wind]),
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
  return hostContext;
}

void main() {
  testWidgets('tapping a row applies it at once and a tap outside keeps it', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    final changes = <AmbientSoundSelection>[];
    final result = AmbientSoundSheet.show(
      context,
      selectedId: null,
      onChanged: changes.add,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rain'));
    await tester.pump();

    expect(changes, hasLength(1));
    expect(changes.single.id, 'rain');
    expect(changes.single.name, 'Rain');

    await tester.tapAt(const Offset(10, 10)); // barrier
    await tester.pumpAndSettle();

    expect(await result, isNull);
    expect(changes, hasLength(1));
  });

  testWidgets('the default row applies a cleared selection', (tester) async {
    final context = await _pumpHost(tester);
    final changes = <AmbientSoundSelection>[];
    AmbientSoundSheet.show(
      context,
      selectedId: 'rain',
      selectedName: 'Rain',
      onChanged: changes.add,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Default (no sound)'));
    await tester.pump();

    expect(changes, hasLength(1));
    expect(changes.single.id, isNull);
    expect(changes.single.name, isNull);
  });

  testWidgets('the X returns the current selection', (tester) async {
    final context = await _pumpHost(tester);
    final result = AmbientSoundSheet.show(context, selectedId: null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wind'));
    await tester.pump();
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    final selection = await result;
    expect(selection?.id, 'wind');
    expect(selection?.name, 'Wind');
  });
}
