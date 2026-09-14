import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Shared bottom navigation strip used by both `ReaderScreen` (for
/// SOURCE_REFERENCE items) and `PlanTextScreen` (for inline TEXT/IMAGE items).
///
/// Renders one of three layouts based on the navigation context:
/// - **Full controls** (canSwipe): prev arrow, "X of N" + title, next arrow,
///   or a finish (✓) button on the last item.
/// - **Single item** (one navigable subtask): title + finish (✓) button.
/// - **Minimal** (no plan context, e.g. reader opened from search): title only.
///
/// All state — current index, total count, prev/next availability — is read
/// from [navigationContext] so the strip stays in sync regardless of which
/// screen hosts it.
class PlanNavigationBottomBar extends StatelessWidget {
  final NavigationContext? navigationContext;

  /// Title shown in the centre when there is no [navigationContext]
  /// (e.g. minimal reader). Ignored when a plan context is present —
  /// in that case the current item's title is used.
  final String fallbackTitle;

  /// Optional font family applied to the centre title (used by the reader
  /// to honour the script of the source text).
  final String? fallbackTitleFontFamily;

  final VoidCallback? onPreviousTap;
  final VoidCallback? onNextTap;
  final VoidCallback? onFinishedTap;

  const PlanNavigationBottomBar({
    super.key,
    required this.navigationContext,
    required this.fallbackTitle,
    this.fallbackTitleFontFamily,
    this.onPreviousTap,
    this.onNextTap,
    this.onFinishedTap,
  });

  @override
  Widget build(BuildContext context) {
    final ctx = navigationContext;
    final canSwipe = ctx != null && ctx.canSwipe;
    final isCompletableNavigation =
        ctx != null &&
        (ctx.source == NavigationSource.plan ||
            ctx.source == NavigationSource.groupRecitationCollection ||
            ctx.source == NavigationSource.myRecitationCollection);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child:
            canSwipe
                ? _buildFullControls(context, ctx)
                : isCompletableNavigation
                ? _buildSingleItemControls(context, ctx)
                : _buildMinimalTitle(context),
      ),
    );
  }

  // ─── Layouts ────────────────────────────────────────────────────────

  Widget _buildMinimalTitle(BuildContext context) {
    return Center(
      child: _TitleText(
        text: fallbackTitle,
        fontFamily: fallbackTitleFontFamily,
      ),
    );
  }

  Widget _buildSingleItemControls(BuildContext context, NavigationContext ctx) {
    final title = ctx.currentItem?.title ?? fallbackTitle;
    final onFinish = onFinishedTap ?? () => Navigator.of(context).maybePop();
    return _buildBalancedRow(
      center: _TitleText(text: title, fontFamily: fallbackTitleFontFamily),
      trailing:
          () => _NavigationButton(
            icon: AppAssets.check,
            onTap: onFinish,
          ),
    );
  }

  Widget _buildFullControls(BuildContext context, NavigationContext ctx) {
    final hasPrevious = ctx.hasPreviousText;
    final hasNext = ctx.hasNextText;
    final progress = context.l10n.pagination_position(
      (ctx.currentTextIndex ?? 0) + 1,
      ctx.planTextItems!.length,
    );
    final title = ctx.currentItem?.title ?? fallbackTitle;
    void onPop() => Navigator.of(context).maybePop();

    return _buildBalancedRow(
      center: Column(
        children: [
          _TitleText(text: title),
          Text(
            progress,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      leading:
          hasPrevious
              ? () => _NavigationButton(
                icon: AppAssets.caretLeft,
                onTap: onPreviousTap ?? onPop,
              )
              : null,
      trailing:
          () =>
              hasNext
                  ? _NavigationButton(
                    icon: AppAssets.caretRight,
                    onTap: onNextTap ?? onPop,
                  )
                  : _NavigationButton(
                    icon: AppAssets.check,
                    onTap: onFinishedTap ?? onPop,
                  ),
    );
  }

  /// Keeps [center] visually centred by mirroring whichever side slot is empty
  /// with an invisible copy of the opposite navigation button.
  Widget _buildBalancedRow({
    required Widget center,
    Widget Function()? leading,
    Widget Function()? trailing,
  }) {
    assert(
      leading != null || trailing != null,
      'At least one side slot is required for balance',
    );

    final leadingWidget =
        leading?.call() ?? _invisibleSlot(trailing!.call());
    final trailingWidget =
        trailing?.call() ?? _invisibleSlot(leading!.call());

    return Row(
      children: [
        leadingWidget,
        Expanded(child: center),
        trailingWidget,
      ],
    );
  }

  Widget _invisibleSlot(Widget child) {
    return Opacity(opacity: 0, child: IgnorePointer(child: child));
  }
}

class _TitleText extends StatelessWidget {
  final String text;
  final String? fontFamily;

  const _TitleText({required this.text, this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;

    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
      strutStyle: context.tibetanStrutStyle(fontSize),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
    );
  }
}
