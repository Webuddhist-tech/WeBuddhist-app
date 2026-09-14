import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_link_card.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A link the composer will send with the post.
class GroupPostLinkDraft {
  final String url;
  final String type;
  final String? title;

  const GroupPostLinkDraft({required this.url, required this.type, this.title});
}

enum _LinkStatus { idle, invalid, loading, ready, failed }

class GroupPostAddLinkSheet extends ConsumerStatefulWidget {
  const GroupPostAddLinkSheet({super.key});

  static Future<GroupPostLinkDraft?> show(BuildContext context) {
    return showModalBottomSheet<GroupPostLinkDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const GroupPostAddLinkSheet(),
    );
  }

  @override
  ConsumerState<GroupPostAddLinkSheet> createState() =>
      _GroupPostAddLinkSheetState();
}

class _GroupPostAddLinkSheetState extends ConsumerState<GroupPostAddLinkSheet> {
  /// Long enough that a pasted URL is resolved once, not at every keystroke.
  static const Duration _settle = Duration(milliseconds: 600);

  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  String? _resolvedUrl;
  bool _isInvalid = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _resolvedUrl = null;
        _isInvalid = false;
      });
      return;
    }
    _timer = Timer(_settle, _resolve);
  }

  void _resolve() {
    if (!mounted) return;
    _timer?.cancel();
    final normalized = ConnectPostLinkUtils.normalizeUserUrl(_controller.text);
    setState(() {
      _resolvedUrl = normalized;
      _isInvalid = normalized == null && _controller.text.trim().isNotEmpty;
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _resolvedUrl = null;
      _isInvalid = false;
    });
  }

  void _attach(String url, String? title) {
    Navigator.of(context).pop(
      GroupPostLinkDraft(
        url: url,
        type: ConnectPostLinkUtils.typeFor(url),
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    final url = _resolvedUrl;
    final isYoutube = url != null && ConnectPostLinkUtils.isYoutube(url);
    final previewAsync =
        url != null &&
                !isYoutube &&
                ChatLinkPreviewService.isPreviewableUrl(url)
            ? ref.watch(chatLinkPreviewProvider(url))
            : null;

    final _LinkStatus status;
    if (url == null) {
      status = _isInvalid ? _LinkStatus.invalid : _LinkStatus.idle;
    } else if (isYoutube) {
      status = _LinkStatus.ready;
    } else if (previewAsync == null) {
      status = _LinkStatus.failed;
    } else if (previewAsync.isLoading) {
      status = _LinkStatus.loading;
    } else if (previewAsync.valueOrNull != null) {
      status = _LinkStatus.ready;
    } else {
      status = _LinkStatus.failed;
    }
    final previewTitle = previewAsync?.valueOrNull?.title;
    final canAttach =
        status == _LinkStatus.ready || status == _LinkStatus.failed;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.group_post_add_link_title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppAssets.x),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.group_post_add_link_hint,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _resolve(),
                  decoration: InputDecoration(
                    hintText: l10n.group_post_link_field_hint,
                    filled: true,
                    fillColor:
                        isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceWhite,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                if (status != _LinkStatus.idle) const SizedBox(height: 16),
                switch (status) {
                  _LinkStatus.idle => const SizedBox.shrink(),
                  _LinkStatus.invalid => Text(
                    l10n.group_post_invalid_link,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                  _LinkStatus.loading => Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ConnectPostLinkUtils.shortUrl(url!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: secondaryColor),
                        ),
                      ),
                    ],
                  ),
                  _LinkStatus.ready => ConnectPostLinkCard(
                    url: url!,
                    onRemove: _clear,
                    onTap: () {},
                  ),
                  _LinkStatus.failed => _PreviewFailed(
                    url: url!,
                    isDark: isDark,
                    borderColor: borderColor,
                    secondaryColor: secondaryColor,
                  ),
                },
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        canAttach ? () => _attach(url!, previewTitle) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                      disabledBackgroundColor:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      disabledForegroundColor:
                          isDark ? AppColors.grey500 : AppColors.grey600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      status == _LinkStatus.failed
                          ? l10n.group_post_attach_as_link
                          : l10n.group_post_attach,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewFailed extends StatelessWidget {
  const _PreviewFailed({
    required this.url,
    required this.isDark,
    required this.borderColor,
    required this.secondaryColor,
  });

  final String url;
  final bool isDark;
  final Color borderColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.group_post_preview_failed_title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.group_post_preview_failed_message,
          style: TextStyle(fontSize: 13, color: secondaryColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: secondaryColor, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ConnectPostLinkUtils.shortUrl(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
