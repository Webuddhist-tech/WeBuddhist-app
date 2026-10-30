import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectPostLinkUtils.isYoutubeShort', () {
    test('recognises a shorts URL', () {
      expect(
        ConnectPostLinkUtils.isYoutubeShort(
          'https://www.youtube.com/shorts/k4kzbi48SVc',
        ),
        isTrue,
      );
      expect(
        ConnectPostLinkUtils.isYoutubeShort(
          'https://m.youtube.com/shorts/k4kzbi48SVc?feature=share',
        ),
        isTrue,
      );
    });

    test('treats watch, live, and youtu.be links as normal videos', () {
      const urls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://www.youtube.com/live/dQw4w9WgXcQ',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
      ];
      for (final url in urls) {
        expect(ConnectPostLinkUtils.isYoutubeShort(url), isFalse, reason: url);
      }
    });
  });
}
