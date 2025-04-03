import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';

class TDialogTheme {
  TDialogTheme._();

  static final lightDialogTheme = DialogTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
  );

  static final darkDialogTheme = DialogTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
  );
}
