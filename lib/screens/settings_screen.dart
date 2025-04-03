import 'package:flutter/material.dart';
import 'package:flutter_pos/providers/settings_provider.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _storePhoneController;

  late ThemeMode _selectedThemeMode;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final currentSettings = ref.read(settingsProvider);
    _storeNameController = TextEditingController(text: currentSettings.storeName);
    _storeAddressController = TextEditingController(text: currentSettings.storeAddress);
    _storePhoneController = TextEditingController(text: currentSettings.storePhone);
    _selectedThemeMode = currentSettings.themeMode;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    }); // Показываем индикатор
    final notifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider); // Текущие для сравнения

    try {
      if (currentSettings.storeName != _storeNameController.text.trim()) {
        await notifier.updateStoreName(_storeNameController.text.trim());
      }
      if (currentSettings.storeAddress != _storeAddressController.text.trim()) {
        await notifier.updateStoreAddress(_storeAddressController.text.trim());
      }
      if (currentSettings.storePhone != _storePhoneController.text.trim()) {
        await notifier.updateStorePhone(_storePhoneController.text.trim());
      }
      if (currentSettings.themeMode != _selectedThemeMode) {
        await notifier.updateThemeMode(_selectedThemeMode);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Настройки сохранены'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        }); // Убираем индикатор
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSettings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : const Icon(Icons.save),
            tooltip: 'Сохранить настройки',
            onPressed: _isSaving ? null : _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TSizes.md),
        children: [
          Text('Данные магазина (для чеков)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          _buildTextField(controller: _storeNameController, labelText: 'Название магазина', enabled: !_isSaving),
          _buildTextField(controller: _storeAddressController, labelText: 'Адрес магазина', enabled: !_isSaving),
          _buildTextField(
            controller: _storePhoneController,
            labelText: 'Телефон магазина',
            keyboardType: TextInputType.phone,
            enabled: !_isSaving,
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          Text('Оформление', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          RadioListTile<ThemeMode>(
            title: const Text('Светлая тема'),
            value: ThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: _isSaving ? null : (value) => setState(() => _selectedThemeMode = value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Темная тема'),
            value: ThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: _isSaving ? null : (value) => setState(() => _selectedThemeMode = value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Системная тема'),
            subtitle: const Text('Автоматически подстраивается под настройки ОС'),
            value: ThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: _isSaving ? null : (value) => setState(() => _selectedThemeMode = value!),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          // Используем стиль из темы
        ),
        keyboardType: keyboardType,
        enabled: enabled,
      ),
    );
  }
}
