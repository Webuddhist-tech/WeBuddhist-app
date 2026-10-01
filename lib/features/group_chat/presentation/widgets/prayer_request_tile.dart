import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_action_menu.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/floating_prayer_text.dart';

/// One prayer request as a card tinted by its intention: who asked, what
/// for, how many are praying, and a pray button for everyone but the requester.
class PrayerRequestTile extends StatelessWidget {
  const PrayerRequestTile({
    super.key,
    required this.request,
    required this.displayName,
    this.avatarUrl,
    this.isOwn = false,
    this.onPray,
    this.onShowSupporters,
    this.onEdit,
    this.onDelete,
  });

  final ChatMessageDTO request;
  final String displayName;
  final String? avatarUrl;

  /// The viewer's own request: named "You", no pray button, roster opens.
  final bool isOwn;

  /// Every tap adds a prayer; there is no taking one back.
  final VoidCallback? onPray;

  /// Only the requester may see who is praying; ignored on others' cards.
  final VoidCallback? onShowSupporters;

  /// Either one shows the overflow menu with the matching entry.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intention = request.intention;
    final cardColor = prayerIntentionCardColor(intention, isDark);
    final accent = prayerIntentionColor(intention, isDark);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final name = isOwn ? context.l10n.event_prayer_you : displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(
            prayerIntentionCardBorder(intention, isDark),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PrayerAvatar(
                  avatarUrl: avatarUrl,
                  label: isOwn ? name : displayName,
                  size: 28,
                  accent: accent,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: context.tibetanStrutStyle(13, compact: true),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  ConnectActionMenu(
                    icon: AppAssets.dotsThree,
                    iconColor:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _CollapsibleBody(
              text: request.body,
              textColor: textColor,
              linkColor: prayerAccentTextColor(accent, isDark),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            ),
            const SizedBox(height: 10),
            _buildFooter(context, isDark, accent, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    bool isDark,
    Color accent,
    Color cardColor,
  ) {
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final count = request.prayerCount;

    final Widget supporters;
    if (count > 0) {
      supporters = _SupportersSummary(
        count: count,
        recent: request.recentPrayers,
        accent: accent,
        cardColor: cardColor,
        isDark: isDark,
        onTap: isOwn ? onShowSupporters : null,
      );
    } else if (isOwn) {
      supporters = Text(
        context.l10n.event_prayer_waiting_first,
        strutStyle: context.tibetanStrutStyle(12, compact: true),
        style: TextStyle(fontSize: 12, color: muted),
      );
    } else {
      supporters = const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: supporters),
        ),
        if (!isOwn) ...[
          const SizedBox(width: 8),
          _PrayButton(
            prayedByMe: request.prayedByMe,
            myPrayerCount: request.myPrayerCount,
            accent: accent,
            isDark: isDark,
            onTap: onPray,
          ),
        ],
      ],
    );
  }
}

/// Body clamped to a few lines with a show more / less toggle when longer.
class _CollapsibleBody extends StatefulWidget {
  const _CollapsibleBody({
    required this.text,
    required this.textColor,
    required this.linkColor,
  });

  final String text;
  final Color textColor;
  final Color linkColor;

  static const int _collapsedLines = 4;

  @override
  State<_CollapsibleBody> createState() => _CollapsibleBodyState();
}

class _CollapsibleBodyState extends State<_CollapsibleBody> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_CollapsibleBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    // Measured in the font the Text below inherits from the theme (Inter,
    // Noto Serif Tibetan, ...); a bare style would measure the platform font
    // and misjudge where the lines break.
    final defaults = DefaultTextStyle.of(context);
    final style = defaults.style.merge(
      TextStyle(fontSize: 14, height: 1.4, color: widget.textColor),
    );
    final strut = context.tibetanStrutStyle(14);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          strutStyle: strut,
          maxLines: _CollapsibleBody._collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          textWidthBasis: defaults.textWidthBasis,
          textHeightBehavior:
              defaults.textHeightBehavior ??
              DefaultTextHeightBehavior.maybeOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        final body = Text(
          widget.text,
          maxLines: _expanded ? null : _CollapsibleBody._collapsedLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          strutStyle: strut,
          style: style,
        );
        if (!overflows) return body;

        final toggleLabel =
            _expanded ? context.l10n.show_less : context.l10n.show_more;
        void toggle() => setState(() => _expanded = !_expanded);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body,
              const SizedBox(height: 4),
              Semantics(
                button: true,
                expanded: _expanded,
                label: toggleLabel,
                onTap: toggle,
                excludeSemantics: true,
                child: Text(
                  toggleLabel,
                  strutStyle: context.tibetanStrutStyle(13, compact: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.linkColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Round avatar with an initial on the intention colour when there is no
/// picture. Shared by the card header, the avatar stack and the roster.
class PrayerAvatar extends StatelessWidget {
  const PrayerAvatar({
    super.key,
    required this.avatarUrl,
    required this.label,
    required this.size,
    required this.accent,
    required this.isDark,
    this.borderColor,
  });

  final String? avatarUrl;
  final String label;
  final double size;
  final Color accent;
  final bool isDark;

  /// Ring that separates overlapping avatars in a stack.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final border = borderColor;
    final inner = size - (border == null ? 0 : 4);

    final avatar = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: inner,
                  height: inner,
                  fit: BoxFit.cover,
                  errorWidget: _initial(inner),
                )
                : _initial(inner),
      ),
    );
    if (border == null) return avatar;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: border, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: avatar,
    );
  }

  Widget _initial(double inner) {
    // A white or black accent washes out to the surface; use the neutral
    // fallback fill instead so the circle still shows.
    final fill =
        prayerAccentNeedsBorder(accent, isDark)
            ? (isDark ? AppColors.chipBackgroundDark : AppColors.grey100)
            : Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.55 : 0.22),
              isDark ? AppColors.cardDark : AppColors.surfaceWhite,
            );
    return ColoredBox(
      color: fill,
      child: Center(
        child: Text(
          chatSenderInitials(label).characters.take(1).toString(),
          style: TextStyle(
            fontSize: inner * 0.42,
            fontWeight: FontWeight.w600,
            color:
                isDark
                    ? AppColors.textPrimaryDark
                    : prayerAccentTextColor(accent, isDark),
          ),
        ),
      ),
    );
  }
}

class _SupportersSummary extends StatelessWidget {
  const _SupportersSummary({
    required this.count,
    required this.recent,
    required this.accent,
    required this.cardColor,
    required this.isDark,
    required this.onTap,
  });

  final int count;
  final List<ChatPrayerUserDTO> recent;
  final Color accent;
  final Color cardColor;
  final bool isDark;
  final VoidCallback? onTap;

  static const double _avatarSize = 22;
  static const double _overlap = 7;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final shown = recent.take(3).toList();
    final extra = count - shown.length;
    final label =
        shown.isNotEmpty && extra > 0
            ? context.l10n.event_prayer_more_praying(extra)
            : context.l10n.event_prayer_people_praying(count);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shown.isNotEmpty) ...[
              SizedBox(
                width:
                    _avatarSize + (shown.length - 1) * (_avatarSize - _overlap),
                height: _avatarSize,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * (_avatarSize - _overlap),
                        child: PrayerAvatar(
                          avatarUrl: shown[i].avatarUrl,
                          label: shown[i].name ?? '',
                          size: _avatarSize,
                          accent: accent,
                          isDark: isDark,
                          borderColor: cardColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(12, compact: true),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(AppAssets.caretRight, size: 14, color: muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrayButton extends StatefulWidget {
  const _PrayButton({
    required this.prayedByMe,
    required this.myPrayerCount,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final bool prayedByMe;
  final int myPrayerCount;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  State<_PrayButton> createState() => _PrayButtonState();
}

class _PrayButtonState extends State<_PrayButton> {
  Offset? _lastTap;

  bool get prayedByMe => widget.prayedByMe;
  Color get accent => widget.accent;
  bool get isDark => widget.isDark;

  /// Every tap floats the mantra up from where it landed.
  void _handleTap() {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        _lastTap ??
        (box == null
            ? Offset.zero
            : box.localToGlobal(box.size.center(Offset.zero)));
    HapticFeedback.lightImpact();
    showFloatingPrayerText(
      context,
      origin: origin,
      text: prayerMantraForLocale(Localizations.localeOf(context)),
      accent: accent,
      isDark: isDark,
    );
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final label = context.l10n.event_prayer_pray;
    final mine = widget.myPrayerCount;
    final idleBorder = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final background =
        prayedByMe
            ? accent
            : (isDark ? AppColors.chipBackgroundDark : AppColors.surfaceWhite);
    final foreground =
        prayedByMe
            ? prayerAccentOnColor(accent)
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    // A white accent fill needs the hairline to read as a button at all.
    final border =
        prayedByMe && !prayerAccentNeedsBorder(accent, isDark)
            ? accent
            : idleBorder;

    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTapDown: (details) => _lastTap = details.globalPosition,
        onTap: onTap == null ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prayedByMe
                    ? AppAssets.handsPrayingFill
                    : AppAssets.handsPraying,
                size: 15,
                color: foreground,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                strutStyle: context.tibetanStrutStyle(12, compact: true),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (prayedByMe && mine > 0) ...[
                const SizedBox(width: 5),
                Text(
                  context.l10n.event_prayer_my_count(mine),
                  strutStyle: context.tibetanStrutStyle(12, compact: true),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: foreground.withValues(alpha: 0.8),
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
