import 'package:flutter/material.dart';
import 'package:flutter_pos/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _storeNameKey = 'settings_store_name';
  static const _storeAddressKey = 'settings_store_address';
  static const _storePhoneKey = 'settings_store_phone';
  static const _themeModeKey = 'settings_theme_mode';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();

    final themeModeString = prefs.getString(_themeModeKey) ?? defaults.themeMode.name;
    final themeMode = ThemeMode.values.firstWhere((e) => e.name == themeModeString, orElse: () => defaults.themeMode);

    return AppSettings(
      storeName: prefs.getString(_storeNameKey) ?? defaults.storeName,
      storeAddress: prefs.getString(_storeAddressKey) ?? defaults.storeAddress,
      storePhone: prefs.getString(_storePhoneKey) ?? defaults.storePhone,
      themeMode: themeMode,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeNameKey, settings.storeName);
    await prefs.setString(_storeAddressKey, settings.storeAddress);
    await prefs.setString(_storePhoneKey, settings.storePhone);
    await prefs.setString(_themeModeKey, settings.themeMode.name);
  }
}
