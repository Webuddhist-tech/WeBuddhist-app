import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_list_continuation.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

/// Message composer pinned to the bottom of the chat.
///
/// Own avatar on the left, then a pill field. The send button only exists once
/// something has been typed — an empty field is avatar plus field, full width.
class GroupChatComposer extends StatelessWidget {
  const GroupChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isSending,
    required this.onSubmit,
    this.enabled = true,
    this.avatarUrl,
    this.displayName,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isSending;
  final VoidCallback onSubmit;
  final bool enabled;

  /// Own avatar and name for the leading circle.
  final String? avatarUrl;
  final String? displayName;

  static const double _fieldHeight = 44;
  static const double _sendButtonSize = 44;
  static const double _avatarSize = 36;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        keyboardInset > 0 ? keyboardInset + 8 : bottomSafePadding + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _OwnAvatar(
            avatarUrl: avatarUrl,
            displayName: displayName,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MessageField(
              controller: controller,
              focusNode: focusNode,
              isDark: isDark,
              hintText: hintText,
              enabled: enabled,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              // Nothing typed, nothing to send: the button is absent rather
              // than disabled, and the field takes the full width.
              if (!hasText && !isSending) return const SizedBox.shrink();
              final canSend = enabled && hasText && !isSending;
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _SendButton(
                  canSend: canSend,
                  isSending: isSending,
                  isDark: isDark,
                  onPressed: canSend ? onSubmit : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OwnAvatar extends StatelessWidget {
  const _OwnAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isDark,
  });

  final String? avatarUrl;
  final String? displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: GroupChatComposer._avatarSize,
        height: GroupChatComposer._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: networkImageKey(url),
                  imageUrl: url,
                  width: GroupChatComposer._avatarSize,
                  height: GroupChatComposer._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _initials(),
                )
                : _initials(),
      ),
    );
  }

  Widget _initials() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Center(
        child: Text(
          chatSenderInitials(displayName),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey500 : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hintText,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    const radius = GroupChatComposer._fieldHeight / 2;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: 1,
      maxLines: 5,
      // Return adds a line rather than sending: with a send button always at
      // hand there is no other way to type a second line, and `send` made
      // multi-line messages impossible to compose.
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      // Return inside a list carries the marker on; Return on an empty item
      // ends the list.
      inputFormatters: const [ChatListContinuationFormatter()],
      style: TextStyle(
        fontSize: 15,
        height: 1.2,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 15,
          height: 1.2,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: isDark ? AppColors.grey600 : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.canSend,
    required this.isSending,
    required this.isDark,
    required this.onPressed,
  });

  final bool canSend;
  final bool isSending;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.surfaceWhite;

    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: GroupChatComposer._sendButtonSize,
          height: GroupChatComposer._sendButtonSize,
          child: Center(
            child:
                isSending
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                    : Icon(
                      AppAssets.paperPlaneRight,
                      size: 20,
                      color: foregroundColor,
                    ),
          ),
        ),
      ),
    );
  }
}
