import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

/// Open Graph card under a message body.
///
/// Renders nothing while the fetch is in flight and nothing when it fails, so
/// the bubble never reflows twice for the same message.
class GroupChatLinkPreviewCard extends ConsumerWidget {
  const GroupChatLinkPreviewCard({
    super.key,
    required this.url,
    required this.onOpen,
  });

  final String url;
  final ValueChanged<String> onOpen;

  static const double _thumbnailSize = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(chatLinkPreviewProvider(url)).valueOrNull;
    if (preview == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final imageUrl = preview.imageUrl;
    final title = preview.title;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => onOpen(url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.scaffoldBackgroundDark : AppColors.goldLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImageWidget(
                    key: networkImageKey(imageUrl),
                    imageUrl: imageUrl,
                    width: _thumbnailSize,
                    height: _thumbnailSize,
                    fit: BoxFit.cover,
                    errorWidget: const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    if (preview.host.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: secondaryColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
