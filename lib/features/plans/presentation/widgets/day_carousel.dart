import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/scroll_controller_ext.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:intl/intl.dart';

class DayCarousel extends StatefulWidget {
  final String language;
  final List<PlanDaysModel> days;
  final DateTime startDate;
  final int selectedDay;
  final Function(int) onDaySelected;
  final Map<int, bool>? dayCompletionStatus;
  final bool lockFutureDays;

  /// When [lockFutureDays] is true, days `1..previewUnlockDayCount` stay
  /// selectable even if their calendar date is in the future.
  final int previewUnlockDayCount;

  const DayCarousel({
    super.key,
    required this.language,
    required this.days,
    required this.startDate,
    required this.selectedDay,
    required this.onDaySelected,
    this.dayCompletionStatus,
    this.lockFutureDays = false,
    this.previewUnlockDayCount = 0,
  });

  @override
  State<DayCarousel> createState() => _DayCarouselState();
}

class _DayCarouselState extends State<DayCarousel> {
  late ScrollController _scrollController;

  /// A scroll requested before the list had been laid out, run by
  /// [_handleScrollMetrics] after the first layout. Null when none is waiting.
  bool? _pendingScrollAnimate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay(animate: false);
    });
  }

  @override
  void didUpdateWidget(DayCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _scrollToSelectedDay(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay({required bool animate}) {
    if (!mounted) return;
    final selectedIndex = widget.days.indexWhere(
      (d) => d.dayNumber == widget.selectedDay,
    );

    if (selectedIndex < 0) return;
    if (!_scrollController.hasLaidOutPosition) {
      // The list can be built without being laid out in the same frame. Its
      // scroll extent does not exist yet, so wait for the first layout.
      _pendingScrollAnimate = animate;
      return;
    }
    _pendingScrollAnimate = null;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 88.0;
    final targetOffset =
        (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    final animate = _pendingScrollAnimate;
    if (animate != null && notification.depth == 0) {
      _scrollToSelectedDay(animate: animate);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localStartDate = DateUtils.dateOnly(widget.startDate.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());

    return SizedBox(
      height: 80,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleScrollMetrics,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: widget.days.length,
          itemBuilder: (context, index) {
            final day = widget.days[index];
            final dayDate = localStartDate.add(
              Duration(days: day.dayNumber - 1),
            );
            final dayDateString = DateFormat('dd MMM').format(dayDate);
            final isSelected = widget.selectedDay == day.dayNumber;
            final isCompleted =
                widget.dayCompletionStatus?[day.dayNumber] ?? false;
            final isToday = dayDate.isAtSameMomentAs(today);
            final isFuture = dayDate.isAfter(today);
            final isDisabled =
                widget.lockFutureDays &&
                isFuture &&
                day.dayNumber > widget.previewUnlockDayCount;
            final isEffectivelySelected = isSelected && !isDisabled;
            final theme = Theme.of(context);
            final disabledColor = theme.disabledColor;

            return Opacity(
              opacity: isDisabled ? 0.45 : 1,
              child: GestureDetector(
                onTap:
                    isDisabled
                        ? null
                        : () {
                          HapticFeedback.selectionClick();
                          widget.onDaySelected(day.dayNumber);
                        },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        isDisabled
                            ? theme.cardColor.withValues(alpha: 0.6)
                            : theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isEffectivelySelected
                              ? const Color(0xFF1E3A8A)
                              : theme.cardColor,
                      width: 2,
                    ),
                    boxShadow:
                        isEffectivelySelected
                            ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF1E3A8A,
                                ).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isCompleted)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color:
                                isDisabled
                                    ? disabledColor
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.dayNumber}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDisabled ? disabledColor : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration:
                                isToday && !isDisabled
                                    ? BoxDecoration(
                                      color:
                                          theme.brightness == Brightness.dark
                                              ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                              : const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                    : null,
                            child: Text(
                              dayDateString,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDisabled
                                        ? disabledColor
                                        : isToday
                                        ? Colors.white
                                        : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
