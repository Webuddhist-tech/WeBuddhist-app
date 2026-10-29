import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The kinds of text on a reader sheet, with their Latin size and weight.
enum ReaderSheetTextRole {
  title(17, FontWeight.w600),
  group(15, FontWeight.w600),
  row(16, FontWeight.w400),
  caps(11, FontWeight.w600),
  chip(13, FontWeight.w500),

  /// A label over a group of rows ("Line spacing").
  label(14, FontWeight.w400),

  /// A segmented choice, and the chosen one.
  segment(14, FontWeight.w400),
  segmentSelected(14, FontWeight.w600);

  const ReaderSheetTextRole(this.size, this.weight);

  final double size;
  final FontWeight weight;
}

/// Sheet text for [role] in [color]. Sheets are in Inter; an interface in
/// Tibetan or Chinese keeps the app's font for its script and is set larger
/// by that script's interface factor, so labels look the same size.
TextStyle readerSheetText(
  BuildContext context,
  ReaderSheetTextRole role, {
  required Color color,
}) {
  final script = ReaderScript.ofLanguage(
    Localizations.maybeLocaleOf(context)?.languageCode,
  );
  final latin = script == ReaderScript.latin || script == ReaderScript.cyrillic;
  return TextStyle(
    fontSize: ReaderTypography.chromeSize(role.size, script),
    fontWeight: role.weight,
    fontFamily: latin ? ReaderFonts.inter.family(weight: role.weight) : null,
    letterSpacing: role == ReaderSheetTextRole.caps ? 0.6 : null,
    color: color,
  );
}

/// The smallest a tap target on a sheet may be, either way.
const double readerSheetTapTarget = 44;

/// Shows a reader sheet built by [builder]: it is as tall as its content,
/// up to most of the screen, and closes on a drag down.
Future<T?> showReaderSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  useSafeArea: true,
  builder: builder,
);

/// A sheet over the reader: a handle, its [title] with ✕ (and ← when
/// [onBack] is set), then [child], in the drawer colours of the reader's
/// background.
///
/// The title is centred, as on most of the design's sheets; Display sets it
/// at the start with a rule under the header ([centerTitle] false,
/// [headerRule] true). [child] scrolls when the sheet would be too tall; a
/// child that scrolls on its own (a list) sets [scrolls] to false and is
/// given the room left.
class ReaderSheet extends ConsumerWidget {
  const ReaderSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.centerTitle = true,
    this.headerRule = false,
    this.scrolls = true,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });

  final String title;

  /// A line under the title, in the muted colour.
  final Widget? subtitle;
  final Widget child;

  /// Shows ← before the title, which calls this.
  final VoidCallback? onBack;
  final bool centerTitle;
  final bool headerRule;
  final bool scrolls;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final l10n = context.l10n;
    final body = Padding(padding: padding, child: child);
    // ← sits in a slot of its own; a centred title keeps the slot empty
    // without one so it stays in the middle.
    final leading =
        onBack != null
            ? _SheetIconButton(
              icon: AppAssets.arrowLeft,
              tooltip: l10n.back,
              color: palette.ink,
              onPressed: onBack!,
            )
            : centerTitle
            ? const SizedBox(width: readerSheetTapTarget)
            : null;
    return Material(
      color: palette.drawerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.drawerHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: leading == null ? 20 : 6,
                  right: centerTitle ? 6 : 10,
                ),
                child: Row(
                  children: [
                    if (leading != null) leading,
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            centerTitle
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textAlign:
                                centerTitle ? TextAlign.center : TextAlign.start,
                            style: readerSheetText(
                              context,
                              ReaderSheetTextRole.title,
                              color: palette.ink,
                            ),
                          ),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              style: readerSheetText(
                                context,
                                ReaderSheetTextRole.chip,
                                color: palette.sheetMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: subtitle!,
                            ),
                        ],
                      ),
                    ),
                    _SheetIconButton(
                      icon: AppAssets.x,
                      tooltip: l10n.close,
                      color: palette.ink,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              if (headerRule)
                Divider(height: 1, thickness: 1, color: palette.drawerDivider),
              Flexible(
                child: scrolls ? SingleChildScrollView(child: body) : body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 22, color: color),
    tooltip: tooltip,
    constraints: const BoxConstraints(
      minWidth: readerSheetTapTarget,
      minHeight: readerSheetTapTarget,
    ),
    onPressed: onPressed,
  );
}

/// A small upper-case label over a group of rows ("IN THE TEXT").
class ReaderSheetCapsLabel extends ConsumerWidget {
  const ReaderSheetCapsLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: readerSheetText(
          context,
          ReaderSheetTextRole.caps,
          color: palette.sheetMuted,
        ),
      ),
    );
  }
}

/// A group's title, with [trailing] (a switch) at the end of its line.
class ReaderSheetGroupTitle extends ConsumerWidget {
  const ReaderSheetGroupTitle(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final text = Text(
      label,
      style: readerSheetText(
        context,
        ReaderSheetTextRole.group,
        color: palette.ink,
      ),
    );
    if (trailing == null) return text;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: readerSheetTapTarget),
      child: Row(children: [Expanded(child: text), trailing!]),
    );
  }
}

/// A switch in the sheet's selected colour, drawn 44 x 26 as WF19 does, in
/// a 44 high tap target. A [locked] switch is dimmed and does nothing: the
/// last line still on cannot be turned off.
class ReaderSheetSwitch extends ConsumerWidget {
  const ReaderSheetSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final enabled = !locked && onChanged != null;
    void toggle() {
      HapticFeedback.lightImpact();
      onChanged?.call(!value);
    }

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? toggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Opacity(
            opacity: locked ? 0.4 : 1,
            // The switch draws; the tap target around it answers.
            child: AbsorbPointer(
              child: AppToggleSwitch(
                value: value,
                width: 44,
                height: 26,
                trackOnColor: palette.selectedChip,
                trackOffColor: palette.drawerHandle,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of a sheet: a [label] with a [trailing] switch, or a row that
/// opens something (More settings ›, Change languages →).
class ReaderSheetRow extends ConsumerWidget {
  const ReaderSheetRow({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
    this.trailing,
    this.labelTrailing,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  /// At the end of the row: a switch, or a chevron.
  final Widget? trailing;

  /// Right after the label: an arrow.
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final text = Text(
      label,
      style: readerSheetText(
        context,
        ReaderSheetTextRole.row,
        color: palette.ink,
      ),
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: palette.ink, size: 22),
                child: leading!,
              ),
              const SizedBox(width: 16),
            ],
            if (labelTrailing == null)
              Expanded(child: text)
            else ...[
              Flexible(child: text),
              const SizedBox(width: 6),
              IconTheme.merge(
                data: IconThemeData(color: palette.ink, size: 16),
                child: labelTrailing!,
              ),
              const Spacer(),
            ],
            if (trailing != null)
              IconTheme.merge(
                data: IconThemeData(color: palette.sheetMuted, size: 18),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: row,
    );
  }
}

/// A small label over a group of rows, as WF19 sets "Line spacing" and "In
/// the text".
class ReaderSheetLabel extends ConsumerWidget {
  const ReaderSheetLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: readerSheetText(
          context,
          ReaderSheetTextRole.label,
          color: palette.sheetMuted,
        ),
      ),
    );
  }
}

/// One of a few choices side by side in a rounded track, the chosen one
/// raised in white as WF19/WF20 draw it (Compact · Normal · Relaxed).
class ReaderSheetSegments<T> extends ConsumerWidget {
  const ReaderSheetSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.drawerChip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(value);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration:
                        value == selected
                            ? BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            )
                            : null,
                    child: Text(
                      labelOf(value),
                      style: readerSheetText(
                        context,
                        value == selected
                            ? ReaderSheetTextRole.segmentSelected
                            : ReaderSheetTextRole.segment,
                        // The raised segment is white in light and dark.
                        color:
                            value == selected
                                ? ReaderPalette.inkLight
                                : palette.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rule between a sheet's groups.
class ReaderSheetDivider extends ConsumerWidget {
  const ReaderSheetDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Divider(
    height: 1,
    thickness: 1,
    color: ReaderPalette.resolve(Theme.of(context), ref).drawerDivider,
  );
}

/// A chip to pick one of a few: a script, a language, a font. A font's
/// chip may set its label in that font ([fontFamily], [fontStyle]).
class ReaderSheetChip extends ConsumerWidget {
  const ReaderSheetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontFamily,
    this.fontStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? fontFamily;
  final FontStyle? fontStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final style = readerSheetText(
      context,
      ReaderSheetTextRole.chip,
      color: selected ? palette.selectedChipText : palette.ink,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            onTap == null
                ? null
                : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
        // The chip is drawn 30 high; the rest of the 44 is still its tap
        // target.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          // Sized to its label: an aligned Container would fill the row.
          child: Container(
            constraints: const BoxConstraints(minHeight: 30, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? palette.selectedChip : palette.drawerChip,
              borderRadius: BorderRadius.circular(15),
              border:
                  selected ? null : Border.all(color: palette.drawerDivider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: style.copyWith(
                    fontFamily: fontFamily,
                    fontStyle: fontStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chips in rows that wrap.
class ReaderSheetChips extends StatelessWidget {
  const ReaderSheetChips({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 16, children: children);
}

/// The A | A buttons, side by side: one size step down, one up. Each shows
/// a letter of its line's [script] in the line's font ([fontFamily]): A,
/// ཀ, 字. A button is dimmed and does nothing at the end of the steps.
class ReaderSheetSizeStep extends ConsumerWidget {
  const ReaderSheetSizeStep({
    super.key,
    required this.onSmaller,
    required this.onLarger,
    this.script = ReaderScript.latin,
    this.fontFamily,
  });

  /// Null at the smallest step.
  final VoidCallback? onSmaller;

  /// Null at the largest step.
  final VoidCallback? onLarger;
  final ReaderScript script;
  final String? fontFamily;

  /// The letter, the small and large sizes, and the buttons' height for
  /// [script], as the design draws them.
  static ({String letter, double small, double large, double height})
  lookOf(ReaderScript script) => switch (script) {
    ReaderScript.tibetan => (letter: 'ཀ', small: 18, large: 28, height: 58),
    ReaderScript.chinese => (letter: '字', small: 14, large: 24, height: 42),
    ReaderScript.devanagari => (letter: 'अ', small: 14, large: 24, height: 42),
    ReaderScript.cyrillic => (letter: 'А', small: 14, large: 24, height: 35),
    ReaderScript.latin => (letter: 'A', small: 14, large: 24, height: 35),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final l10n = context.l10n;
    final look = lookOf(script);
    // The drawn button sits in a tap target at least 44 high.
    final tapPadding =
        look.height >= readerSheetTapTarget
            ? 0.0
            : (readerSheetTapTarget - look.height) / 2;
    Widget button(String tooltip, double size, VoidCallback? onTap) =>
        Expanded(
          child: Tooltip(
            message: tooltip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  onTap == null
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        onTap();
                      },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tapPadding),
                child: Container(
                  height: look.height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.drawerChip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    look.letter,
                    style: TextStyle(
                      fontSize: size,
                      height: 1.2,
                      fontFamily: fontFamily,
                      color:
                          onTap == null
                              ? palette.ink.withValues(alpha: 0.35)
                              : palette.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        button(l10n.reader_text_smaller, look.small, onSmaller),
        const SizedBox(width: 16),
        button(l10n.reader_text_larger, look.large, onLarger),
      ],
    );
  }
}
