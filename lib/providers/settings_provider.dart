import 'package:flutter/material.dart';
import 'package:flutter_pos/models/app_settings.dart';
import 'package:flutter_pos/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(SettingsService());
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(AppSettings.defaults()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _settingsService.loadSettings();
  }

  Future<void> updateStoreName(String newName) async {
    if (state.storeName == newName) return;
    state = state.copyWith(storeName: newName);
    await _settingsService.saveSettings(state);
  }

  /// Обновляет и сохраняет Адрес магазина
  Future<void> updateStoreAddress(String newAddress) async {
    if (state.storeAddress == newAddress) return;
    state = state.copyWith(storeAddress: newAddress);
    await _settingsService.saveSettings(state);
  }

  /// Обновляет и сохраняет Телефон магазина
  Future<void> updateStorePhone(String newPhone) async {
    if (state.storePhone == newPhone) return;
    state = state.copyWith(storePhone: newPhone);
    await _settingsService.saveSettings(state);
  }

  /// Обновляет и сохраняет Тему приложения
  Future<void> updateThemeMode(ThemeMode newMode) async {
    if (state.themeMode == newMode) return;
    state = state.copyWith(themeMode: newMode);
    await _settingsService.saveSettings(state);
  }
}
