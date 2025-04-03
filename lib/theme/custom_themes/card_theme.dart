import 'package:flutter/material.dart';

import 'package:flutter_pos/utils/constants/sizes.dart';

class TCardTheme {
  TCardTheme._();

  static final lightCardTheme = CardTheme(
    elevation: 1,
    margin: const EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    clipBehavior: Clip.antiAlias,
  );

  static final darkCardTheme = CardTheme(
    elevation: 1,
    margin: const EdgeInsets.symmetric(vertical: TSizes.xs, horizontal: TSizes.sm),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
    clipBehavior: Clip.antiAlias,
  );
}
