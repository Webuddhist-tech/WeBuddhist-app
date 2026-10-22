import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The text at the top of the page and, among several, its place; opens the
/// sections sheet.
class ReaderSectionsPill extends ConsumerWidget {
  final String title;
  final String language;
  final int position;
  final int? total;
  final VoidCallback onTap;

  const ReaderSectionsPill({
    super.key,
    required this.title,
    required this.language,
    required this.position,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ReaderStyle.of(context, ref);
    final palette = style.palette;
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
                        fontWeight: FontWeight.w600,
                        fontFamily: style.type.family(language),
                        color: palette.pillText,
                      ),
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '· $position / $total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.pillMuted,
                      ),
                    ),
                  ],
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
