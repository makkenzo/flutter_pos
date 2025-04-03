import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';

class TElevatedButtonTheme {
  TElevatedButtonTheme._();

  /// Светлая тема
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0, // Небольшая тень
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: TSizes.md), // Вертикальный отступ
      textStyle: const TextStyle(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
    ),
  );

  /// Темная тема
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: TSizes.md),
      textStyle: const TextStyle(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
      minimumSize: const Size(double.infinity, TSizes.buttonHeight),
      // Цвета также возьмутся из темной ColorScheme
    ),
  );
}
