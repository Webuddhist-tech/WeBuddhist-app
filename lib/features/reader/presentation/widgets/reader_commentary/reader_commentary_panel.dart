import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_list_order.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_resource_list.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The verse sheet's Commentary tab: the verse's commentaries.
class ReaderCommentaryPanel extends ConsumerWidget {
  final String segmentId;
  final String textLanguage;
  final ReaderParams params;

  const ReaderCommentaryPanel({
    super.key,
    required this.segmentId,
    required this.textLanguage,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );

    return segmentCommentaries.when(
      data:
          (data) => _CommentaryList(
            commentaries: data.commentaries,
            textLanguage: textLanguage,
            commentaryTextId:
                params.navigationContext?.currentItem?.commentaryTextId,
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
    );
  }
}

class _CommentaryList extends StatelessWidget {
  const _CommentaryList({
    required this.commentaries,
    required this.textLanguage,
    required this.commentaryTextId,
  });

  final List<SegmentCommentary> commentaries;
  final String textLanguage;
  final String? commentaryTextId;

  @override
  Widget build(BuildContext context) {
    final order = orderCommentaries(
      commentaries: commentaries,
      textLanguage: textLanguage,
      commentaryTextId: commentaryTextId,
    );
    final pinned = order.pinned;
    return ReaderResourceList(
      textLanguage: textLanguage,
      firstLanguage: pinned?.language,
      rememberAs: 'commentary',
      entries: [
        if (pinned != null) _entry(pinned),
        for (final code in order.languageCodes)
          for (final commentary
              in order.byLanguage[code] ?? const <SegmentCommentary>[])
            _entry(commentary),
      ],
    );
  }

  static ReaderResourceEntry _entry(SegmentCommentary commentary) =>
      ReaderResourceEntry(
        content: commentary.segments
            .map((s) => normalizeSegmentHtml(s.content))
            .where((s) => s.isNotEmpty)
            .join('<br><br>'),
        language: commentary.language,
        title: commentary.title,
        source: commentary.source,
        license: commentary.license,
      );
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
