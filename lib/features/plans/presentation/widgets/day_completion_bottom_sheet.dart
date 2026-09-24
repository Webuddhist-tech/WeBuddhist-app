import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_day_share.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DayCompletionBottomSheet extends ConsumerStatefulWidget {
  final int dayNumber;
  final int totalDays;
  final int completedDays;
  final String? fallbackImageUrl;
  final String? thumbnailUrl;
  final String? shareableImageUrl;
  final String planTitle;
  final String planId;
  final String planLanguage;

  const DayCompletionBottomSheet({
    super.key,
    required this.dayNumber,
    required this.totalDays,
    required this.completedDays,
    required this.fallbackImageUrl,
    this.thumbnailUrl,
    this.shareableImageUrl,
    required this.planTitle,
    required this.planId,
    required this.planLanguage,
  });

  @override
  ConsumerState<DayCompletionBottomSheet> createState() =>
      _DayCompletionBottomSheetState();
}

class _DayCompletionBottomSheetState
    extends ConsumerState<DayCompletionBottomSheet> {
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  bool get _hasShareableImage =>
      widget.shareableImageUrl?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.totalDays > 0 ? widget.completedDays / widget.totalDays : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 20),
          _buildCheckmarkIcon(context),
          const SizedBox(height: 15),
          _buildDayText(context),
          const SizedBox(height: 20),
          _buildPlanImageCard(context),
          const SizedBox(height: 30),
          _hasShareableImage
              ? _buildShareButton(context)
              : _buildProgressBar(context, progress),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCheckmarkIcon(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 30,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDayText(BuildContext context) {
    return Text(
      context.l10n.plan_day_of(widget.dayNumber, widget.totalDays),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPlanImageCard(BuildContext context) {
    final imageWidth = MediaQuery.of(context).size.width - 80;
    final displayImageUrl =
        widget.thumbnailUrl?.trim().isNotEmpty == true
            ? widget.thumbnailUrl!.trim()
            : widget.fallbackImageUrl?.trim();

    if (displayImageUrl == null || displayImageUrl.isEmpty) {
      return _buildPlaceholderImage(context, imageWidth);
    }

    return CachedNetworkImageWidget(
      imageUrl: displayImageUrl,
      width: imageWidth,
      height: 180,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context, double width) {
    return Container(
      width: width,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width - 48;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: buttonWidth,
      height: 56,
      child: FilledButton.icon(
        key: _shareButtonKey,
        onPressed: _isSharing ? null : _shareImage,
        icon:
            _isSharing
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.surface.withValues(alpha: 0.85),
                  ),
                )
                : const Icon(AppAssets.readerShare, size: 22),
        label: Text(
          context.l10n.share,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.onSurface,
          foregroundColor: colorScheme.surface,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
          disabledForegroundColor: colorScheme.surface.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    final url = widget.shareableImageUrl?.trim();
    if (url == null || url.isEmpty || _isSharing) return;

    setState(() => _isSharing = true);

    try {
      await sharePlanDayImage(
        context: context,
        shareableImageUrl: url,
        dayNumber: widget.dayNumber,
        planId: widget.planId,
        planLanguage: widget.planLanguage,
        shareButtonKey: _shareButtonKey,
      );
      if (mounted) {
        ref
            .read(planAnalyticsProvider)
            .planDayShared(
              planId: widget.planId,
              dayNumber: widget.dayNumber,
            );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final barWidth = MediaQuery.of(context).size.width - 80;

    return SizedBox(
      width: barWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
