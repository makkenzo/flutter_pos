import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class TTextTheme {
  TTextTheme._();

  static TextTheme _baseTextTheme(Color textColor) =>
      GoogleFonts.nunitoSansTextTheme(TextTheme().apply(bodyColor: textColor, displayColor: textColor));

  /// Кастомная светлая тема текста
  static TextTheme lightTextTheme = _baseTextTheme(TColors.textPrimary);

  /// Кастомная темная тема текста
  static TextTheme darkTextTheme = _baseTextTheme(TColors.textWhite);
}
