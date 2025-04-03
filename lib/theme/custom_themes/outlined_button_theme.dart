import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/colors.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';

class TOutlinedButtonTheme {
  TOutlinedButtonTheme._();

  /// Светлая тема
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: TColors.primary,
      backgroundColor: TColors.white,
      side: const BorderSide(color: TColors.primary),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonHeight / 3),
      textStyle: const TextStyle(fontSize: TSizes.fontSizeMd, color: TColors.textPrimary, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    ),
  );

  /// Темная тема
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: TColors.white,
      backgroundColor: TColors.primary,
      side: const BorderSide(color: TColors.primary),
      padding: const EdgeInsets.symmetric(vertical: TSizes.buttonHeight / 3),
      textStyle: const TextStyle(fontSize: TSizes.fontSizeMd, color: TColors.textWhite, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    ),
  );
}
