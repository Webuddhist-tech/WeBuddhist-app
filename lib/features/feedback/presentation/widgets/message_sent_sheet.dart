import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/help_topic_l10n.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/help_topic_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What Help & contact sent, for the "Message sent" sheet.
class HelpContactResult {
  const HelpContactResult({required this.message, this.topic, this.roomId});

  final String message;
  final HelpTopic? topic;

  /// The WeBuddhist Team chat the backend posted the message into, when it
  /// says which.
  final String? roomId;
}

/// Where "Open chat" goes: straight into the WeBuddhist Team chat when the
/// backend said which room it posted to, otherwise the Chats list.
String messageSentChatLocation(HelpContactResult result) {
  final roomId = result.roomId?.trim() ?? '';
  return roomId.isEmpty ? AppRoutes.chats : AppRoutes.directChatPath(roomId);
}

/// Confirms a Help & contact message and says where the reply will come.
class MessageSentSheet extends ConsumerWidget {
  const MessageSentSheet({super.key, required this.result});

  final HelpContactResult result;

  static Future<void> show(BuildContext context, HelpContactResult result) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      // Masked like the Help & contact route: it quotes the message back.
      builder: (_) => ClarityMask(child: MessageSentSheet(result: result)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final firstName = ref.watch(userProvider).user?.visibleName ?? '';
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final topic = result.topic;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(AppAssets.x, color: ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.successDark : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppAssets.check,
                    size: 28,
                    color:
                        isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.help_contact_sent_title,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(20, compact: true),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                firstName.isEmpty
                    ? l10n.help_contact_sent_body
                    : l10n.help_contact_sent_body_named(firstName),
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(14),
                style: TextStyle(fontSize: 14, height: 1.4, color: muted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.cardBorderDark : AppColors.grey300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.help_contact_your_request,
                      strutStyle: context.tibetanStrutStyle(11, compact: true),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: muted,
                      ),
                    ),
                    if (topic != null) ...[
                      const SizedBox(height: 8),
                      HelpTopicChip(
                        label: helpTopicLabel(l10n, topic),
                        isSelected: true,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '“${result.message}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: context.tibetanStrutStyle(13),
                      style: TextStyle(fontSize: 13, height: 1.4, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor:
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                  foregroundColor:
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _buttonLabel(context, l10n.done),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(messageSentChatLocation(result));
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: ink,
                  side: BorderSide(color: ink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _buttonLabel(context, l10n.help_contact_open_chat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttonLabel(BuildContext context, String text) {
    return Text(
      text,
      strutStyle: context.tibetanStrutStyle(15, compact: true),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
