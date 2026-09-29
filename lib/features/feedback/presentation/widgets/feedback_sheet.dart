import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/feedback/data/discord_feedback_client.dart';
import 'package:flutter_pecha/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Draggable bottom sheet where the user writes feedback and attaches up to
/// [maxImages] screenshots. Pops with `true` once the feedback was sent.
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({super.key});

  static const int maxMessageLength = 400;
  static const int maxImages = 3;

  static const double _initialSize = 0.6;
  static const double _maxSize = 0.95;

  /// Floor for the sheet, in pixels. The header and the Send footer do not
  /// scroll, so a fraction of the space left above an open keyboard can be
  /// too short to show the composer on a compact phone.
  static const double _minSheetHeight = 380;

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const FeedbackSheet(),
    );
  }

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  final _messageController = TextEditingController();
  final _images = <XFile>[];
  bool _pickingImages = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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

  int get _remainingImages => FeedbackSheet.maxImages - _images.length;

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
    _showError(context.l10n.feedback_image_limit(FeedbackSheet.maxImages));
  }

  /// Shown inside the sheet: a snackbar would sit under the modal barrier.
  void _showError(String message) => setState(() => _error = message);

  Future<void> _send() async {
    if (!_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(sendFeedbackProvider)(
        message: _messageController.text.trim(),
        imagePaths: [for (final image in _images) image.path],
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.feedback_sent),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FeedbackException catch (e) {
      if (!mounted) return;
      _showError(switch (e.failure) {
        FeedbackFailure.notConfigured => l10n.feedback_error_unavailable,
        FeedbackFailure.offline => l10n.feedback_error_offline,
        FeedbackFailure.rateLimited => l10n.feedback_error_rate_limited,
        FeedbackFailure.tooLarge => l10n.feedback_error_too_large,
        FeedbackFailure.failed => l10n.feedback_error_failed,
      });
    } catch (_) {
      if (mounted) _showError(l10n.feedback_error_failed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fractions are of the space left above the keyboard, so they have
          // to grow as that space shrinks to keep the sheet usable.
          final floor = (FeedbackSheet._minSheetHeight / constraints.maxHeight)
              .clamp(0.0, 1.0);
          final initial = math.max(FeedbackSheet._initialSize, floor);
          final max = math.max(FeedbackSheet._maxSize, initial);
          return _buildSheet(context, isDark, initial: initial, max: max);
        },
      ),
    );
  }

  Widget _buildSheet(
    BuildContext context,
    bool isDark, {
    required double initial,
    required double max,
  }) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initial,
      minChildSize: initial,
      maxChildSize: max,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      _buildMessageField(context, isDark),
                      const SizedBox(height: 16),
                      _buildImages(context, isDark),
                    ],
                  ),
                ),
                _buildSubmit(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.feedback_title,
              strutStyle: context.tibetanStrutStyle(18, compact: true),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField(BuildContext context, bool isDark) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
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
            minLines: 5,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(FeedbackSheet.maxMessageLength),
            ],
            style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
            decoration: InputDecoration(
              hintText: context.l10n.feedback_hint,
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
            '$length / ${FeedbackSheet.maxMessageLength}',
            style: TextStyle(fontSize: 12, color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context, bool isDark) {
    const tileSize = 72.0;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.grey500 : AppColors.grey600;
    final dashColor = isDark ? AppColors.grey600 : AppColors.grey400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.l10n.feedback_images,
              strutStyle: context.tibetanStrutStyle(15, compact: true),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const Spacer(),
            Text(
              '${_images.length} / ${FeedbackSheet.maxImages}',
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
              _ImageThumb(
                file: File(image.path),
                size: tileSize,
                onRemove: _sending ? null : () => _removeImage(index),
              ),
            if (_remainingImages > 0)
              _AddImageTile(
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

  Widget _buildSubmit(BuildContext context, bool isDark) {
    final background = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foreground = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    final disabledBackground = isDark ? AppColors.grey800 : AppColors.grey300;
    final disabledForeground = isDark ? AppColors.grey500 : AppColors.grey600;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
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
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: labelColor,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    context.l10n.cancel,
                    strutStyle: context.tibetanStrutStyle(15, compact: true),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubmitButton(
                  context,
                  background: background,
                  foreground: foreground,
                  disabledBackground: disabledBackground,
                  disabledForeground: disabledForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context, {
    required Color background,
    required Color foreground,
    required Color disabledBackground,
    required Color disabledForeground,
  }) {
    return ElevatedButton(
      onPressed: _canSend ? _send : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: disabledBackground,
        disabledForegroundColor: disabledForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.size,
    required this.color,
    required this.onTap,
    required this.loading,
    required this.tooltip,
  });

  final double size;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _DashedRoundedBorderPainter(color: color, radius: 12),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child:
                    loading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                        : Icon(AppAssets.plus, size: 28, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _strokeWidth = 1.5;
  static const _dashWidth = 5.0;
  static const _dashSpace = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );

    final dashed = Path();
    for (final metric in (Path()..addRRect(rRect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + _dashSpace;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.file,
    required this.size,
    required this.onRemove,
  });

  final File file;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(AppAssets.x, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
