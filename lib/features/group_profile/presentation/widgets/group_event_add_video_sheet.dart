import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pops with a YouTube video for the About page.
class GroupEventAddVideoSheet extends ConsumerStatefulWidget {
  const GroupEventAddVideoSheet({super.key});

  static Future<GroupEventVideoDraft?> show(BuildContext context) {
    return GroupEventSheet.show<GroupEventVideoDraft>(
      context,
      builder: (_) => const GroupEventAddVideoSheet(),
    );
  }

  @override
  ConsumerState<GroupEventAddVideoSheet> createState() =>
      _GroupEventAddVideoSheetState();
}

class _GroupEventAddVideoSheetState
    extends ConsumerState<GroupEventAddVideoSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    final raw = _controller.text.trim();
    final normalized = ConnectPostLinkUtils.normalizeUserUrl(raw);
    final url =
        normalized != null && ConnectPostLinkUtils.isYoutube(normalized)
            ? normalized
            : null;
    final isInvalid = raw.isNotEmpty && url == null;
    final previewAsync =
        url == null ? null : ref.watch(chatLinkPreviewProvider(url));
    final isLoading = previewAsync?.isLoading ?? false;
    final preview = previewAsync?.valueOrNull;
    final canAdd = url != null && !isLoading;

    return GroupEventSheet(
      title: l10n.group_event_add_video,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.group_event_add_video,
        onPressed:
            !canAdd
                ? null
                : () => Navigator.of(context).pop(
                  GroupEventVideoDraft(
                    url: url,
                    title: preview?.title,
                    thumbnailUrl: preview?.imageUrl,
                  ),
                ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.group_event_video_link,
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l10n.group_event_video_link_hint,
                      hintStyle: TextStyle(fontSize: 15, color: secondaryColor),
                      filled: true,
                      fillColor:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceWhite,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isInvalid ? AppColors.danger : borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isInvalid
                                  ? AppColors.danger
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _paste,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    l10n.group_event_paste,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (isInvalid) ...[
              const SizedBox(height: 6),
              Text(
                l10n.group_event_video_invalid,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ] else if (isLoading) ...[
              const SizedBox(height: 6),
              Text(
                l10n.group_event_video_loading,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ] else if (url != null) ...[
              const SizedBox(height: 12),
              _VideoPreview(
                title: preview?.title ?? l10n.group_event_video_untitled,
                thumbnailUrl: preview?.imageUrl,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.title,
    required this.thumbnailUrl,
    required this.isDark,
  });

  final String title;
  final String? thumbnailUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 96,
              height: 64,
              child:
                  thumbnailUrl == null
                      ? ColoredBox(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.grey100,
                      )
                      : CachedNetworkImageWidget(
                        imageUrl: thumbnailUrl,
                        width: 96,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.group_event_video_source,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
