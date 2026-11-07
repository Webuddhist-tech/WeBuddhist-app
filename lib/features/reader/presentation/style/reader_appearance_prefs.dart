import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';

/// The Display sheet's settings as one value, for saving to the server.
class ReaderAppearancePrefs extends Equatable {
  const ReaderAppearancePrefs({
    this.background = ReaderBackground.defaultBackground,
    this.textSize = const ReaderTextSize(),
    this.fonts = const ReaderFontChoices(),
    this.verseNumbers = true,
  });

  final ReaderBackground background;
  final ReaderTextSize textSize;
  final ReaderFontChoices fonts;
  final bool verseNumbers;

  /// Server shape; a setting left at its default is not sent.
  Map<String, dynamic> toWire() => {
    if (background != ReaderBackground.defaultBackground)
      'background': background.name,
    if (textSize.originalStep != ReaderTextSize.defaultStep)
      'original_step': textSize.originalStep,
    if (textSize.translationStep != ReaderTextSize.defaultStep)
      'translation_step': textSize.translationStep,
    if (fonts.picks.isNotEmpty) 'fonts': jsonDecode(fonts.toJson()),
    if (textSize.spacing != ReaderSpacing.normal)
      'spacing': textSize.spacing.name,
    if (!verseNumbers) 'verse_numbers': false,
  };

  /// Reads [toWire]'s output. A value this app does not recognise reads as the
  /// default, so a setting from a newer app never breaks this one.
  factory ReaderAppearancePrefs.fromWire(Map<String, dynamic> json) {
    final background = json['background'];
    final spacing = json['spacing'];
    final fonts = json['fonts'];
    final verseNumbers = json['verse_numbers'];
    return ReaderAppearancePrefs(
      background: ReaderBackground.fromName(
        background is String ? background : null,
      ),
      textSize: const ReaderTextSize().copyWith(
        originalStep: _stepOf(json['original_step']),
        translationStep: _stepOf(json['translation_step']),
        spacing: ReaderSpacing.fromName(spacing is String ? spacing : null),
      ),
      fonts:
          fonts is Map
              ? ReaderFontChoices.fromJson(jsonEncode(fonts))
              : const ReaderFontChoices(),
      verseNumbers: verseNumbers is bool ? verseNumbers : true,
    );
  }

  static int? _stepOf(Object? value) => value is num ? value.toInt() : null;

  @override
  List<Object?> get props => [background, textSize, fonts, verseNumbers];
}
