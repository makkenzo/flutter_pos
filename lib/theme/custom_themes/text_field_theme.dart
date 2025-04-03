import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/colors.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static final _baseBorder = UnderlineInputBorder(
    // Используем подчеркивание
    // borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
    borderSide: BorderSide(width: 1, color: TColors.grey.withValues(alpha: 0.5)),
  );

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,

    labelStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeMd, color: TColors.textSecondary),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.textSecondary),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal), // Сброс курсива по умолчанию
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.textPrimary.withValues(alpha: 0.8)),

    filled: false,

    border: _baseBorder,
    enabledBorder: _baseBorder,
    focusedBorder: _baseBorder.copyWith(
      // При фокусе линия становится основной
      borderSide: const BorderSide(width: 1.5, color: TColors.primary), // Используем цвет TColors для акцента
    ),
    errorBorder: _baseBorder.copyWith(
      // Ошибка - красная линия
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
    focusedErrorBorder: _baseBorder.copyWith(
      // Ошибка в фокусе - утолщенная красная
      borderSide: const BorderSide(width: 1.5, color: TColors.error),
    ),

    contentPadding: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.xs), // Внутренние отступы
    isDense: true,
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    prefixIconColor: TColors.grey,
    suffixIconColor: TColors.grey,

    labelStyle: const TextStyle().copyWith(
      fontSize: TSizes.fontSizeMd,
      color: TColors.textWhite.withValues(alpha: 0.8),
    ),
    hintStyle: const TextStyle().copyWith(fontSize: TSizes.fontSizeSm, color: TColors.grey),
    floatingLabelStyle: const TextStyle().copyWith(color: TColors.textWhite.withValues(alpha: 0.8)),

    filled: false,

    border: UnderlineInputBorder(borderSide: BorderSide(width: 1, color: TColors.darkGrey.withValues(alpha: .8))),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(width: 1, color: TColors.darkGrey.withValues(alpha: .8)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(width: 1.5, color: TColors.primary.withValues(alpha: .8)),
    ),

    contentPadding: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md),
    isDense: true,
  );
}
