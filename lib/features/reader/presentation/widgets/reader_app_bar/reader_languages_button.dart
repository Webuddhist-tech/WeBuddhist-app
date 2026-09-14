import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Globe button that opens the Languages drawer. Also pre-fills the
/// translation slot from the Settings language when the toggle is already on.
class ReaderLanguagesButton extends ConsumerStatefulWidget {
  const ReaderLanguagesButton({
    super.key,
    required this.params,
    required this.onPressed,
  });

  final ReaderParams params;
  final VoidCallback onPressed;

  @override
  ConsumerState<ReaderLanguagesButton> createState() =>
      _ReaderLanguagesButtonState();
}

class _ReaderLanguagesButtonState extends ConsumerState<ReaderLanguagesButton> {
  bool _didAutoFill = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoFill());
  }

  String? _sourceLanguage() {
    final fromNav = widget.params.navigationContext?.language?.trim();
    if (fromNav != null && fromNav.isNotEmpty) return fromNav;
    return ref.read(readerNotifierProvider(widget.params)).textDetail?.language;
  }

  Future<void> _maybeAutoFill() async {
    if (_didAutoFill || !mounted) return;
    final textId = widget.params.textId;
    final dual = ref.read(readerDualSettingsProvider(textId));
    if (!dual.secondaryEnabled || dual.secondary.versionId != null) return;
    final source = _sourceLanguage();
    if (source == null || source.isEmpty) return;
    _didAutoFill = true;
    final textDetail = ref.read(readerNotifierProvider(widget.params)).textDetail;
    await fillSettingsLanguageSecondary(
      ref: ref,
      context: context,
      textId: textId,
      sourceLanguage: source,
      sourceVersionId: textDetail?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textId = widget.params.textId;
    ref.listen(readerLanguagesProvider(textId), (_, next) {
      if (next.hasValue) Future.microtask(_maybeAutoFill);
    });
    ref.listen(readerNotifierProvider(widget.params), (_, next) {
      if (next.textDetail != null) Future.microtask(_maybeAutoFill);
    });

    return IconButton(
      icon: const Icon(AppAssets.readerVersionSettings),
      tooltip: context.l10n.reader_languages_title,
      onPressed: widget.onPressed,
    );
  }
}
