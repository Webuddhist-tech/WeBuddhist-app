import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/upgrade/force_update_dialog.dart';
import 'package:flutter_pecha/core/services/upgrade/upgrade_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the app's root child and blocks it with a non-dismissible
/// forced-update modal on Android/iOS whenever the store has a newer version.
///
/// Mount this via [MaterialApp.router]'s `builder` parameter so the modal
/// sits above the GoRouter navigator and blocks every route.
///
/// The modal is layered in this widget's own [Stack] rather than pushed with
/// `showDialog`: a pageless dialog route on the GoRouter navigator is removed
/// as soon as GoRouter rebuilds its page stack (e.g. an auth redirect right
/// after launch), which let users dismiss the update by simply waiting.
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only enforce on Android/iOS; skip macOS and other platforms.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return child;
    }

    final updateRequired =
        ref.watch(updateAvailableProvider).valueOrNull ?? false;

    // Keep the tree shape stable across both states so toggling the gate
    // never remounts the navigator underneath.
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: updateRequired,
          child: ExcludeSemantics(excluding: updateRequired, child: child),
        ),
        if (updateRequired) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          const ForceUpdateDialog(),
        ],
      ],
    );
  }
}
