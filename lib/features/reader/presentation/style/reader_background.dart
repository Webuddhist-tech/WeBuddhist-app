import 'package:flutter/material.dart';

/// The page colour the person picks for the reader. Each has a light and a
/// dark value; the phone's light or dark setting picks which one shows.
enum ReaderBackground {
  ricePaper(light: Color(0xFFFFF4E3), dark: Color(0xFF222222)),
  gold(light: Color(0xFFFFF1DA), dark: Color(0xFF402F12)),
  sky(light: Color(0xFFEBF2FA), dark: Color(0xFF272F3A)),
  white(light: Color(0xFFFFFFFF), dark: Color(0xFF141414)),
  plum(light: Color(0xFFEDE8EB), dark: Color(0xFF4D183B)),
  templeRed(light: Color(0xFFFDECEC), dark: Color(0xFF3A1011)),
  robeSaffron(light: Color(0xFFFFDED4), dark: Color(0xFF662510));

  const ReaderBackground({required this.light, required this.dark});

  final Color light;
  final Color dark;

  static const ReaderBackground defaultBackground = ReaderBackground.ricePaper;

  Color of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static ReaderBackground fromName(String? name) => ReaderBackground.values
      .firstWhere((b) => b.name == name, orElse: () => defaultBackground);
}
