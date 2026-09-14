import 'dart:math';

/// Taglines shown on the splash screen; one is picked at random per launch.
const List<String> splashTaglines = [
  'We Buddhists learn daily.',
  'We Buddhists practice daily.',
  'We Buddhists connect daily.',
  'We Buddhists do a little less harm every day.',
  'We Buddhists do a little more good every day.',
  'We Buddhists know our minds a little better every day.',
  'We Buddhists know that everything changes.',
  'We Buddhists know that nothing is 100% perfect and satisfactory.',
  'We Buddhists know that things are our own projections, not the way they look.',
];

String randomSplashTagline([Random? random]) {
  final rng = random ?? Random();
  return splashTaglines[rng.nextInt(splashTaglines.length)];
}
