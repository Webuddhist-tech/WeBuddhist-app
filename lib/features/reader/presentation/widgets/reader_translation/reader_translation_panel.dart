import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_bottom_panel_shell.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_content_block.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_metadata_tile.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_section_header.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _expandedContentIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

final _expandedMetadataIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

class ReaderTranslationPanel extends ConsumerWidget {
  final String segmentId;
  final String textLanguage;
  final ReaderParams params;
  final double availableHeight;

  const ReaderTranslationPanel({
    super.key,
    required this.segmentId,
    required this.textLanguage,
    required this.params,
    required this.availableHeight,
  });

  void _resetExpansion(WidgetRef ref) {
    ref.read(_expandedContentIndexProvider(segmentId).notifier).state = null;
    ref.read(_expandedMetadataIndexProvider(segmentId).notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = context.l10n;
    final notifier = ref.read(readerNotifierProvider(params).notifier);
    final segmentTranslations = ref.watch(
      segmentTranslationsFutureProvider(segmentId),
    );

    return ReaderBottomPanelShell(
      title: localizations.version,
      params: params,
      availableHeight: availableHeight,
      onDismiss: () {
        notifier.closeTranslation();
        _resetExpansion(ref);
      },
      child: segmentTranslations.when(
        data: (data) => _TranslationList(
          translations: data.translations,
          segmentId: segmentId,
          textLanguage: textLanguage,
        ),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () =>
              ref.invalidate(segmentTranslationsFutureProvider(segmentId)),
        ),
        loading: () => const CommentarySkeleton(),
      ),
    );
  }
}

class _TranslationList extends ConsumerWidget {
  const _TranslationList({
    required this.translations,
    required this.segmentId,
    required this.textLanguage,
  });

  final List<SegmentTranslation> translations;
  final String segmentId;
  final String textLanguage;

  /// Groups translations by language code, preserving original order within
  /// each group, and emits the current text language first.
  List<MapEntry<String, List<SegmentTranslation>>> _grouped() {
    final grouped = <String, List<SegmentTranslation>>{};
    for (final t in translations) {
      grouped.putIfAbsent(t.language, () => []).add(t);
    }
    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aFirst = a.key == textLanguage ? 0 : 1;
      final bFirst = b.key == textLanguage ? 0 : 1;
      if (aFirst != bFirst) return aFirst.compareTo(bFirst);
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (translations.isEmpty) {
      return const _EmptyState();
    }

    final groups = _grouped();
    final expandedContent = ref.watch(_expandedContentIndexProvider(segmentId));
    final expandedMetadata = ref.watch(
      _expandedMetadataIndexProvider(segmentId),
    );

    final children = <Widget>[];
    var globalIndex = 0;
    for (final entry in groups) {
      children.add(
        ReaderPanelSectionHeader(
          languageCode: entry.key,
          count: entry.value.length,
        ),
      );
      for (final translation in entry.value) {
        final index = globalIndex++;
        children.add(
          _TranslationItem(
            translation: translation,
            index: index,
            segmentId: segmentId,
            isContentExpanded: expandedContent == index,
            isMetadataExpanded: expandedMetadata == index,
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}

class _TranslationItem extends ConsumerWidget {
  const _TranslationItem({
    required this.translation,
    required this.index,
    required this.segmentId,
    required this.isContentExpanded,
    required this.isMetadataExpanded,
  });

  final SegmentTranslation translation;
  final int index;
  final String segmentId;
  final bool isContentExpanded;
  final bool isMetadataExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = translation.segments
        .map((s) => normalizeSegmentHtml(s.content))
        .where((s) => s.isNotEmpty)
        .join('<br><br>');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.contentSpacing,
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.itemSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReaderPanelContentBlock(
            content: content,
            language: translation.language,
            segmentIndex: index,
            isExpanded: isContentExpanded,
            onToggle: () {
              ref
                  .read(_expandedContentIndexProvider(segmentId).notifier)
                  .state = isContentExpanded ? null : index;
            },
          ),
          const SizedBox(height: ReaderPanelConstants.contentSpacing),
          ReaderPanelMetadataTile(
            title: translation.title,
            language: translation.language,
            source: translation.source,
            license: translation.license,
            isExpanded: isMetadataExpanded,
            onToggle: () {
              ref
                  .read(_expandedMetadataIndexProvider(segmentId).notifier)
                  .state = isMetadataExpanded ? null : index;
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(
          ReaderPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.no_translation,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(
          ReaderPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              localizations.something_went_wrong,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}
