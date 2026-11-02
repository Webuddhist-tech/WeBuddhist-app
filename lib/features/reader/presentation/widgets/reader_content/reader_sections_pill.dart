import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Section name · N / total": the section at the top of the page and its
/// place among the page's sections. Opens the sections sheet.
///
/// Its size follows the script of the section name, not the size buttons.
class ReaderSectionsPill extends ConsumerWidget {
  final String title;
  final String language;

  /// The language the page's numbers are written in; the section name's
  /// when not given.
  final String? numeralLanguage;
  final int position;
  final int total;
  final VoidCallback onTap;

  const ReaderSectionsPill({
    super.key,
    required this.title,
    required this.language,
    this.numeralLanguage,
    required this.position,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ReaderStyle.of(context, ref);
    final palette = style.palette;
    final numeralScript = ReaderScript.ofLanguage(numeralLanguage ?? language);
    final titleSize = ReaderTypography.chromeSize(
      ReaderTypography.sectionPillSize,
      ReaderScript.of(title, language: language),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Center(
        child: Material(
          color: palette.pillBackground,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: style.type.family(language),
                        color: palette.pillText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${readerNumerals(context.l10n.reader_count_position('$position', '$total'), numeralScript)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: ReaderTypography.sectionPillSize,
                      color: palette.pillMuted,
                      fontFamilyFallback: readerNumeralFallback(numeralScript),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(AppAssets.caretDown, size: 16, color: palette.pillText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
