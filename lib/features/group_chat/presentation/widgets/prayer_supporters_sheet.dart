import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who is praying for one of the viewer's own requests, and how many times.
class PrayerSupportersSheet extends ConsumerStatefulWidget {
  const PrayerSupportersSheet({
    super.key,
    required this.eventId,
    required this.request,
  });

  final String eventId;

  /// The request as it was when opened; an edit made while the sheet is up
  /// is picked up from the event's request list.
  final ChatMessageDTO request;

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    required ChatMessageDTO request,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder:
          (_) => PrayerSupportersSheet(eventId: eventId, request: request),
    );
  }

  @override
  ConsumerState<PrayerSupportersSheet> createState() =>
      _PrayerSupportersSheetState();
}

class _PrayerSupportersSheetState extends ConsumerState<PrayerSupportersSheet> {
  final _scrollController = ScrollController();
  static const double _loadMoreThreshold = 200;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(
        ref
            .read(prayerSupportersProvider(widget.request.id).notifier)
            .loadMore(),
      );
    }
  }

  ChatMessageDTO _currentRequest() {
    final id = widget.request.id;
    return ref.watch(
          prayerRequestsProvider(widget.eventId).select(
            (state) =>
                state.requests.where((request) => request.id == id).firstOrNull,
          ),
        ) ??
        widget.request;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prayerSupportersProvider(widget.request.id));

    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final height = math.max(
      260.0,
      math.min(size.height * 0.75, size.height - topInset - 48),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(child: _buildBody(context, state, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final title = context.l10n.event_prayer_praying_for_you;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(AppAssets.arrowLeft),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: context.tibetanStrutStyle(17, compact: true),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrayerSupportersState state,
    bool isDark,
  ) {
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    // Watched here, in build: the item builder below runs during layout.
    final request = _currentRequest();
    final count = state.hasLoaded ? state.total : widget.request.prayerCount;
    final showError =
        state.error != null && state.supporters.isEmpty && state.hasLoaded;
    final showSpinner =
        !state.hasLoaded || (state.isLoading && state.supporters.isEmpty);
    final itemCount = state.supporters.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestCard(
                request: request,
                title: context.l10n.event_prayer_your_request,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.event_prayer_people_praying(count),
                strutStyle: context.tibetanStrutStyle(13, compact: true),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (showSpinner)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (showError)
                _Notice(
                  text: context.l10n.event_prayer_supporters_failed,
                  color: muted,
                  actionLabel: context.l10n.group_chat_retry,
                  onAction:
                      () => unawaited(
                        ref
                            .read(
                              prayerSupportersProvider(
                                widget.request.id,
                              ).notifier,
                            )
                            .load(),
                      ),
                )
              else if (state.supporters.isEmpty)
                _Notice(
                  text: context.l10n.event_prayer_no_supporters,
                  color: muted,
                ),
            ],
          );
        }
        final position = index - 1;
        if (position >= state.supporters.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _SupporterRow(
          supporter: state.supporters[position],
          isDark: isDark,
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.title,
    required this.isDark,
  });

  final ChatMessageDTO request;
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: prayerIntentionCardColor(request.intention, isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(
          prayerIntentionCardBorder(request.intention, isDark),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            strutStyle: context.tibetanStrutStyle(12, compact: true),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.body,
            strutStyle: context.tibetanStrutStyle(15),
            style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _SupporterRow extends StatelessWidget {
  const _SupporterRow({required this.supporter, required this.isDark});

  final ChatPrayerUserDTO supporter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final name =
        chatSenderDisplayName(
          messageName: supporter.name,
          senderEmail: supporter.email,
        ) ??
        context.l10n.group_chat_unknown_sender;
    // Same neutral grey as the stack on the card, not a per-person colour.
    final accent = prayerIntentionColor(null, isDark);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final times = supporter.prayerCount;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          PrayerAvatar(
            avatarUrl: supporter.avatarUrl,
            label: name,
            size: 32,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: context.tibetanStrutStyle(14, compact: true),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (times > 0) ...[
            const SizedBox(width: 12),
            Text(
              '$times',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            strutStyle: context.tibetanStrutStyle(13),
            style: TextStyle(fontSize: 13, color: color),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
