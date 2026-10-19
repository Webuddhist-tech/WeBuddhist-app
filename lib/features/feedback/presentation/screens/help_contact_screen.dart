import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/feedback_failure_message.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/help_topic_l10n.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/feedback_image_tiles.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/help_topic_chip.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/message_sent_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// One form for reporting a problem, sharing an idea, suggesting content or
/// offering to help. It goes to `POST /feedback`; the backend stores it,
/// forwards it to Discord and posts it into the user's WeBuddhist Team chat,
/// where the reply comes.
class HelpContactScreen extends ConsumerStatefulWidget {
  const HelpContactScreen({super.key, this.initialTopic});

  /// Picked when the screen opens, e.g. *Idea or feedback* from the home
  /// prompt's Feedback button.
  final HelpTopic? initialTopic;

  static const int maxMessageLength = 1000;
  static const int maxImages = 3;

  /// The backend has no anonymous messages: it needs a signed-in account.
  static bool canSend(AuthState auth) => auth.isLoggedIn && !auth.isGuest;

  /// Entry point for Settings and the home prompt. Guests get the login
  /// drawer instead. After a send, the "Message sent" sheet opens over
  /// whatever opened this screen.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    HelpTopic? topic,
  }) async {
    if (!canSend(ref.read(authProvider))) {
      await LoginDrawer.show(context, ref, feature: 'feedback');
      return;
    }
    final result = await context.push<HelpContactResult>(
      AppRoutes.helpContact,
      extra: topic,
    );
    if (result == null || !context.mounted) return;
    await MessageSentSheet.show(context, result);
  }

  @override
  ConsumerState<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends ConsumerState<HelpContactScreen> {
  final _messageController = TextEditingController();
  final _images = <XFile>[];
  HelpTopic? _topic;
  bool _pickingImages = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _topic = widget.initialTopic;
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageChanged() => setState(() {});

  bool get _canSend => !_sending && _messageController.text.trim().isNotEmpty;

  int get _remainingImages => HelpContactScreen.maxImages - _images.length;

  void _toggleTopic(HelpTopic topic) {
    if (_sending) return;
    setState(() => _topic = _topic == topic ? null : topic);
  }

  Future<void> _pickImages() async {
    if (_pickingImages || _sending) return;
    final remaining = _remainingImages;
    if (remaining <= 0) {
      _showImageLimit();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _pickingImages = true);
    final picker = ImagePicker();
    var picked = <XFile>[];
    try {
      if (remaining == 1) {
        // The multi picker requires a limit of at least two.
        final single = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (single != null) picked = [single];
      } else {
        picked = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
          limit: remaining,
        );
      }
    } catch (_) {
      picked = [];
    }

    if (!mounted) return;
    setState(() {
      _images.addAll(picked.take(remaining));
      _pickingImages = false;
    });
    if (picked.length > remaining) _showImageLimit();
  }

  void _removeImage(int index) {
    if (_sending) return;
    setState(() {
      _images.removeAt(index);
      _error = null;
    });
  }

  void _showImageLimit() {
    setState(
      () =>
          _error = context.l10n.feedback_image_limit(
            HelpContactScreen.maxImages,
          ),
    );
  }

  Future<void> _send() async {
    if (!_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final l10n = context.l10n;
    final message = _messageController.text.trim();
    final topic = _topic;
    try {
      final receipt = await ref.read(sendFeedbackProvider)(
        message: message,
        imagePaths: [for (final image in _images) image.path],
        topic: topic,
      );
      if (!mounted) return;
      context.pop(
        HelpContactResult(
          message: message,
          topic: topic,
          roomId: receipt.roomId,
        ),
      );
    } on FeedbackException catch (e) {
      if (!mounted) return;
      setState(() => _error = feedbackFailureMessage(l10n, e.failure));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.feedback_error_failed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          context.l10n.help_contact_title,
          strutStyle: context.tibetanStrutStyle(18, compact: true),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _muted(context, isDark, context.l10n.help_contact_intro, 14),
                  const SizedBox(height: 20),
                  _label(context, isDark, context.l10n.help_contact_message),
                  const SizedBox(height: 8),
                  _buildMessageField(context, isDark),
                  const SizedBox(height: 24),
                  _buildImages(context, isDark),
                  const SizedBox(height: 24),
                  _label(context, isDark, context.l10n.help_contact_topic),
                  const SizedBox(height: 4),
                  _buildTopics(isDark),
                  const SizedBox(height: 20),
                  _muted(context, isDark, context.l10n.help_contact_footer, 12),
                ],
              ),
            ),
            _buildSubmit(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, bool isDark, String text) {
    return Text(
      text,
      strutStyle: context.tibetanStrutStyle(14, compact: true),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }

  Widget _muted(BuildContext context, bool isDark, String text, double size) {
    return Text(
      text,
      strutStyle: context.tibetanStrutStyle(size),
      style: TextStyle(
        fontSize: size,
        height: 1.4,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
      ),
    );
  }

  String _count(BuildContext context, String value) {
    return context.isTibetanLocale ? toTibetanDigits(value) : value;
  }

  Widget _buildMessageField(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.grey500 : AppColors.grey600;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final length = _messageController.text.characters.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _messageController,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                HelpContactScreen.maxMessageLength,
              ),
            ],
            style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
            decoration: InputDecoration(
              hintText: helpTopicHint(context.l10n, _topic),
              hintMaxLines: 3,
              hintStyle: TextStyle(fontSize: 15, height: 1.4, color: hintColor),
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
            _count(context, '$length / ${HelpContactScreen.maxMessageLength}'),
            style: TextStyle(fontSize: 12, color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context, bool isDark) {
    const tileSize = 72.0;
    final muted = isDark ? AppColors.grey500 : AppColors.grey600;
    final dashColor = isDark ? AppColors.grey600 : AppColors.grey400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _label(context, isDark, context.l10n.help_contact_photos),
            ),
            Text(
              _count(
                context,
                '${_images.length} / ${HelpContactScreen.maxImages}',
              ),
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (index, image) in _images.indexed)
              FeedbackImageThumb(
                file: File(image.path),
                size: tileSize,
                onRemove: _sending ? null : () => _removeImage(index),
              ),
            if (_remainingImages > 0)
              FeedbackAddImageTile(
                size: tileSize,
                color: dashColor,
                onTap: _sending ? null : _pickImages,
                loading: _pickingImages,
                tooltip: context.l10n.feedback_add_image,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopics(bool isDark) {
    return Wrap(
      spacing: 8,
      children: [
        for (final topic in HelpTopic.values)
          HelpTopicChip(
            label: helpTopicLabel(context.l10n, topic),
            isSelected: _topic == topic,
            isDark: isDark,
            onTap: () => _toggleTopic(topic),
          ),
      ],
    );
  }

  Widget _buildSubmit(BuildContext context, bool isDark) {
    final background = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foreground = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    final error = _error;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(13),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: _canSend ? _send : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              backgroundColor: background,
              foregroundColor: foreground,
              disabledBackgroundColor:
                  isDark ? AppColors.grey800 : AppColors.grey300,
              disabledForegroundColor:
                  isDark ? AppColors.grey500 : AppColors.grey600,
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
                    : Text(
                      context.l10n.feedback_send,
                      strutStyle: context.tibetanStrutStyle(15, compact: true),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
