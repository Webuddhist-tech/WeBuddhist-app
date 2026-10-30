import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_page_toc.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Sections sheet (WF11/WF12/WF26): "Sections · Section n / m", then the
/// sections the pill counts, in order, under their group headings. Those
/// before the one on screen are ticked, the rest numbered; the one on screen
/// is marked, and the live one carries the Live pill. Pops with the section
/// to go to.
class ReaderSectionsSheet extends ConsumerWidget {
  final ValueListenable<ReaderSectionsSnapshot> snapshot;
  final ValueListenable<String?> current;

  const ReaderSectionsSheet({
    super.key,
    required this.snapshot,
    required this.current,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<ReaderSectionsSnapshot>(
      valueListenable: snapshot,
      builder:
          (context, page, _) => ValueListenableBuilder<String?>(
            valueListenable: current,
            builder: (context, currentKey, _) {
              final sections = page.sections;
              // The section at the top of the page, as the pill counts it.
              final at = sections.indexWhere((s) => s.section.key == currentKey);
              final index = at < 0 ? 0 : at;
              final total = sections.length + page.pendingSources;
              final script = ReaderScript.ofLanguage(
                sections.isEmpty ? null : sections[index].numeralLanguage,
              );
              return ReaderSheet(
                title: context.l10n.reader_sections_title,
                subtitle: Text(
                  context.l10n.reader_section_position(
                    readerNumerals(index + 1, script),
                    readerNumerals(total, script),
                  ),
                  style: TextStyle(
                    fontFamilyFallback: readerNumeralFallback(script),
                  ),
                ),
                scrolls: false,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _SectionList(
                  sections: sections,
                  pendingSources: page.pendingSources,
                  current: sections.isEmpty ? -1 : index,
                  liveKey: page.liveKey,
                ),
              );
            },
          ),
    );
  }
}

class _SectionList extends StatefulWidget {
  const _SectionList({
    required this.sections,
    required this.pendingSources,
    required this.current,
    required this.liveKey,
  });

  final List<ReaderSheetSection> sections;
  final int pendingSources;
  final int current;
  final String? liveKey;

  @override
  State<_SectionList> createState() => _SectionListState();
}

class _SectionListState extends State<_SectionList> {
  final _currentRow = GlobalKey();
  final _scroll = ScrollController();

  /// A row is never shorter than this, so an offset of this times the rows
  /// above the current one never jumps past it.
  static const double _minRowHeight = 46;

  @override
  void initState() {
    super.initState();
    // Opens with the section on screen in view.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(0));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the current row into view. The list only builds rows near the
  /// screen, so one far down a long table of contents has no context yet:
  /// jump towards it first, then centre it once it is built.
  void _reveal(int attempt) {
    if (!mounted || widget.current <= 0) return;
    final row = _currentRow.currentContext;
    if (row != null) {
      Scrollable.ensureVisible(row, alignment: 0.4);
      return;
    }
    if (attempt >= 4 || !_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        attempt == 0
            ? widget.current * _minRowHeight
            : position.pixels + position.viewportDimension;
    _scroll.jumpTo(target.clamp(0, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(attempt + 1));
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final children = <Widget>[];
    String? group;
    for (var i = 0; i < sections.length; i++) {
      final row = sections[i];
      if (row.group != null && row.group != group) {
        children.add(
          _GroupHeading(label: row.group!, language: row.groupLanguage),
        );
      }
      group = row.group;
      children.add(
        _SectionRow(
          key: i == widget.current ? _currentRow : null,
          row: row,
          position: i + 1,
          isCurrent: i == widget.current,
          isDone: i < widget.current,
          isLive: row.section.key == widget.liveKey,
          onTap: () => Navigator.of(context).pop(row.section),
        ),
      );
    }
    for (var i = 0; i < widget.pendingSources; i++) {
      children.add(const _PendingSectionRow());
    }
    return ListView(
      controller: _scroll,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

/// A heading over a group of sections ("AFTER THE PUJA").
class _GroupHeading extends ConsumerWidget {
  const _GroupHeading({required this.label, this.language});

  final String label;
  final String? language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final script = ReaderScript.of(label, language: language);
    final latin = script == ReaderScript.latin || script == ReaderScript.cyrillic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(
        latin ? label.toUpperCase() : label,
        // Sized by its own letters, not the interface's.
        style: readerSheetText(
          context,
          ReaderSheetTextRole.caps,
          color: style.palette.sheetMuted,
          script: script,
        ).copyWith(
          fontFamily: latin ? null : style.type.family(language ?? ''),
        ),
      ),
    );
  }
}

/// A section: ticked once read or numbered, its title, and the Live pill
/// when the puja leader is in it. The one on screen is marked.
class _SectionRow extends ConsumerWidget {
  const _SectionRow({
    super.key,
    required this.row,
    required this.position,
    required this.isCurrent,
    required this.isDone,
    required this.isLive,
    required this.onTap,
  });

  final ReaderSheetSection row;
  final int position;
  final bool isCurrent;
  final bool isDone;
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final palette = style.palette;
    final section = row.section;
    final script = ReaderScript.of(section.title, language: section.language);
    final latin = script == ReaderScript.latin || script == ReaderScript.cyrillic;
    final numerals = ReaderScript.ofLanguage(row.numeralLanguage);
    final muted = palette.sheetMuted;
    return Material(
      color: isCurrent ? palette.sheetCurrentRow : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // The tick or number centred under one another, as drawn.
                Container(
                  width: 26,
                  alignment: Alignment.center,
                  child:
                      isDone
                          ? Icon(AppAssets.check, size: 13, color: muted)
                          : Text(
                            readerNumerals(position, numerals),
                            style: readerSheetText(
                              context,
                              ReaderSheetTextRole.chip,
                              color: muted,
                              script: numerals,
                            ).copyWith(
                              fontFamilyFallback: readerNumeralFallback(
                                numerals,
                              ),
                            ),
                          ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    // Sized by the title's own letters: an English title
                    // in a Tibetan interface is 16, not 24.
                    style: readerSheetText(
                      context,
                      ReaderSheetTextRole.row,
                      color: isDone ? muted : palette.ink,
                      weight: isCurrent ? FontWeight.w600 : null,
                      script: script,
                    ).copyWith(
                      height: latin ? 1.25 : style.type.listLineHeight(section.language),
                      fontFamily:
                          latin ? null : style.type.family(section.language),
                    ),
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 10),
                  _LivePill(palette: palette),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red Live pill, as the header draws it.
class _LivePill extends StatelessWidget {
  const _LivePill({required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: palette.livePill,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: palette.livePillText,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.recitation_live_label,
          style: readerSheetText(
            context,
            ReaderSheetTextRole.chip,
            color: palette.livePillText,
          ),
        ),
      ],
    ),
  );
}

/// A text of the page still loading its first page.
class _PendingSectionRow extends ConsumerWidget {
  const _PendingSectionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ReaderStyle.of(context, ref).palette.sheetMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: muted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.loading,
            style: readerSheetText(
              context,
              ReaderSheetTextRole.row,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
