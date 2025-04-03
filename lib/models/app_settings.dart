import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class AppSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final ThemeMode themeMode;
  // Добавьте другие настройки по мере необходимости

  const AppSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.themeMode,
  });

  // Значения по умолчанию
  factory AppSettings.defaults() => const AppSettings(
    storeName: "ПОМЕНЯЙТЕ НАЗВАНИЕ МАГАЗИНА",
    storeAddress: "ПОМЕНЯЙТЕ АДРЕС",
    storePhone: "+7 (000) 000-00-00",
    themeMode: ThemeMode.system,
  );

  AppSettings copyWith({
    String? apiUrl,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
