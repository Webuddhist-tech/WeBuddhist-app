import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

/// The unfurl of a link in the draft, shown above the composer once one is
/// typed or pasted — so the sender sees what the card will look like before
/// the message goes out.
class GroupChatComposerLinkPreview extends ConsumerStatefulWidget {
  const GroupChatComposerLinkPreview({
    super.key,
    required this.url,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onDismiss;

  @override
  ConsumerState<GroupChatComposerLinkPreview> createState() =>
      _GroupChatComposerLinkPreviewState();
}

class _GroupChatComposerLinkPreviewState
    extends ConsumerState<GroupChatComposerLinkPreview> {
  /// Long enough that a URL being typed a character at a time is fetched once,
  /// when it settles, rather than at every prefix.
  static const Duration _settle = Duration(milliseconds: 600);

  String? _resolved;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleResolve();
  }

  @override
  void didUpdateWidget(GroupChatComposerLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _scheduleResolve();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleResolve() {
    _timer?.cancel();
    _timer = Timer(_settle, () {
      if (mounted) setState(() => _resolved = widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolved;
    if (url == null) return const SizedBox.shrink();

    final preview = ref.watch(chatLinkPreviewProvider(url)).valueOrNull;
    // Nothing while it is in flight, and nothing when the page has no card to
    // show — the bar should not flicker in and out around a bare link.
    if (preview == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = preview.imageUrl;
    final title = preview.title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceWhite,
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
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                            ),
                          ),
                        if (preview.host.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            preview.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.x, size: 18),
            color: isDark ? AppColors.grey500 : AppColors.grey600,
            onPressed: widget.onDismiss,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }
}
