import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Link attached to a post: a YouTube thumbnail card, an Open Graph preview
/// card, or a plain link row when no preview is available.
class ConnectPostLinkCard extends ConsumerWidget {
  const ConnectPostLinkCard({
    super.key,
    required this.url,
    this.label,
    this.onRemove,
    this.onTap,
  });

  final String url;
  final String? label;

  /// When set, an X badge is drawn on the card (composer usage).
  final VoidCallback? onRemove;

  /// Defaults to opening the link externally.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videoId = ConnectPostLinkUtils.youtubeVideoId(url);
    final preview =
        ChatLinkPreviewService.isPreviewableUrl(url)
            ? ref.watch(chatLinkPreviewProvider(url)).valueOrNull
            : null;
    final trimmedLabel = label?.trim();
    final title =
        trimmedLabel != null && trimmedLabel.isNotEmpty
            ? trimmedLabel
            : preview?.title;

    final Widget body;
    if (videoId != null) {
      body = _YoutubeBody(videoId: videoId, title: title, isDark: isDark);
    } else if (preview?.imageUrl != null) {
      body = _ImagePreviewBody(
        imageUrl: preview!.imageUrl!,
        title: title,
        host: ConnectPostLinkUtils.hostOf(url) ?? preview.host,
        isDark: isDark,
      );
    } else {
      body = _PlainLinkBody(
        title: title ?? ConnectPostLinkUtils.hostOf(url) ?? url,
        subtitle: ConnectPostLinkUtils.shortUrl(url),
        isDark: isDark,
      );
    }

    final card = Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap ?? () => _open(url), child: body),
    );

    if (onRemove == null) return card;

    return Stack(
      children: [
        card,
        Positioned(top: 10, right: 10, child: _RemoveBadge(onTap: onRemove!)),
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _YoutubeBody extends StatelessWidget {
  const _YoutubeBody({
    required this.videoId,
    required this.title,
    required this.isDark,
  });

  final String videoId;
  final String? title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImageWidget(
                imageUrl: ConnectPostLinkUtils.youtubeThumbnailUrl(videoId),
                fit: BoxFit.cover,
                errorWidget: _PreviewFallback(isDark: isDark),
              ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppAssets.play,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'YouTube',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    AppAssets.youtube,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'YouTube',
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePreviewBody extends StatelessWidget {
  const _ImagePreviewBody({
    required this.imageUrl,
    required this.title,
    required this.host,
    required this.isDark,
  });

  final String imageUrl;
  final String? title;
  final String host;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImageWidget(
            key: ValueKey(imageUrl),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: _PreviewFallback(isDark: isDark),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: secondaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlainLinkBody extends StatelessWidget {
  const _PlainLinkBody({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            ),
            child: Icon(
              AppAssets.linkSimple,
              size: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != title) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppAssets.arrowSquareOut, size: 16, color: secondaryColor),
        ],
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.linkSimple,
        size: 28,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(AppAssets.x, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
