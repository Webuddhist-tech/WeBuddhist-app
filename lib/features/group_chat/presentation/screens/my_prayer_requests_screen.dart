import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/my_prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_delete_dialog.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/new_prayer_request_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_supporters_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every prayer request the viewer has posted, in any space or event,
/// active ones first and accomplished ones under their own heading.
class MyPrayerRequestsScreen extends ConsumerStatefulWidget {
  const MyPrayerRequestsScreen({super.key});

  @override
  ConsumerState<MyPrayerRequestsScreen> createState() =>
      _MyPrayerRequestsScreenState();
}

class _MyPrayerRequestsScreenState
    extends ConsumerState<MyPrayerRequestsScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 200;

  MyPrayerRequestsNotifier get _notifier =>
      ref.read(myPrayerRequestsProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(_notifier.loadMore());
    }
  }

  Future<void> _edit(ChatMessageDTO request) async {
    await NewPrayerRequestSheet.show(
      context,
      editing: request,
      submit:
          (body, intention) =>
              _notifier.edit(request.id, body: body, intention: intention),
    );
  }

  Future<void> _toggleCompleted(ChatMessageDTO request) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _notifier.setCompleted(
      request.id,
      isCompleted: !request.isCompleted,
    );
    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.event_prayer_update_failed)),
      ),
      (_) {},
    );
  }

  Future<void> _delete(ChatMessageDTO request) async {
    final l10n = context.l10n;
    final confirmed = await confirmChatMessageDelete(
      context,
      title: l10n.event_prayer_delete_title,
      body: l10n.me_prayer_delete_body,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _notifier.delete(request.id);
    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.event_prayer_delete_failed)),
      ),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(myPrayerRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.l10n.me_prayer_requests,
          strutStyle: context.tibetanStrutStyle(20, compact: true),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, MyPrayerRequestsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final l10n = context.l10n;

    if (!state.hasLoaded || (state.isLoading && state.requests.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.requests.isEmpty && state.error != null) {
      return _Notice(
        text: l10n.event_prayer_load_failed,
        color: muted,
        actionLabel: l10n.group_chat_retry,
        onAction: () => unawaited(_notifier.load()),
      );
    }
    if (state.requests.isEmpty) {
      return _Notice(
        text: l10n.me_prayer_requests_empty_title,
        detail: l10n.me_prayer_requests_empty_body,
        color: muted,
      );
    }

    final user = ref.watch(userProvider).user;
    final selfName =
        joinChatName(user?.firstName, user?.lastName) ?? l10n.event_prayer_you;
    final rows = <_Row>[
      if (state.active.isNotEmpty) ...[
        _SectionRow(l10n.event_prayer_section_active),
        for (final request in state.active) _RequestRow(request),
      ],
      if (state.accomplished.isNotEmpty) ...[
        _SectionRow(l10n.event_prayer_section_accomplished),
        for (final request in state.accomplished) _RequestRow(request),
      ],
    ];

    return RefreshIndicator(
      onRefresh: _notifier.load,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final row = rows[index];
          if (row is _SectionRow) {
            return _SectionHeader(label: row.label, isDark: isDark);
          }
          final request = (row as _RequestRow).request;
          return PrayerRequestTile(
            key: ValueKey(request.id),
            request: request,
            displayName: selfName,
            avatarUrl: user?.avatarUrl,
            isOwn: true,
            onShowSupporters:
                () => unawaited(
                  PrayerSupportersSheet.show(context, request: request),
                ),
            onEdit: () => unawaited(_edit(request)),
            onDelete: () => unawaited(_delete(request)),
            onToggleCompleted: () => unawaited(_toggleCompleted(request)),
          );
        },
      ),
    );
  }
}

sealed class _Row {}

class _SectionRow extends _Row {
  _SectionRow(this.label);

  final String label;
}

class _RequestRow extends _Row {
  _RequestRow(this.request);

  final ChatMessageDTO request;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(
        label,
        strutStyle: context.tibetanStrutStyle(14, compact: true),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? detail;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(15, compact: true),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(13),
                style: TextStyle(fontSize: 13, color: color),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
