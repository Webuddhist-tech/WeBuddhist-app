import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/utils/poem_share.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// share_plus forwards every share to this channel; capturing its calls lets
/// the test assert the exact payload without a platform share sheet.
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

const _shortUrl = 'https://short.example/poem-1';
const _shareMessage =
    'I liked this poem from WeBuddhist and wanted to share it with you.';

/// Stands in for the URL shortener so the share text is deterministic.
class _FakeShareUrlService implements ShareUrlService {
  @override
  Future<String> shorten(String longUrl) async => _shortUrl;
}

Poem _makePoem(String title) =>
    Poem(id: 'poem-1', title: title, content: 'Content', authorName: 'Author');

/// Pumps a localized app and returns a context that can call [sharePoem].
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shareUrlServiceProvider.overrideWithValue(_FakeShareUrlService()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return hostContext;
}

void main() {
  final shareCalls = <MethodCall>[];

  setUp(() {
    shareCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (call) async {
          shareCalls.add(call);
          return 'dev.fluttercommunity.plus/share/success';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  String sharedText() {
    expect(shareCalls, hasLength(1));
    expect(shareCalls.single.method, 'share');
    final args = shareCalls.single.arguments as Map<Object?, Object?>;
    return args['text'] as String;
  }

  group('sharePoem', () {
    testWidgets('wraps a non-empty title in the localized quotation template', (
      tester,
    ) async {
      final context = await _pumpHost(tester);

      await sharePoem(context, _makePoem('Benefits of Bodhicitta'));

      expect(
        sharedText(),
        '$_shareMessage\n\n“Benefits of Bodhicitta”\n\n$_shortUrl',
      );
    });

    testWidgets('trims surrounding whitespace before quoting the title', (
      tester,
    ) async {
      final context = await _pumpHost(tester);

      await sharePoem(context, _makePoem('  Benefits of Bodhicitta \n'));

      expect(
        sharedText(),
        '$_shareMessage\n\n“Benefits of Bodhicitta”\n\n$_shortUrl',
      );
    });

    testWidgets('omits the title line entirely when the title is blank', (
      tester,
    ) async {
      final context = await _pumpHost(tester);

      await sharePoem(context, _makePoem('   \n\t'));

      expect(sharedText(), '$_shareMessage\n\n$_shortUrl');
    });

    testWidgets('omits the title line when the title is empty', (tester) async {
      final context = await _pumpHost(tester);

      await sharePoem(context, _makePoem(''));

      expect(sharedText(), '$_shareMessage\n\n$_shortUrl');
    });
  });
}
