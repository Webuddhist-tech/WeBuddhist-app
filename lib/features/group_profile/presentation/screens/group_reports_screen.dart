import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_reports_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_report_reason_label.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin moderation queue: reported posts, comments, and chat messages,
/// each with the reports filed against it.
class GroupReportsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupReportsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupReportsScreen> createState() => _GroupReportsScreenState();
}

class _GroupReportsScreenState extends ConsumerState<GroupReportsScreen> {
  static const _sectionOrder = [
    GroupReportKind.post,
    GroupReportKind.comment,
    GroupReportKind.chatMessage,
  ];

  final Set<String> _expandedItemKeys = {};
  final Set<String> _resolvingItemKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(groupReportsProvider(widget.groupId).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _itemKey(GroupReportedItem item) =>
      '${item.kind.apiValue}:${item.targetId}';

  void _toggleExpanded(GroupReportedItem item) {
    final key = _itemKey(item);
    setState(() {
      if (!_expandedItemKeys.remove(key)) _expandedItemKeys.add(key);
    });
  }

  Future<void> _resolve(GroupReportedItem item) async {
    // One resolve reloads the queue. A second tap before that finishes is
    // ignored: the notifier would return false without trying the request,
    // and the screen would show an error for an item it never sent.
    if (_resolvingItemKeys.isNotEmpty) return;
    final key = _itemKey(item);
    _resolvingItemKeys.add(key);
    setState(() {});

    final resolved = await ref
        .read(groupReportsProvider(widget.groupId).notifier)
        .resolveItem(item);
    if (!mounted) return;
    setState(() {
      _resolvingItemKeys.remove(key);
      if (resolved) _expandedItemKeys.remove(key);
    });
    if (!resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.something_went_wrong),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static bool _isNearEnd(ScrollMetrics metrics) =>
      metrics.pixels >= metrics.maxScrollExtent - 200;

  bool _onScrollLoadMore(ScrollNotification notification) {
    if (_isNearEnd(notification.metrics)) {
      ref.read(groupReportsProvider(widget.groupId).notifier).loadMore();
    }
    return false;
  }

  /// Reports on the same item share one card, so a whole page can collapse
  /// into a list too short to scroll, and scrolling is what asks for the next
  /// page. Keeps paging until the list reaches past the screen or the queue
  /// ends. Stops on an error; the footer offers the retry.
  void _loadMoreIfShort() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = ref.read(groupReportsProvider(widget.groupId));
    if (!state.hasMore ||
        state.isLoading ||
        state.isLoadingMore ||
        state.error != null) {
      return;
    }
    if (_isNearEnd(_scrollController.position)) {
      ref.read(groupReportsProvider(widget.groupId).notifier).loadMore();
    }
  }

  String _sectionTitle(BuildContext context, GroupReportKind kind) {
    return switch (kind) {
      GroupReportKind.post => context.l10n.group_reports_section_posts,
      GroupReportKind.comment => context.l10n.group_reports_section_comments,
      GroupReportKind.chatMessage =>
        context.l10n.group_reports_section_messages,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(groupReportsProvider(widget.groupId));
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(AppAssets.arrowLeft, color: titleColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.group_reports_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: context.tibetanStrutStyle(20),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        fontFamily: getSystemFontFamily(
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, state, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupReportsState state,
    bool isDark,
  ) {
    final notifier = ref.read(groupReportsProvider(widget.groupId).notifier);

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        customMessage: context.l10n.group_reports_load_error,
        onRetry: notifier.retry,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.loadInitial,
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.l10n.group_reports_empty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textSecondary,
                          fontFamily: getSystemFontFamily(
                            Localizations.localeOf(context).languageCode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
    }

    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final children = <Widget>[];
    for (final kind in _sectionOrder) {
      final items = state.itemsOfKind(kind);
      if (items.isEmpty) continue;

      // Separates subsections only. Cards in the same section have no rule.
      if (children.isNotEmpty) {
        children.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
      children.add(
        _SectionHeader(title: _sectionTitle(context, kind), isDark: isDark),
      );
      for (final item in items) {
        children.add(
          _ReportedItemTile(
            groupId: widget.groupId,
            item: item,
            isDark: isDark,
            isExpanded: _expandedItemKeys.contains(_itemKey(item)),
            onToggleExpanded: () => _toggleExpanded(item),
            onDismiss:
                _resolvingItemKeys.isNotEmpty ? null : () => _resolve(item),
          ),
        );
      }
    }

    // A later page that failed keeps the items it has; the footer says so and
    // offers a retry, since a list too short to scroll never asks again.
    final loadMoreFailed = state.error != null && !state.isLoadingMore;
    if (state.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (loadMoreFailed) {
      children.add(_buildLoadMoreError(context, isDark));
    }

    if (state.hasMore &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfShort());
    }

    return RefreshIndicator(
      onRefresh: notifier.loadInitial,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollLoadMore,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: children,
        ),
      ),
    );
  }

  Widget _buildLoadMoreError(BuildContext context, bool isDark) {
    final fontFamily = getSystemFontFamily(
      Localizations.localeOf(context).languageCode,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            context.l10n.group_reports_load_error,
            textAlign: TextAlign.center,
            strutStyle: context.tibetanStrutStyle(14),
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
              fontFamily: fontFamily,
            ),
          ),
          TextButton(
            onPressed:
                ref.read(groupReportsProvider(widget.groupId).notifier).retry,
            child: Text(
              context.l10n.retry,
              style: TextStyle(fontFamily: fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        strutStyle: context.tibetanStrutStyle(15),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          fontFamily: getSystemFontFamily(
            Localizations.localeOf(context).languageCode,
          ),
        ),
      ),
    );
  }
}

/// One reported item: the content card and its expandable list of reports.
class _ReportedItemTile extends StatelessWidget {
  final String groupId;
  final GroupReportedItem item;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  /// Resolves the item's reports; null while any item is resolving.
  final VoidCallback? onDismiss;

  const _ReportedItemTile({
    required this.groupId,
    required this.item,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportedContentCard(
            groupId: groupId,
            item: item,
            isDark: isDark,
            onDismiss: onDismiss,
          ),
          _ReportsToggle(
            count: item.reports.length,
            isExpanded: isExpanded,
            isDark: isDark,
            onTap: onToggleExpanded,
          ),
          if (isExpanded)
            for (final report in item.reports)
              _ReporterRow(groupId: groupId, report: report, isDark: isDark),
        ],
      ),
    );
  }
}

class _ReportedContentCard extends StatelessWidget {
  final String groupId;
  final GroupReportedItem item;
  final bool isDark;
  final VoidCallback? onDismiss;

  const _ReportedContentCard({
    required this.groupId,
    required this.item,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (viewLabel, deleteLabel) = switch (item.kind) {
      GroupReportKind.post => (
        l10n.group_reports_view_post,
        l10n.group_reports_delete_post,
      ),
      GroupReportKind.comment => (
        l10n.group_reports_view_post,
        l10n.group_reports_delete_comment,
      ),
      GroupReportKind.chatMessage => (
        l10n.group_reports_view_message,
        l10n.group_reports_delete_message,
      ),
    };
    final isMessage = item.kind == GroupReportKind.chatMessage;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.cardBackgroundDark
                : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMessage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(
                  groupId: groupId,
                  userId: item.reportedUser?.id,
                  name: item.reportedUser?.displayName ?? '',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                Expanded(child: _MessageBubble(item: item, isDark: isDark)),
                _DismissButton(isDark: isDark, onPressed: onDismiss),
              ],
            )
          else
            _AuthoredContent(
              groupId: groupId,
              item: item,
              isDark: isDark,
              onDismiss: onDismiss,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _CardActionButton(
                  label: viewLabel,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                  onPressed: null,
                ),
              ),
              Expanded(
                child: _CardActionButton(
                  label: deleteLabel,
                  color: AppColors.danger,
                  onPressed: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar, author, and text of a reported post or comment.
class _AuthoredContent extends StatelessWidget {
  final String groupId;
  final GroupReportedItem item;
  final bool isDark;
  final VoidCallback? onDismiss;

  const _AuthoredContent({
    required this.groupId,
    required this.item,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getSystemFontFamily(
      Localizations.localeOf(context).languageCode,
    );
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final author = item.reportedUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _UserAvatar(
              groupId: groupId,
              userId: author?.id,
              name: author?.displayName ?? '',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NameAndTime(
                name: author?.displayName ?? '',
                createdAt: item.latest.createdAt,
                isDark: isDark,
              ),
            ),
            _DismissButton(isDark: isDark, onPressed: onDismiss),
          ],
        ),
        if (item.contentText.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              item.contentText,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DismissButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;

  const _DismissButton({required this.isDark, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabledColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    // A null handler means a dismiss is already in flight. The icon stays
    // visible so the row does not jump, but greyed so a tap that does
    // nothing does not look available.
    final color =
        onPressed == null
            ? (isDark ? AppColors.grey600 : AppColors.grey400)
            : enabledColor;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(AppAssets.x, color: color),
      ),
    );
  }
}

/// A reported chat message, drawn like it appears in the chat thread.
class _MessageBubble extends StatelessWidget {
  final GroupReportedItem item;
  final bool isDark;

  const _MessageBubble({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fontFamily = getSystemFontFamily(
      Localizations.localeOf(context).languageCode,
    );
    final senderName = item.reportedUser?.displayName ?? '';

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.chipBackgroundDark : AppColors.grey00,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName.isNotEmpty)
                Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(12, compact: true),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.accentGold
                            : AppColors.accentGoldDark,
                    fontFamily: fontFamily,
                  ),
                ),
              if (item.contentText.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.contentText,
                  strutStyle: context.tibetanStrutStyle(14),
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _CardActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        // View and delete are not wired up yet. Dimmed so an admin can tell
        // the button is inert instead of tapping a control that does nothing.
        disabledForegroundColor: color.withValues(alpha: 0.38),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        strutStyle: context.tibetanStrutStyle(14, compact: true),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: getSystemFontFamily(
            Localizations.localeOf(context).languageCode,
          ),
        ),
      ),
    );
  }
}

class _ReportsToggle extends StatelessWidget {
  final int count;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onTap;

  const _ReportsToggle({
    required this.count,
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.group_reports_count(count),
                strutStyle: context.tibetanStrutStyle(14, compact: true),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: getSystemFontFamily(
                    Localizations.localeOf(context).languageCode,
                  ),
                ),
              ),
            ),
            Icon(
              isExpanded ? AppAssets.caretUp : AppAssets.caretDown,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Who filed one report, when, and why.
class _ReporterRow extends StatelessWidget {
  final String groupId;
  final GroupReport report;
  final bool isDark;

  const _ReporterRow({
    required this.groupId,
    required this.report,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = report.reporter?.displayName ?? '';
    // Reports made off a fixed reason carry no description, and the reason is
    // then the only word on why this was filed.
    final detail =
        report.description.isNotEmpty
            ? report.description
            : groupReportReasonLabel(context.l10n, report.reason);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            groupId: groupId,
            userId: report.reporter?.id,
            name: name,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameAndTime(
                  name: name,
                  createdAt: report.createdAt,
                  isDark: isDark,
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    strutStyle: context.tibetanStrutStyle(13, compact: true),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontFamily: getSystemFontFamily(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameAndTime extends StatelessWidget {
  final String name;
  final DateTime? createdAt;
  final bool isDark;

  const _NameAndTime({
    required this.name,
    required this.createdAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getSystemFontFamily(
      Localizations.localeOf(context).languageCode,
    );
    final relativeTime = connectCommentRelativeTime(createdAt);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (relativeTime.isNotEmpty)
            TextSpan(
              text: name.isEmpty ? relativeTime : ' · $relativeTime',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      strutStyle: context.tibetanStrutStyle(13, compact: true),
      style: TextStyle(fontSize: 13, fontFamily: fontFamily),
    );
  }
}

/// Photo from the group members list when this user has one, otherwise an
/// initial. The reports payload only carries the user id.
class _UserAvatar extends ConsumerWidget {
  final String groupId;
  final String? userId;
  final String name;
  final bool isDark;

  const _UserAvatar({
    required this.groupId,
    required this.userId,
    required this.name,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = userId?.trim() ?? '';
    final avatarUrl =
        id.isEmpty ? null : ref.watch(groupReportAvatarsProvider(groupId))[id];
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child:
            hasAvatar
                ? CachedNetworkImageWidget(
                  key: ValueKey(avatarUrl),
                  imageUrl: avatarUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorWidget: _fallback(initial),
                )
                : _fallback(initial),
      ),
    );
  }

  Widget _fallback(String initial) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Center(
        child:
            initial.isEmpty
                ? Icon(
                  AppAssets.profile,
                  size: 16,
                  color: isDark ? AppColors.grey500 : AppColors.grey600,
                )
                : Text(
                  initial,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.grey400 : AppColors.grey800,
                  ),
                ),
      ),
    );
  }
}
