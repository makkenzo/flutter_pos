import 'package:flutter/material.dart';
import 'package:flutter_pos/theme/custom_themes/appbar_theme.dart';
import 'package:flutter_pos/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:flutter_pos/theme/custom_themes/card_theme.dart';
import 'package:flutter_pos/theme/custom_themes/checkbox_theme.dart';
import 'package:flutter_pos/theme/custom_themes/dialog_theme.dart';
import 'package:flutter_pos/theme/custom_themes/elevated_button_theme.dart';
import 'package:flutter_pos/theme/custom_themes/outlined_button_theme.dart';
import 'package:flutter_pos/theme/custom_themes/text_field_theme.dart';
import 'package:flutter_pos/theme/custom_themes/text_theme.dart';

import 'package:google_fonts/google_fonts.dart';

class TAppTheme {
  TAppTheme._();

  static const Color _seedColor = Color(0xFF546E7A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
    fontFamily: GoogleFonts.nunitoSans().fontFamily,
    scaffoldBackgroundColor: const Color(0xFFFDFDFD),
    textTheme: TTextTheme.lightTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme, // Пример
    cardTheme: TCardTheme.lightCardTheme, // Пример
    dialogTheme: TDialogTheme.lightDialogTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    // fontFamily: 'Poppins',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
    fontFamily: GoogleFonts.nunitoSans().fontFamily,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    textTheme: TTextTheme.darkTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    cardTheme: TCardTheme.darkCardTheme,
    dialogTheme: TDialogTheme.darkDialogTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
  );
}
