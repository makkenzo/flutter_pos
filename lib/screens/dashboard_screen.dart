import 'package:flutter/material.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/screens/analytics_screen.dart';
import 'package:flutter_pos/screens/inventory_screen.dart';
import 'package:flutter_pos/screens/pos/pos_screen.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart';
import 'package:flutter_pos/screens/sales/sales_history_screen.dart';
import 'package:flutter_pos/screens/settings_screen.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/widgets/dashboard_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_DashboardItemData> dashboardItems = [
      _DashboardItemData(
        icon: Icons.point_of_sale_outlined,
        title: 'Касса',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
      ),
      _DashboardItemData(
        icon: Icons.inventory_2_outlined,
        title: 'Товары',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
      ),
      _DashboardItemData(
        icon: Icons.history_outlined,
        title: 'История Продаж',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
      ),
      _DashboardItemData(
        icon: Icons.inventory_outlined, // Иконка инвентаря/склада
        title: 'Остатки',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ), // Переход на новый экран
      ),
      _DashboardItemData(
        icon: Icons.analytics_outlined, // \u003c--- Новая иконка
        title: 'Аналитика',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ), // \u003c--- Переход
      ),
      _DashboardItemData(
        icon: Icons.settings_outlined, // Иконка настроек
        title: 'Настройки',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), // Переход
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель управления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Подтверждение выхода'),
                      content: const Text('Вы уверены, что хотите выйти из системы?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: dashboardItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: TSizes.spaceBtwItems,
          mainAxisSpacing: TSizes.spaceBtwItems,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final item = dashboardItems[index];
          return DashboardGridItem(icon: item.icon, title: item.title, onTap: item.onTap);
        },
      ),
    );
  }
}

class _DashboardItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DashboardItemData({required this.icon, required this.title, required this.onTap});
}
