import 'package:flutter/widgets.dart';
// Transitive through the vendored youtube_player_flutter; the player's
// WebView has no platform implementation under `flutter test` without it.
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Stands in for the WebView plugin in widget tests so [YoutubePlayer] can
/// mount: the WebView is an empty box that never reports ready, which keeps
/// the live player on its loader. Idempotent; call before pumping.
class FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  static void install() {
    if (InAppWebViewPlatform.instance is FakeInAppWebViewPlatform) return;
    InAppWebViewPlatform.instance = FakeInAppWebViewPlatform();
  }

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _FakeInAppWebViewWidget(params);
}

class _FakeInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _FakeInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      controller as T;

  @override
  void dispose() {}
}
