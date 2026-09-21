import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

enum ConnectMyEmptyStateType { feed, events, posts, practices, groups }

/// Empty state shown in Connect tabs when the My segment has no content.
class ConnectMyEmptyState extends StatelessWidget {
  const ConnectMyEmptyState({super.key, required this.type, this.onBrowseTap});

  final ConnectMyEmptyStateType type;
  final VoidCallback? onBrowseTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              AppAssets.connect,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _title(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _subtitle(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: subtitleColor, height: 1.5),
          ),
          if (onBrowseTap != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBrowseTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _browseLabel(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (type) {
    ConnectMyEmptyStateType.feed => l10n.connect_my_empty_feed_title,
    ConnectMyEmptyStateType.events => l10n.connect_my_empty_events_title,
    ConnectMyEmptyStateType.posts => l10n.connect_my_empty_posts_title,
    ConnectMyEmptyStateType.practices => l10n.connect_my_empty_practices_title,
    ConnectMyEmptyStateType.groups => l10n.connect_my_empty_groups_title,
  };

  String _subtitle(AppLocalizations l10n) => switch (type) {
    ConnectMyEmptyStateType.feed => l10n.connect_my_empty_feed_subtitle,
    ConnectMyEmptyStateType.events => l10n.connect_my_empty_events_subtitle,
    ConnectMyEmptyStateType.posts => l10n.connect_my_empty_posts_subtitle,
    ConnectMyEmptyStateType.practices =>
      l10n.connect_my_empty_practices_subtitle,
    ConnectMyEmptyStateType.groups => l10n.connect_my_empty_groups_subtitle,
  };

  String _browseLabel(AppLocalizations l10n) => switch (type) {
    ConnectMyEmptyStateType.feed => l10n.connect_my_empty_feed_browse,
    ConnectMyEmptyStateType.events => l10n.connect_my_empty_events_browse,
    ConnectMyEmptyStateType.posts => l10n.connect_my_empty_posts_browse,
    ConnectMyEmptyStateType.practices => l10n.connect_my_empty_practices_browse,
    ConnectMyEmptyStateType.groups => l10n.discover_groups,
  };
}
