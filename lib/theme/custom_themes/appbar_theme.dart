import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/colors.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:google_fonts/google_fonts.dart';

class TAppBarTheme {
  TAppBarTheme._();

  static final lightAppBarTheme = AppBarTheme(
    elevation: 0, // Без тени
    centerTitle: false, // Заголовок слева
    scrolledUnderElevation: 0, // Без тени при скролле
    backgroundColor: Colors.transparent, // Прозрачный фон (цвет возьмется от Scaffold)
    surfaceTintColor: Colors.transparent, // Убрать эффект окрашивания при скролле
    iconTheme: const IconThemeData(color: TColors.black, size: TSizes.iconMd),
    actionsIconTheme: const IconThemeData(color: TColors.black, size: TSizes.iconMd),
    titleTextStyle: GoogleFonts.nunitoSans(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: TColors.black,
    ), // Явно задаем шрифт и стиль заголовка
  );

  static final darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: TColors.white, size: TSizes.iconMd),
    actionsIconTheme: const IconThemeData(color: TColors.white, size: TSizes.iconMd),
    titleTextStyle: GoogleFonts.nunitoSans(fontSize: 18.0, fontWeight: FontWeight.w600, color: TColors.white),
  );
}
