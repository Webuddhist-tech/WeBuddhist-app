import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/home/presentation/providers/verse_of_day_engagement_providers.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_sheet_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// People who liked the verse of the day.
class VerseLikersSheet extends ConsumerStatefulWidget {
  const VerseLikersSheet({super.key, required this.verseId});

  final String verseId;

  static const double _initialSize = 0.6;
  static const double _minSize = 0.4;
  static const double _maxSize = 0.96;

  static Future<void> show(BuildContext context, {required String verseId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => VerseLikersSheet(verseId: verseId),
    );
  }

  @override
  ConsumerState<VerseLikersSheet> createState() => _VerseLikersSheetState();
}

class _VerseLikersSheetState extends ConsumerState<VerseLikersSheet> {
  ScrollController? _scrollController;

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _attachScrollController(ScrollController controller) {
    if (identical(_scrollController, controller)) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller..addListener(_onScroll);
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    ref.read(verseOfDayLikersProvider(widget.verseId).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verseOfDayLikersProvider(widget.verseId));
    final likeCount = ref.watch(
      verseOfDayLikesProvider(widget.verseId).select((s) => s.likeCount),
    );

    return VerseSheetTapToDismiss(
      child: DraggableScrollableSheet(
        initialChildSize: VerseLikersSheet._initialSize,
        minChildSize: VerseLikersSheet._minSize,
        maxChildSize: VerseLikersSheet._maxSize,
        snap: true,
        snapSizes: const [
          VerseLikersSheet._minSize,
          VerseLikersSheet._initialSize,
          VerseLikersSheet._maxSize,
        ],
        snapAnimationDuration: const Duration(milliseconds: 180),
        builder: (context, scrollController) {
          _attachScrollController(scrollController);

          return VerseSheetTapShield(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                child: Column(
                  children: [
                    VerseSheetHeader(
                      title: context.l10n.verse_likes_title(likeCount),
                    ),
                    Expanded(
                      child: _buildBody(context, state, scrollController),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    VerseOfDayLikersState state,
    ScrollController scrollController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.error != null && state.likers.isEmpty) {
      return ErrorStateWidget(error: state.error!, onRetry: _loadMore);
    }

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        for (final liker in state.likers)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                VerseUserAvatar(
                  name: liker.user.displayName,
                  avatarUrl: liker.user.avatarUrl,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    liker.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          Center(
            child: TextButton(
              onPressed: _loadMore,
              child: Text(context.l10n.tryAgain),
            ),
          ),
      ],
    );
  }
}
