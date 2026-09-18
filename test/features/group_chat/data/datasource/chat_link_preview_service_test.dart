import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePreview', () {
    test('reads og: tags', () {
      const html = '''
<html><head>
<meta property="og:title" content="Satipatthana Sutta">
<meta property="og:description" content="The discourse on mindfulness">
<meta property="og:image" content="https://pecha.org/cover.png">
</head><body></body></html>
''';

      final preview = ChatLinkPreviewService.parsePreview(
        html,
        url: 'https://pecha.org/sutta',
      );

      expect(preview, isNotNull);
      expect(preview!.title, 'Satipatthana Sutta');
      expect(preview.description, 'The discourse on mindfulness');
      expect(preview.imageUrl, 'https://pecha.org/cover.png');
      expect(preview.host, 'pecha.org');
    });

    test('falls back to the document title', () {
      const html = '<html><head><title>Pecha</title></head></html>';

      final preview = ChatLinkPreviewService.parsePreview(
        html,
        url: 'https://pecha.org/',
      );

      expect(preview?.title, 'Pecha');
      expect(preview?.imageUrl, isNull);
    });

    test('resolves a relative og:image against the page URL', () {
      const html = '''
<html><head>
<meta property="og:title" content="Texts">
<meta property="og:image" content="/static/cover.png">
</head></html>
''';

      final preview = ChatLinkPreviewService.parsePreview(
        html,
        url: 'https://pecha.org/texts/reading',
      );

      expect(preview?.imageUrl, 'https://pecha.org/static/cover.png');
    });

    test('drops an og:image with a non-web scheme', () {
      const html = '''
<html><head>
<meta property="og:title" content="Texts">
<meta property="og:image" content="data:image/png;base64,AAA">
</head></html>
''';

      final preview = ChatLinkPreviewService.parsePreview(
        html,
        url: 'https://pecha.org/texts',
      );

      expect(preview?.title, 'Texts');
      expect(preview?.imageUrl, isNull);
    });

    test('returns null when there is no title and no image', () {
      expect(
        ChatLinkPreviewService.parsePreview(
          '<html><body>just text</body></html>',
          url: 'https://pecha.org/',
        ),
        isNull,
      );
    });

    test('returns null for malformed markup with nothing usable', () {
      expect(
        ChatLinkPreviewService.parsePreview(
          '<<<not really html',
          url: 'https://pecha.org/',
        ),
        isNull,
      );
    });
  });

  group('parseYoutubeOembed', () {
    test('reads the video title, channel and thumbnail', () {
      const body =
          '{"title":"Heart Sutra Chanting","author_name":"WeBuddhist",'
          '"thumbnail_url":"https://i.ytimg.com/vi/abc/hqdefault.jpg"}';

      final preview = ChatLinkPreviewService.parseYoutubeOembed(
        body,
        url: 'https://youtu.be/abc',
      );

      expect(preview?.title, 'Heart Sutra Chanting');
      expect(preview?.description, 'WeBuddhist');
      expect(preview?.imageUrl, 'https://i.ytimg.com/vi/abc/hqdefault.jpg');
    });

    test('returns null for a non-JSON or empty response', () {
      expect(
        ChatLinkPreviewService.parseYoutubeOembed(
          'Not Found',
          url: 'https://youtu.be/abc',
        ),
        isNull,
      );
      expect(
        ChatLinkPreviewService.parseYoutubeOembed(
          '{}',
          url: 'https://youtu.be/abc',
        ),
        isNull,
      );
    });
  });

  group('isYoutubeUrl', () {
    test('matches YouTube hosts only', () {
      for (final url in [
        'https://youtu.be/abc',
        'https://www.youtube.com/watch?v=abc',
        'https://m.youtube.com/shorts/abc',
      ]) {
        expect(ChatLinkPreviewService.isYoutubeUrl(url), isTrue, reason: url);
      }
      expect(
        ChatLinkPreviewService.isYoutubeUrl('https://pecha.org/youtube'),
        isFalse,
      );
    });
  });

  group('isPreviewableUrl', () {
    test('accepts public http and https hosts', () {
      expect(
        ChatLinkPreviewService.isPreviewableUrl('https://pecha.org/a'),
        isTrue,
      );
      expect(
        ChatLinkPreviewService.isPreviewableUrl('http://pecha.org'),
        isTrue,
      );
    });

    test('rejects non-web schemes', () {
      expect(
        ChatLinkPreviewService.isPreviewableUrl('ftp://pecha.org'),
        isFalse,
      );
      expect(
        ChatLinkPreviewService.isPreviewableUrl('file:///etc/passwd'),
        isFalse,
      );
    });

    test('rejects loopback and bare IP hosts', () {
      for (final url in [
        'http://localhost:8080/x',
        'http://127.0.0.1/x',
        'http://192.168.1.4/x',
        'http://[::1]/x',
      ]) {
        expect(
          ChatLinkPreviewService.isPreviewableUrl(url),
          isFalse,
          reason: url,
        );
      }
    });
  });
}
