import 'dart:math';

import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

/// Taglines shown on the splash screen; one is picked at random per launch.
final List<String Function(AppLocalizations)> splashTaglines = [
  (l10n) => l10n.splash_tagline_1,
  (l10n) => l10n.splash_tagline_2,
];

int randomSplashTaglineIndex([Random? random]) {
  final rng = random ?? Random();
  return rng.nextInt(splashTaglines.length);
}
