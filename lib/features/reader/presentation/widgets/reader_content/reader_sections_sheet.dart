import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_page_toc.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The page's texts with their sections nested: the text on screen marked,
/// those before it ticked, the section on screen marked under its text.
/// Pops with the entry index to go to.
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = ReaderStyle.of(context, ref).palette;
    final muted = palette.sheetMuted;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ValueListenableBuilder<ReaderSectionsSnapshot>(
          valueListenable: snapshot,
          builder:
              (context, pages, _) => ValueListenableBuilder<String?>(
                valueListenable: current,
                builder: (context, currentKey, _) {
                  // A section key is "<source>:<id>".
                  final currentSource = int.tryParse(
                    (currentKey ?? '').split(':').first,
                  );
                  final currentText = pages.texts.indexWhere(
                    (t) => t.source == currentSource,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: ReaderPanelConstants.dragHandleWidth,
                        height: ReaderPanelConstants.dragHandleHeight,
                        decoration: BoxDecoration(
                          color: ReaderPanelConstants.dragHandleColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Full width, or the column centres the header.
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.reader_sections_title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (pages.title.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    pages.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            for (var i = 0; i < pages.texts.length; i++) ...[
                              _SectionRow(
                                index: i,
                                title: pages.texts[i].title,
                                language: pages.texts[i].language,
                                isCurrent: i == currentText,
                                isRead: i < currentText,
                                onTap:
                                    () => Navigator.of(
                                      context,
                                    ).pop(pages.texts[i].entryIndex),
                              ),
                              for (final section in pages.texts[i].sections)
                                _SectionRow(
                                  title: section.title,
                                  language: section.language,
                                  isCurrent: section.key == currentKey,
                                  nested: true,
                                  onTap:
                                      () => Navigator.of(
                                        context,
                                      ).pop(section.entryIndex),
                                ),
                            ],
                            for (var i = 0; i < pages.pendingSources; i++)
                              _PendingSectionRow(label: l10n.loading),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

/// A text row, numbered or ticked once read, or one of its sections
/// ([nested]) indented under it.
class _SectionRow extends ConsumerWidget {
  final int? index;
  final String title;
  final String language;
  final bool isCurrent;
  final bool isRead;
  final bool nested;
  final VoidCallback onTap;

  const _SectionRow({
    this.index,
    required this.title,
    required this.language,
    required this.isCurrent,
    this.isRead = false,
    this.nested = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ReaderStyle.of(context, ref);
    final muted = style.palette.sheetMuted;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isCurrent ? style.palette.sheetCurrentRow : null,
        padding: EdgeInsets.fromLTRB(
          nested ? 56 : 20,
          nested ? 10 : 14,
          20,
          nested ? 10 : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!nested) ...[
              SizedBox(
                width: 24,
                child:
                    isRead
                        ? Icon(AppAssets.check, size: 18, color: muted)
                        : Text(
                          '${(index ?? 0) + 1}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: (nested
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                      fontFamily: style.type.family(language),
                      fontWeight: isCurrent ? FontWeight.w700 : null,
                      height: style.type.headingHeight(language),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text of the page still loading its first page.
class _PendingSectionRow extends ConsumerWidget {
  final String label;

  const _PendingSectionRow({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = ReaderStyle.of(context, ref).palette.sheetMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: muted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
