import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_content_block.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One item of a verse sheet's Commentary, Versions or Root text tab: its
/// text (HTML) and where it comes from.
class ReaderResourceEntry {
  const ReaderResourceEntry({
    required this.content,
    required this.language,
    required this.title,
    this.source,
    this.license,
  });

  final String content;
  final String language;
  final String title;
  final String? source;
  final String? license;
}

/// The order of a tab's language chips: the interface's language first, as
/// WF13 (English) and WF27 (Tibetan) draw it, then the text's own, then the
/// rest A→Z with Classical Chinese and Chinese side by side. Only
/// [languages] the verse has something in are listed.
List<String> readerResourceLanguages({
  required Iterable<String> languages,
  required String interfaceLanguage,
  required String textLanguage,
}) {
  final present = languages.toSet();
  final first = [
    for (final code in {interfaceLanguage, textLanguage})
      if (present.contains(code)) code,
  ];
  final rest = present.where((code) => !first.contains(code)).toList()..sort();
  if (rest.contains('lzh') && rest.contains('zh')) {
    rest.remove('zh');
    rest.insert(rest.indexOf('lzh') + 1, 'zh');
  }
  return [...first, ...rest];
}

/// A tab's items, one language at a time: a chip for each language, then
/// the chosen language's items, each with a line naming its source that
/// opens into the source's card (WF13–WF15, WF27).
///
/// [entries] come in order; [firstLanguage] (a plan task's pinned item's)
/// is chosen first when given, else the first chip.
class ReaderResourceList extends ConsumerStatefulWidget {
  const ReaderResourceList({
    super.key,
    required this.entries,
    required this.textLanguage,
    this.firstLanguage,
  });

  final List<ReaderResourceEntry> entries;
  final String textLanguage;
  final String? firstLanguage;

  @override
  ConsumerState<ReaderResourceList> createState() => _ReaderResourceListState();
}

class _ReaderResourceListState extends ConsumerState<ReaderResourceList> {
  String? _language;
  int? _expandedContent;
  int? _expandedSource;

  void _choose(String language) {
    setState(() {
      _language = language;
      _expandedContent = null;
      _expandedSource = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languages = readerResourceLanguages(
      languages: widget.entries.map((entry) => entry.language),
      interfaceLanguage: Localizations.localeOf(context).languageCode,
      textLanguage: widget.textLanguage,
    );
    if (languages.isEmpty) return const SizedBox.shrink();
    final first = widget.firstLanguage;
    final language =
        languages.contains(_language)
            ? _language!
            : first != null && languages.contains(first)
            ? first
            : languages.first;
    final entries = [
      for (final entry in widget.entries)
        if (entry.language == language) entry,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ReaderSheetChips(
          spacing: 8,
          children: [
            for (final code in languages)
              ReaderSheetChip(
                label: getNativeLanguageName(code) ?? getLanguageName(code, context),
                selected: code == language,
                onTap: () => _choose(code),
              ),
          ],
        ),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 10 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReaderPanelContentBlock(
                  content: entries[i].content,
                  language: entries[i].language,
                  segmentIndex: i,
                  isExpanded: _expandedContent == i,
                  onToggle:
                      () => setState(
                        () => _expandedContent = _expandedContent == i ? null : i,
                      ),
                ),
                _SourceLine(
                  entry: entries[i],
                  isExpanded: _expandedSource == i,
                  onToggle:
                      () => setState(
                        () => _expandedSource = _expandedSource == i ? null : i,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "⌄ Illuminating Rays": the item's source, opening into its card.
class _SourceLine extends ConsumerWidget {
  const _SourceLine({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
  });

  final ReaderResourceEntry entry;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final palette = style.palette;
    final l10n = context.l10n;
    final source = entry.source?.trim() ?? '';
    final license = entry.license?.trim() ?? '';

    // A title is set in its own script: Inter for Latin, else the reader's
    // font for its language.
    TextStyle titleText(Color color, {FontWeight? weight}) {
      final script = ReaderScript.of(entry.title, language: entry.language);
      final latin =
          script == ReaderScript.latin || script == ReaderScript.cyrillic;
      final base = readerSheetText(
        context,
        ReaderSheetTextRole.chip,
        color: color,
        weight: weight ?? FontWeight.w400,
        script: script,
      );
      return latin
          ? base
          : base.copyWith(
            fontFamily: style.type.family(entry.language, script: script),
            fontSize: ReaderTypography.chromeSize(13, script),
            fontWeight: weight ?? FontWeight.w400,
            height: 1.6,
          );
    }

    final muted = readerSheetText(
      context,
      ReaderSheetTextRole.chip,
      color: palette.sheetMuted,
      weight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: readerSheetTapTarget),
            child: Row(
              children: [
                Icon(
                  isExpanded ? AppAssets.caretUp : AppAssets.caretDown,
                  size: 13,
                  color: palette.sheetMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleText(palette.sheetMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child:
              isExpanded
                  ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.drawerChip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: titleText(palette.ink, weight: FontWeight.w600),
                        ),
                        if (source.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('${l10n.source}: $source', style: muted),
                        ],
                        if (license.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('${l10n.reader_license}: $license', style: muted),
                        ],
                      ],
                    ),
                  )
                  : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
