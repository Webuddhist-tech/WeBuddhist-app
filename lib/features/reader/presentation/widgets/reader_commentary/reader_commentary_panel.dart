import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_bottom_panel_shell.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_content_block.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_metadata_tile.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_section_header.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _expandedContentIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

final _expandedMetadataIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

class ReaderCommentaryPanel extends ConsumerWidget {
  final String segmentId;
  final String textLanguage;
  final ReaderParams params;
  final double availableHeight;

  const ReaderCommentaryPanel({
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
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );

    return ReaderBottomPanelShell(
      title: localizations.text_commentary,
      params: params,
      availableHeight: availableHeight,
      onDismiss: () {
        notifier.closeCommentary();
        _resetExpansion(ref);
      },
      child: segmentCommentaries.when(
        data:
            (data) => _CommentaryList(
              commentaries: data.commentaries,
              segmentId: segmentId,
              textLanguage: textLanguage,
            ),
        error:
            (error, _) => _ErrorState(
              error: error,
              onRetry:
                  () => ref.invalidate(
                    segmentCommentaryFutureProvider(segmentId),
                  ),
            ),
        loading: () => const CommentarySkeleton(),
      ),
    );
  }
}

class _CommentaryList extends ConsumerWidget {
  const _CommentaryList({
    required this.commentaries,
    required this.segmentId,
    required this.textLanguage,
  });

  final List<SegmentCommentary> commentaries;
  final String segmentId;
  final String textLanguage;

  /// `zh` and `lzh` are treated as a family pair and always placed adjacent.
  static const _chinesePair = {'zh', 'lzh'};

  /// Builds the ordered list of language sections to render.
  ///
  /// **Chinese text (`zh` / `lzh`):** Both Chinese variants are pinned at the
  /// top — the text's language first, the partner second. The partner section
  /// always appears (showing "not available" when empty). All other languages
  /// that have commentaries follow, sorted A→Z.
  ///
  /// **Non-Chinese text:** Text language is first. Remaining languages are
  /// sorted A→Z, but `zh` is moved to immediately follow `lzh` so the Chinese
  /// family always appears together.
  List<String> _orderedLanguageCodes(
    Map<String, List<SegmentCommentary>> byLanguage,
  ) {
    if (_chinesePair.contains(textLanguage)) {
      // Chinese text: pin both Chinese variants at the top — text language
      // first, partner always second (shows "not available" when empty).
      final partner = textLanguage == 'zh' ? 'lzh' : 'zh';
      final ordered = <String>[textLanguage];
      ordered.add(partner);
      final others =
          byLanguage.keys.where((l) => !_chinesePair.contains(l)).toList()
            ..sort();
      ordered.addAll(others);
      return ordered;
    } else {
      // Non-Chinese text: text language first, rest A→Z with zh kept right
      // after lzh so the Chinese pair is always adjacent.
      final ordered = <String>[textLanguage];
      final allOthers =
          byLanguage.keys.where((l) => l != textLanguage).toList()..sort();
      if (allOthers.contains('lzh') && allOthers.contains('zh')) {
        allOthers.remove('zh');
        allOthers.insert(allOthers.indexOf('lzh') + 1, 'zh');
      }
      ordered.addAll(allOthers);
      return ordered;
    }
  }

  /// Each commentary followed by the editions that translate it, so every
  /// language lands in its own section.
  static Iterable<SegmentCommentary> _flatten(
    Iterable<SegmentCommentary> items,
  ) sync* {
    for (final c in items) {
      yield c;
      yield* _flatten(c.translations);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byLanguage = <String, List<SegmentCommentary>>{};
    for (final c in _flatten(commentaries)) {
      byLanguage.putIfAbsent(c.language, () => []).add(c);
    }
    final orderedLanguages = _orderedLanguageCodes(byLanguage);

    final expandedContent = ref.watch(_expandedContentIndexProvider(segmentId));
    final expandedMetadata = ref.watch(
      _expandedMetadataIndexProvider(segmentId),
    );

    final children = <Widget>[];
    var globalIndex = 0;
    for (final code in orderedLanguages) {
      final items = byLanguage[code] ?? const <SegmentCommentary>[];
      if (items.isEmpty) {
        children.add(ReaderPanelSectionHeader(languageCode: code));
        children.add(_LanguageUnavailable(languageCode: code));
        continue;
      }
      children.add(
        ReaderPanelSectionHeader(languageCode: code, count: items.length),
      );
      for (final commentary in items) {
        final index = globalIndex++;
        children.add(
          _CommentaryItem(
            commentary: commentary,
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

/// Placeholder rendered under a language section header when no commentary in
/// that language is available for the current segment.
class _LanguageUnavailable extends StatelessWidget {
  const _LanguageUnavailable({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    final label = getLanguageName(languageCode, context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.itemSpacing,
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.itemSpacing,
      ),
      child: Text(
        localizations.commentary_not_available_for_language(label),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _CommentaryItem extends ConsumerWidget {
  const _CommentaryItem({
    required this.commentary,
    required this.index,
    required this.segmentId,
    required this.isContentExpanded,
    required this.isMetadataExpanded,
  });

  final SegmentCommentary commentary;
  final int index;
  final String segmentId;
  final bool isContentExpanded;
  final bool isMetadataExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = commentary.segments
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
            language: commentary.language,
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
            title: commentary.title,
            language: commentary.language,
            source: commentary.source,
            license: commentary.license,
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
