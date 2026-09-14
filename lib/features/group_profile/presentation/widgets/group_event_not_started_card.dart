import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// 16:9 placeholder shown in place of the stream before the puja starts.
class GroupEventNotStartedCard extends StatefulWidget {
  final DateTime? startsAt;

  /// Fires once when the countdown reaches zero.
  final VoidCallback? onStarted;

  const GroupEventNotStartedCard({super.key, this.startsAt, this.onStarted});

  @override
  State<GroupEventNotStartedCard> createState() =>
      _GroupEventNotStartedCardState();
}

class _GroupEventNotStartedCardState extends State<GroupEventNotStartedCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(GroupEventNotStartedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startsAt != oldWidget.startsAt) _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration? get _remaining {
    final startsAt = widget.startsAt;
    if (startsAt == null) return null;
    final remaining = startsAt.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    // Round up so the clock reads 00 : 00 : 01 until the start, never 00.
    return Duration(seconds: (remaining.inMilliseconds / 1000).ceil());
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    final remaining = _remaining;
    if (remaining == null || remaining == Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      widget.onStarted?.call();
    }
  }

  String _formatCountdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)} : ${two(d.inMinutes % 60)} : ${two(d.inSeconds % 60)}';
  }

  String? _formatStart(BuildContext context) {
    final start = widget.startsAt?.toLocal();
    if (start == null) return null;
    final locale = intlFormatLocaleOf(context);
    final date = DateFormat('EEE d MMM', locale).format(start);
    final time = DateFormat.jm(locale).format(start).toLowerCase();
    return '$date · $time ${start.timeZoneName}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = _remaining;
    final counting = remaining != null && remaining > Duration.zero;
    final dateText = _formatStart(context);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: isDark ? AppColors.surfaceDark : AppColors.greyLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.chipBackgroundDark
                          : AppColors.grey800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      counting
                          ? context.l10n.event_puja_starts_in
                          : context.l10n.event_puja_not_started,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (counting) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatCountdown(remaining),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (dateText != null) ...[
                const SizedBox(height: 12),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 13,
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
      ),
    );
  }
}
