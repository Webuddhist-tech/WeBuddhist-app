import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

/// One event the home pill can show or list.
class TodayEventBadgeItem {
  const TodayEventBadgeItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isLive = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isLive;
}

/// Small pill shown above the verse-of-the-day card when events are happening
/// today. The first event is shown with its group avatar and a pulsing red dot
/// when live. With several events, the pill carries a count and a caret, and
/// tapping drops down the full list.
class TodayEventBadge extends StatefulWidget {
  const TodayEventBadge({super.key, required this.events, this.onSelect});

  final List<TodayEventBadgeItem> events;
  final ValueChanged<String>? onSelect;

  static const double _avatarSize = 22;
  static const double _menuAvatarSize = 26;
  static const double _menuMaxWidth = 360;

  static String formatEventName(String name) {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  State<TodayEventBadge> createState() => _TodayEventBadgeState();
}

class _TodayEventBadgeState extends State<TodayEventBadge> {
  final MenuController _menu = MenuController();

  bool get _hasMany => widget.events.length > 1;

  VoidCallback? _tapFor(TodayEventBadgeItem item) {
    final onSelect = widget.onSelect;
    if (onSelect == null || item.id.isEmpty) return null;
    return () => onSelect(item.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();
    final first = widget.events.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasMany) {
      return _Pill(
        events: widget.events,
        isDark: isDark,
        onTap: _tapFor(first),
      );
    }

    final menuWidth = (MediaQuery.sizeOf(context).width - 40).clamp(
      0.0,
      TodayEventBadge._menuMaxWidth,
    );
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 6),
      onOpen: () => setState(() {}),
      onClose: () => setState(() {}),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark ? AppColors.cardDark : Colors.white,
        ),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        for (var i = 0; i < widget.events.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
            ),
          _MenuRow(
            item: widget.events[i],
            width: menuWidth,
            isDark: isDark,
            onTap: _tapFor(widget.events[i]),
          ),
        ],
      ],
      builder: (context, controller, _) {
        return _Pill(
          events: widget.events,
          isDark: isDark,
          count: widget.events.length,
          isOpen: controller.isOpen,
          onTap:
              () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.events,
    required this.isDark,
    this.count,
    this.isOpen = false,
    this.onTap,
  });

  final List<TodayEventBadgeItem> events;
  final bool isDark;
  final int? count;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = events.first;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(20);
    final secondary = isDark ? AppColors.grey500 : AppColors.grey600;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AvatarStack(events: events, isDark: isDark),
                const SizedBox(width: 8),
                if (item.isLive) ...[
                  const _LiveDot(),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    TodayEventBadge.formatEventName(item.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      AppAssets.caretDown,
                      size: 14,
                      color: secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.width,
    required this.isDark,
    this.onTap,
  });

  final TodayEventBadgeItem item;
  final double width;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MenuItemButton(
      onPressed: onTap,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            _Avatar(
              url: item.avatarUrl,
              size: TodayEventBadge._menuAvatarSize,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                TodayEventBadge.formatEventName(item.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping avatars of every event, first on top.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.events, required this.isDark});

  final List<TodayEventBadgeItem> events;
  final bool isDark;

  static const double _overlap = 15;
  static const int _maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final shown = events.take(_maxShown).toList();
    final size = TodayEventBadge._avatarSize;
    final step = size - _overlap;
    return SizedBox(
      width: step * (shown.length - 1) + size,
      height: size,
      child: Stack(
        children: [
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: step * i,
              child: _Avatar(
                url: shown[i].avatarUrl,
                size: size,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size, required this.isDark});

  final String? url;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    final fallback = ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey400,
      child: Icon(
        AppAssets.usersThree,
        size: size * 0.6,
        color: AppColors.grey600,
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget: fallback,
                )
                : fallback,
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const _StaticLiveDot();
    }
    return const _PulsingLiveDot();
  }
}

class _StaticLiveDot extends StatelessWidget {
  const _StaticLiveDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: _LiveDotMetrics.size * 2,
      child: Center(child: _LiveDotCore()),
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _LiveDotMetrics.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _LiveDotMetrics.size * (1 + t),
                height: _LiveDotMetrics.size * (1 + t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LiveDotMetrics.color.withValues(alpha: 0.4 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: const _LiveDotCore(),
      ),
    );
  }
}

class _LiveDotMetrics {
  const _LiveDotMetrics._();

  static const size = 8.0;
  static const color = Color(0xFFE53935);
}

class _LiveDotCore extends StatelessWidget {
  const _LiveDotCore();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _LiveDotMetrics.size,
      height: _LiveDotMetrics.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _LiveDotMetrics.color,
      ),
    );
  }
}
