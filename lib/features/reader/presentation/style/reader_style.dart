import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_palette.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flutter_pecha/features/reader/presentation/style/reader_palette.dart';
export 'package:flutter_pecha/features/reader/presentation/style/reader_typography.dart';

/// The reader's colours and text metrics, as one widget reads them.
class ReaderStyle {
  const ReaderStyle({required this.palette, required this.type});

  final ReaderPalette palette;
  final ReaderTypography type;

  /// A ritual direction between verses in [language], written in [script].
  /// Nothing draws one yet: the texts do not mark their directions.
  TextStyle instructionText(String language, ReaderScript script) {
    final metrics = type.instruction(script);
    return TextStyle(
      fontSize: metrics.fontSize,
      height: metrics.height,
      fontStyle: metrics.fontStyle,
      fontFamily: type.family(language, script: script),
      color: palette.instruction,
    );
  }

  /// The style at [context], following the reader's settings via [ref].
  static ReaderStyle of(BuildContext context, WidgetRef ref) => ReaderStyle(
    palette: ReaderPalette.resolve(Theme.of(context), ref),
    type: ReaderTypography.resolve(ref),
  );

  /// The app theme at [context] with the reader's page background, for a
  /// screen that shows a reader.
  static ThemeData theme(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final background = ReaderPalette.resolve(theme, ref).background;
    return theme.copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: theme.appBarTheme.copyWith(backgroundColor: background),
    );
  }
}
