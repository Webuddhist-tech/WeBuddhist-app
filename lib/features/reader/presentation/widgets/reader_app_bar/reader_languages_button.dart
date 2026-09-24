import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Globe button that opens the Languages drawer.
///
/// The first-visit layout, translation auto-fill included, is applied by the
/// screen through `ReaderInitialLayoutApplier`; this is only the button.
class ReaderLanguagesButton extends StatelessWidget {
  const ReaderLanguagesButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(AppAssets.readerVersionSettings),
      tooltip: context.l10n.reader_languages_title,
      onPressed: onPressed,
    );
  }
}
