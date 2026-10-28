import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the launch splash is still playing its intro animation; the
/// router keeps the splash route up until it turns false, even once auth has
/// finished loading. Flipped to false exactly once, by the splash screen, and
/// never back: only the launch splash is held, later splashes (e.g. during a
/// login) are not.
final splashHoldProvider = StateProvider<bool>((ref) => true);
