import 'package:equatable/equatable.dart';

/// How much room the reader leaves between lines and verses.
enum ReaderSpacing {
  compact(lineHeight: 0.9, verseGap: 16, pairGap: 8, inPairGap: 0),
  normal(lineHeight: 1.0, verseGap: 24, pairGap: 12, inPairGap: 2),
  relaxed(lineHeight: 1.15, verseGap: 32, pairGap: 16, inPairGap: 6);

  const ReaderSpacing({
    required this.lineHeight,
    required this.verseGap,
    required this.pairGap,
    required this.inPairGap,
  });

  /// Multiplies every line height.
  final double lineHeight;

  /// From the bottom of one verse (its number) to the top of the next.
  final double verseGap;

  /// Between an original line and the next original line of the same verse.
  final double pairGap;

  /// Between the lines of one pair or block: an original and its translation.
  final double inPairGap;

  static ReaderSpacing fromName(String? name) => ReaderSpacing.values
      .firstWhere((s) => s.name == name, orElse: () => ReaderSpacing.normal);
}

/// The reader's text size settings: a size step for the original line, one
/// for the translation line, and the spacing. One setting for every reader,
/// kept when the person switches script or language.
class ReaderTextSize extends Equatable {
  const ReaderTextSize({
    this.originalStep = defaultStep,
    this.translationStep = defaultStep,
    this.spacing = ReaderSpacing.normal,
  });

  final int originalStep;
  final int translationStep;
  final ReaderSpacing spacing;

  /// Size multipliers of steps 1 to 7.
  static const List<double> stepScales = [0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75];
  static const int minStep = 1;
  static const int maxStep = 7;
  static const int defaultStep = 3;

  /// The size the app stored before steps, which step 3 is.
  static const double legacyDefaultFontSize = 18;

  static double scaleOf(int step) => stepScales[clampStep(step) - 1];

  static int clampStep(int step) => step.clamp(minStep, maxStep);

  /// The step closest to a font size saved by the old A/A buttons.
  static int stepForLegacyFontSize(double fontSize) {
    final scale = fontSize / legacyDefaultFontSize;
    var best = defaultStep;
    var bestDistance = double.infinity;
    for (var i = 0; i < stepScales.length; i++) {
      final distance = (stepScales[i] - scale).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i + 1;
      }
    }
    return best;
  }

  ReaderTextSize copyWith({
    int? originalStep,
    int? translationStep,
    ReaderSpacing? spacing,
  }) => ReaderTextSize(
    originalStep: clampStep(originalStep ?? this.originalStep),
    translationStep: clampStep(translationStep ?? this.translationStep),
    spacing: spacing ?? this.spacing,
  );

  @override
  List<Object?> get props => [originalStep, translationStep, spacing];
}
