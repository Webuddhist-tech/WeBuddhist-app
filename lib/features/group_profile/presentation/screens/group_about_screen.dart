import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/url_opener.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_profile_link_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';

final _logger = AppLogger('GroupAboutScreen');

class GroupAboutScreen extends StatelessWidget {
  final String title;
  final String? description;
  final List<GroupProfileSocialLink> links;

  const GroupAboutScreen({
    super.key,
    required this.title,
    this.description,
    this.links = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trimmedDescription = description?.trim();
    final hasDescription =
        trimmedDescription != null && trimmedDescription.isNotEmpty;
    final orderedLinks = GroupProfileLinkUtils.orderedLinks(links);
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            AppAssets.arrowLeft,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDescription) ...[
              _SectionHeader(
                title: context.l10n.group_about_description,
                isDark: isDark,
                large: true,
              ),
              const SizedBox(height: 10),
              PlanInlineMarkdownView(
                content: trimmedDescription,
                fontSize: 15.0,
              ),
              const SizedBox(height: 28),
            ],
            if (orderedLinks.isNotEmpty) ...[
              _SectionHeader(
                title: context.l10n.group_links_title.toUpperCase(),
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              ...orderedLinks.map(
                (link) => _AboutLinkTile(link: link, isDark: isDark),
              ),
            ],
            if (!hasDescription && orderedLinks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  context.l10n.group_about_empty,
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final bool large;

  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Text(
      title,
      style:
          large
              ? TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: titleColor,
              )
              : TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: secondaryColor,
              ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  final GroupProfileSocialLink link;
  final bool isDark;

  const _AboutLinkTile({required this.link, required this.isDark});

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.tryParse(link.url.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _logger.warning('Blocked invalid group link URL: ${link.url}');
      if (context.mounted) {
        _showSnackBar(context, context.l10n.link_invalid);
      }
      return;
    }

    try {
      if (!await openUrl(uri.toString())) {
        _logger.warning('Cannot launch group link URL: ${link.url}');
        if (context.mounted) {
          _showSnackBar(context, context.l10n.link_cannot_open);
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to launch group link URL: ${link.url}',
        e,
        stackTrace,
      );
      if (context.mounted) {
        _showSnackBar(context, context.l10n.link_invalid);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: () => _launchUrl(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              GroupProfileLinkUtils.iconForPlatform(link.platform),
              size: 22,
              color: titleColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GroupProfileLinkUtils.labelForPlatform(
                      link.platform,
                      context,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.url,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(AppAssets.arrowSquareOut, size: 18, color: secondaryColor),
          ],
        ),
      ),
    );
  }
}
