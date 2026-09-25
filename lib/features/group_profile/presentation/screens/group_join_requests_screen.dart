import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupJoinRequestsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupJoinRequestsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupJoinRequestsScreen> createState() =>
      _GroupJoinRequestsScreenState();
}

class _GroupJoinRequestsScreenState
    extends ConsumerState<GroupJoinRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(groupJoinRequestsProvider(widget.groupId).notifier)
          .loadInitial();
    });
  }

  Future<void> _approve(String requestId) async {
    final requests = ref.read(groupJoinRequestsProvider(widget.groupId));
    if (requests.isLoadingMore || requests.isDeciding) return;

    final admitted = await ref
        .read(groupJoinRequestsProvider(widget.groupId).notifier)
        .approve(requestId);
    if (!mounted) return;
    if (!admitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.group_join_requests_admit_error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.invalidate(groupProfileProvider(widget.groupId));
    if (ref.exists(groupMembersProvider(widget.groupId))) {
      ref.read(groupMembersProvider(widget.groupId).notifier).loadInitial();
    }
  }

  Future<void> _reject(String requestId) async {
    final requests = ref.read(groupJoinRequestsProvider(widget.groupId));
    if (requests.isLoadingMore || requests.isDeciding) return;

    final denied = await ref
        .read(groupJoinRequestsProvider(widget.groupId).notifier)
        .reject(requestId);
    if (!mounted) return;
    if (!denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.group_join_requests_deny_error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _onScrollLoadMore(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      ref.read(groupJoinRequestsProvider(widget.groupId).notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(groupJoinRequestsProvider(widget.groupId));
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
                      context.l10n.group_join_requests_title,
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
    GroupJoinRequestsState state,
    bool isDark,
  ) {
    if (state.isLoading && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.requests.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        customMessage: context.l10n.group_join_requests_load_error,
        onRetry:
            () =>
                ref
                    .read(groupJoinRequestsProvider(widget.groupId).notifier)
                    .retry(),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.group_join_requests_empty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
              fontFamily: getSystemFontFamily(
                Localizations.localeOf(context).languageCode,
              ),
            ),
          ),
        ),
      );
    }

    // A later page that failed keeps the rows it has; the footer says so and
    // offers a retry, since a list too short to scroll never asks again.
    final loadMoreFailed = state.error != null && !state.isLoadingMore;
    final hasFooter = state.isLoadingMore || loadMoreFailed;
    final itemCount = state.requests.length + (hasFooter ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollLoadMore,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.requests.length) {
            if (loadMoreFailed) return _buildLoadMoreError(context, isDark);
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final request = state.requests[index];
          final canDecide = !state.isDeciding && !state.isLoadingMore;
          return _GroupJoinRequestTile(
            request: request,
            isDark: isDark,
            isApproving: state.approvingRequestId == request.id,
            isRejecting: state.rejectingRequestId == request.id,
            onAdmit: canDecide ? () => _approve(request.id) : null,
            onDeny: canDecide ? () => _reject(request.id) : null,
          );
        },
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
            context.l10n.group_join_requests_load_error,
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
                () =>
                    ref
                        .read(
                          groupJoinRequestsProvider(widget.groupId).notifier,
                        )
                        .retry(),
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

class _GroupJoinRequestTile extends StatelessWidget {
  final GroupJoinRequest request;
  final bool isDark;
  final bool isApproving;
  final bool isRejecting;
  final VoidCallback? onAdmit;
  final VoidCallback? onDeny;

  const _GroupJoinRequestTile({
    required this.request,
    required this.isDark,
    required this.isApproving,
    required this.isRejecting,
    required this.onAdmit,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final fontFamily = getSystemFontFamily(locale.languageCode);
    final nameColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final name = request.userName.trim();
    final email = request.email.trim();
    final avatarUrl = request.userAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child:
                  hasAvatar
                      ? CachedNetworkImageWidget(
                        key: ValueKey(avatarUrl),
                        imageUrl: avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: _avatarFallback(isDark),
                      )
                      : _avatarFallback(isDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(16),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                    fontFamily: fontFamily,
                  ),
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: context.tibetanStrutStyle(13, compact: true),
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DecisionButton(
            label: context.l10n.group_join_requests_admit,
            backgroundColor:
                isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
            foregroundColor:
                isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
            fontFamily: fontFamily,
            isLoading: isApproving,
            onPressed: onAdmit,
          ),
          const SizedBox(width: 8),
          _DecisionButton(
            label: context.l10n.group_join_requests_deny,
            backgroundColor:
                isDark ? AppColors.chipBackgroundDark : AppColors.grey100,
            foregroundColor: nameColor,
            fontFamily: fontFamily,
            isLoading: isRejecting,
            onPressed: onDeny,
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        size: 24,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? fontFamily;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _DecisionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.fontFamily,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isTibetan = context.isTibetanLocale;
    return Material(
      color: backgroundColor,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: isTibetan ? 40 : 36,
            child: Center(
              child:
                  isLoading
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foregroundColor,
                        ),
                      )
                      : Text(
                        label,
                        strutStyle: context.tibetanStrutStyle(
                          14,
                          compact: true,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: foregroundColor,
                          fontFamily: fontFamily,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
