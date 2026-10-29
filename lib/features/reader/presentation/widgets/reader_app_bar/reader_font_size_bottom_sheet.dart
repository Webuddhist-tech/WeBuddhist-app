import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_background_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_verse_numbers_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which lines a reader shows: the original unless a translation is on and
/// the original is hidden, and the translation once one is active.
({bool original, bool translation}) readerShownLines(
  ReaderDualLayoutSettings settings,
) {
  final translation =
      settings.secondaryEnabled && settings.secondary.versionId != null;
  return (
    original: settings.originalVisible || !translation,
    translation: translation,
  );
}

/// The reader's Display sheet (Aa): for each line on screen, its size step
/// and font; then the page background.
///
/// With a [scope] it shows a group for the original (in [originalLanguage])
/// and one for the translation, each hidden while its line is off, and
/// "More settings ›", which turns the sheet to its More settings page.
/// Without one, for authored plan text, it shows a single size group and
/// the backgrounds.
class ReaderDisplaySheet extends ConsumerStatefulWidget {
  const ReaderDisplaySheet({
    super.key,
    this.scope,
    this.originalLanguage,
    this.onChangeLanguages,
  });

  final ReaderSettingsScope? scope;
  final String? originalLanguage;

  /// Opens the Languages sheet once this one has closed; "Change
  /// languages →" is left out without it.
  final VoidCallback? onChangeLanguages;

  @override
  ConsumerState<ReaderDisplaySheet> createState() =>
      _ReaderDisplaySheetState();
}

class _ReaderDisplaySheetState extends ConsumerState<ReaderDisplaySheet> {
  bool _moreSettings = false;

  /// More settings dims the page more than Display (WF19, WF17).
  void _showMoreSettings(bool shown) {
    setReaderSheetDim(
      context,
      shown ? ReaderSheetDim.moreSettings : ReaderSheetDim.display,
    );
    setState(() => _moreSettings = shown);
  }

  @override
  Widget build(BuildContext context) {
    if (_moreSettings) {
      return _MoreSettingsPage(
        onBack: () => _showMoreSettings(false),
        onChangeLanguages: widget.onChangeLanguages,
      );
    }
    final l10n = context.l10n;
    final size = ref.watch(readerTextSizeProvider);
    final sizes = ref.read(readerTextSizeProvider.notifier);
    final scope = widget.scope;

    final groups = <Widget>[];
    if (scope == null) {
      groups.add(
        _LineGroup(
          title: l10n.text_size,
          step: size.originalStep,
          onStep: sizes.setOriginalStep,
        ),
      );
    } else {
      final settings = ref.watch(readerDualSettingsProvider(scope));
      final shown = readerShownLines(settings);
      if (shown.original) {
        final language =
            widget.originalLanguage ?? settings.primary.languageCode;
        final original = _originalScript(context, ref, scope, language);
        groups.add(
          _LineGroup(
            title: '${l10n.reader_original_label} · ${original.name}',
            step: size.originalStep,
            onStep: sizes.setOriginalStep,
            line: ReaderFontLine.original,
            script: original.script,
          ),
        );
      }
      if (shown.translation) {
        final language = settings.secondary.languageCode;
        groups.add(
          _LineGroup(
            title:
                '${l10n.reader_translation_label} · '
                '${getLanguageName(language, context)}',
            step: size.translationStep,
            onStep: sizes.setTranslationStep,
            line: ReaderFontLine.translation,
            script: ReaderScript.ofLanguage(language),
            // Under an original a Latin or Cyrillic translation is italic.
            italic: shown.original,
          ),
        );
      }
    }

    // As WF17: the title at the start with a rule under the header, and a
    // rule after each group.
    return ReaderSheet(
      title: l10n.reader_display_title,
      centerTitle: false,
      headerRule: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups) ...[
            const SizedBox(height: 14),
            group,
            const SizedBox(height: 12),
            const ReaderSheetDivider(),
          ],
          const SizedBox(height: 14),
          ReaderSheetGroupTitle(l10n.reader_background),
          const SizedBox(height: 12),
          const _BackgroundTiles(),
          const SizedBox(height: 18),
          if (scope != null) ...[
            const ReaderSheetDivider(),
            ReaderSheetRow(
              label: l10n.reader_more_settings,
              trailing: const Icon(AppAssets.caretRight),
              onTap: () => _showMoreSettings(true),
            ),
          ],
        ],
      ),
    );
  }

  /// The script the original is shown in, and what to call it: the picked
  /// transliteration's name, else the language's.
  static ({ReaderScript script, String name}) _originalScript(
    BuildContext context,
    WidgetRef ref,
    ReaderSettingsScope scope,
    String language,
  ) {
    final service = ref.watch(transliterationServiceProvider);
    final converter = service.converterFor(language);
    final scriptId =
        converter == null
            ? null
            : ref.watch(
              readerOriginalScriptProvider(
                ReaderScriptScope(scope: scope, language: language),
              ),
            );
    final picked = converter?.scriptById(scriptId);
    if (picked == null) {
      return (
        script: ReaderScript.ofLanguage(language),
        name: getLanguageName(language, context),
      );
    }
    final fontLanguage = service.fontLanguageFor(language, scriptId!);
    return (
      // A script's name is written in it.
      script: ReaderScript.of(picked.label, language: fontLanguage ?? language),
      name: picked.label,
    );
  }
}

/// More settings, reached from Display (WF19/WF20): the spacing, whether
/// verse numbers show, and the way to the Languages sheet. Ritual
/// instructions join "In the text" once the texts mark their directions.
class _MoreSettingsPage extends ConsumerWidget {
  const _MoreSettingsPage({required this.onBack, this.onChangeLanguages});

  final VoidCallback onBack;
  final VoidCallback? onChangeLanguages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = ref.watch(
      readerTextSizeProvider.select((size) => size.spacing),
    );
    final verseNumbers = ref.watch(readerVerseNumbersProvider);
    return ReaderSheet(
      title: l10n.reader_more_settings,
      onBack: onBack,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReaderSheetLabel(l10n.reader_spacing),
          const SizedBox(height: 8),
          ReaderSheetSegments<ReaderSpacing>(
            values: ReaderSpacing.values,
            selected: spacing,
            labelOf:
                (value) => switch (value) {
                  ReaderSpacing.compact => l10n.reader_spacing_compact,
                  ReaderSpacing.normal => l10n.reader_spacing_normal,
                  ReaderSpacing.relaxed => l10n.reader_spacing_relaxed,
                },
            onSelected: ref.read(readerTextSizeProvider.notifier).setSpacing,
          ),
          const SizedBox(height: 16),
          ReaderSheetLabel(l10n.reader_in_the_text),
          const SizedBox(height: 4),
          ReaderSheetRow(
            label: l10n.reader_verse_numbers,
            trailing: ReaderSheetSwitch(
              value: verseNumbers,
              onChanged:
                  ref.read(readerVerseNumbersProvider.notifier).setShown,
            ),
          ),
          if (onChangeLanguages != null) ...[
            const ReaderSheetDivider(),
            ReaderSheetRow(
              label: l10n.reader_change_languages,
              labelTrailing: const Icon(AppAssets.arrowRight),
              onTap: () {
                Navigator.of(context).pop();
                onChangeLanguages!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// One line's size step and, when its script has a choice, its fonts, each
/// pill in the font it names as the line would show it.
class _LineGroup extends ConsumerWidget {
  const _LineGroup({
    required this.title,
    required this.step,
    required this.onStep,
    this.line,
    this.script,
    this.italic = false,
  });

  final String title;
  final int step;
  final Future<void> Function(int step) onStep;

  /// The line and script whose font the pills pick; no pills without them.
  final ReaderFontLine? line;
  final ReaderScript? script;

  /// The line is set in italic where its script has one (Latin, Cyrillic).
  final bool italic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = this.line;
    final script = this.script;
    final fonts =
        script == null ? const <ReaderFont>[] : ReaderFonts.forScript(script);
    final picked =
        line == null || script == null
            ? null
            : ref.watch(readerFontsProvider).fontFor(line, script);
    // A Latin or Cyrillic font's name is set in that font, as the line
    // would show it; other scripts' font names stay in the sheet's type.
    final latin =
        script == null ||
        script == ReaderScript.latin ||
        script == ReaderScript.cyrillic;
    final style = italic && latin ? FontStyle.italic : FontStyle.normal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReaderSheetGroupTitle(title),
        const SizedBox(height: 10),
        ReaderSheetSizeStep(
          script: script ?? ReaderScript.latin,
          fontFamily: (picked ?? ReaderFonts.sourceSerif4).family(),
          onSmaller:
              step > ReaderTextSize.minStep ? () => onStep(step - 1) : null,
          onLarger:
              step < ReaderTextSize.maxStep ? () => onStep(step + 1) : null,
        ),
        if (fonts.length > 1) ...[
          const SizedBox(height: 5),
          ReaderSheetChips(
            children: [
              for (final font in fonts)
                ReaderSheetChip(
                  label: font.label,
                  fontFamily: latin ? font.family(style: style) : null,
                  fontStyle: latin ? style : null,
                  selected: font.id == picked?.id,
                  onTap:
                      () => ref
                          .read(readerFontsProvider.notifier)
                          .choose(line!, script!, font),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// What a background is called on its swatch.
String readerBackgroundName(AppLocalizations l10n, ReaderBackground bg) =>
    switch (bg) {
      ReaderBackground.ricePaper => l10n.reader_background_rice_paper,
      ReaderBackground.gold => l10n.reader_background_gold,
      ReaderBackground.sky => l10n.reader_background_sky,
      ReaderBackground.white => l10n.reader_background_white,
      ReaderBackground.plum => l10n.reader_background_plum,
      ReaderBackground.templeRed => l10n.reader_background_temple_red,
      ReaderBackground.robeSaffron => l10n.reader_background_robe_saffron,
    };

/// The seven backgrounds as small pages across the sheet, each in the value
/// the phone's light or dark setting shows, with its radio. The picked one
/// is outlined and its radio ticked, in ink.
class _BackgroundTiles extends ConsumerWidget {
  const _BackgroundTiles();

  static const double _gap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final selected = ref.watch(readerBackgroundProvider);
    const count = 7;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile = (constraints.maxWidth - _gap * (count - 1)) / count;
        final backgrounds = ReaderBackground.values;
        return Row(
          children: [
            for (var i = 0; i < backgrounds.length; i++)
              // Each tile's tap target takes in half of the gaps beside it,
              // so a 42-wide tile still has a 44-wide target.
              SizedBox(
                width:
                    tile +
                    (i == 0 || i == backgrounds.length - 1 ? _gap / 2 : _gap),
                child: Semantics(
                  button: true,
                  selected: backgrounds[i] == selected,
                  label: readerBackgroundName(l10n, backgrounds[i]),
                  excludeSemantics: true,
                  child: Tooltip(
                    message: readerBackgroundName(l10n, backgrounds[i]),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          () => ref
                              .read(readerBackgroundProvider.notifier)
                              .select(backgrounds[i]),
                      child: Align(
                        alignment:
                            i == 0
                                ? Alignment.centerLeft
                                : i == backgrounds.length - 1
                                ? Alignment.centerRight
                                : Alignment.center,
                        child: _BackgroundTile(
                          width: tile,
                          page: backgrounds[i].of(brightness),
                          selected: backgrounds[i] == selected,
                          palette: palette,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.width,
    required this.page,
    required this.selected,
    required this.palette,
  });

  final double width;
  final Color page;
  final bool selected;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 86,
      decoration: BoxDecoration(
        color: page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? palette.ink : palette.drawerDivider,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          // Lines of text in the page's ink.
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 9),
              color: palette.ink,
            ),
          ],
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? palette.ink : null,
              border:
                  selected
                      ? null
                      : Border.all(color: palette.drawerHandle, width: 1.5),
            ),
            child:
                selected
                    ? Icon(AppAssets.check, size: 14, color: page)
                    : null,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Shows the reader's Display sheet; see [ReaderDisplaySheet].
void showReaderDisplaySheet(
  BuildContext context, {
  ReaderSettingsScope? scope,
  String? originalLanguage,
  VoidCallback? onChangeLanguages,
}) {
  showReaderSheet<void>(
    context,
    dim: ReaderSheetDim.display,
    builder:
        (_) => ReaderDisplaySheet(
          scope: scope,
          originalLanguage: originalLanguage,
          onChangeLanguages: onChangeLanguages,
        ),
  );
}
