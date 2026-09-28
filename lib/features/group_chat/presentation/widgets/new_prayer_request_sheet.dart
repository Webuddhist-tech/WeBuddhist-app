import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_l10n.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compose a prayer request: body plus one intention. Pops with the created
/// message, or null when dismissed.
class NewPrayerRequestSheet extends ConsumerStatefulWidget {
  const NewPrayerRequestSheet({super.key, required this.eventId});

  final String eventId;

  static const int maxBodyLength = 280;
  static const int _choicesPerRow = 5;
  static const double _minChoiceWidth = 64;

  static Future<ChatMessageDTO?> show(
    BuildContext context, {
    required String eventId,
  }) {
    return showModalBottomSheet<ChatMessageDTO>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => NewPrayerRequestSheet(eventId: eventId),
    );
  }

  @override
  ConsumerState<NewPrayerRequestSheet> createState() =>
      _NewPrayerRequestSheetState();
}

class _NewPrayerRequestSheetState extends ConsumerState<NewPrayerRequestSheet> {
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  ChatPrayerIntentionDTO? _intention;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bodyFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _onBodyChanged() => setState(() {});

  bool get _canSend =>
      !_sending &&
      _intention != null &&
      _bodyController.text.trim().isNotEmpty;

  Future<void> _send() async {
    final intention = _intention;
    final body = _bodyController.text.trim();
    if (intention == null || body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(prayerRequestsProvider(widget.eventId).notifier)
          .send(body, intention: intention.slug);
      if (!mounted) return;
      result.fold(
        (failure) => presentChatSendError(context, failure),
        (message) => Navigator.of(context).pop(message),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    // Sized to content; capped so the keyboard can never push it past the
    // status bar, and the middle scrolls when that cap bites.
    final maxHeight = size.height - topInset - keyboardInset - 24;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, isDark),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBodyField(context, isDark),
                        const SizedBox(height: 20),
                        _buildIntentionSection(context, isDark),
                      ],
                    ),
                  ),
                ),
                _buildSubmit(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(AppAssets.arrowLeft),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    context.l10n.event_prayer_new_request,
                    strutStyle: context.tibetanStrutStyle(17, compact: true),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyField(BuildContext context, bool isDark) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final length = _bodyController.text.characters.length;

    return Container(
      decoration: BoxDecoration(
        color: prayerIntentionCardColor(_intention, isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(
          prayerIntentionCardBorder(_intention, isDark),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                NewPrayerRequestSheet.maxBodyLength,
              ),
            ],
            style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
            decoration: InputDecoration(
              hintText: context.l10n.event_prayer_hint,
              hintStyle: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: hintColor,
              ),
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          Text(
            '$length / ${NewPrayerRequestSheet.maxBodyLength}',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionSection(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final intentions = ref.watch(prayerIntentionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_prayer_choose_intention,
          strutStyle: context.tibetanStrutStyle(14, compact: true),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        intentions.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          error:
              (_, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.event_prayer_intentions_failed,
                      strutStyle: context.tibetanStrutStyle(13),
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(prayerIntentionsProvider),
                    child: Text(context.l10n.group_chat_retry),
                  ),
                ],
              ),
          data: (items) => _buildIntentionPicker(context, isDark, items),
        ),
      ],
    );
  }

  Widget _buildIntentionPicker(
    BuildContext context,
    bool isDark,
    List<ChatPrayerIntentionDTO> items,
  ) {
    final selected = _intention;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Five share the row as in the design; a larger catalog wraps
        // rather than squeezing every circle thinner.
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = math.min(
              items.length,
              NewPrayerRequestSheet._choicesPerRow,
            );
            final width = math.max(
              NewPrayerRequestSheet._minChoiceWidth,
              constraints.maxWidth / math.max(perRow, 1),
            );
            return Wrap(
              runSpacing: 8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _IntentionChoice(
                      intention: item,
                      selected: item.slug == selected?.slug,
                      isDark: isDark,
                      onTap:
                          _sending
                              ? null
                              : () => setState(() => _intention = item),
                    ),
                  ),
              ],
            );
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          _IntentionDescription(intention: selected, isDark: isDark),
        ],
      ],
    );
  }

  Widget _buildSubmit(BuildContext context, bool isDark) {
    final background = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foreground = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ElevatedButton(
        onPressed: _canSend ? _send : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          disabledForegroundColor: foreground.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child:
            _sending
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppAssets.handsPraying, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.event_prayer_request_button,
                      strutStyle: context.tibetanStrutStyle(15, compact: true),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _IntentionChoice extends StatelessWidget {
  const _IntentionChoice({
    required this.intention,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final ChatPrayerIntentionDTO intention;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final color = prayerIntentionColor(intention, isDark);
    final ring = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: intention.localizedLabel(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _size + 8,
                height: _size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ring : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                intention.localizedLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(11, compact: true),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentionDescription extends StatelessWidget {
  const _IntentionDescription({required this.intention, required this.isDark});

  final ChatPrayerIntentionDTO intention;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = prayerIntentionColor(intention, isDark);
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: prayerIntentionBorderColor(intention, isDark),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intention.localizedLabel(context),
            strutStyle: context.tibetanStrutStyle(13, compact: true),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: prayerAccentTextColor(accent, isDark),
            ),
          ),
          if (intention.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              intention.localizedDescription(context),
              strutStyle: context.tibetanStrutStyle(12),
              style: TextStyle(fontSize: 12, height: 1.4, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}
