import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/colors.dart';

class TCheckboxTheme {
  TCheckboxTheme._();

  static final lightCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.all<Color>(TColors.primary),
    checkColor: WidgetStateProperty.all<Color>(TColors.white),
    overlayColor: WidgetStateProperty.all<Color>(TColors.primary),
  );

  static final darkCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.all<Color>(TColors.primary),
    checkColor: WidgetStateProperty.all<Color>(TColors.white),
    overlayColor: WidgetStateProperty.all<Color>(TColors.primary),
  );
}
