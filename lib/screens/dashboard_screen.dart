import 'package:flutter/material.dart';
import 'package:flutter_pos/models/analytics/sales_analytics.dart';
import 'package:flutter_pos/providers/analytics_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/screens/analytics_screen.dart';
import 'package:flutter_pos/screens/inventory_screen.dart';
import 'package:flutter_pos/screens/pos/pos_screen.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart';
import 'package:flutter_pos/screens/sales/sales_history_screen.dart';
import 'package:flutter_pos/screens/settings_screen.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:flutter_pos/widgets/dashboard_item.dart';
import 'package:flutter_pos/widgets/kpi_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');

    final AsyncValue<SalesAnalytics> analyticsAsync = ref.watch(
      analyticsProvider.select((state) => state.analyticsData),
    );

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
        icon: Icons.inventory_outlined,
        title: 'Остатки',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
      ),
      _DashboardItemData(
        icon: Icons.analytics_outlined,
        title: 'Аналитика',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
      ),
      _DashboardItemData(
        icon: Icons.settings_outlined,
        title: 'Настройки',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
      body: RefreshIndicator(
        onRefresh: () async => ref.read(analyticsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
              child: Text("Обзор", style: theme.textTheme.titleLarge), // Заголовок секции
            ),
            _buildKpiHeader(context, analyticsAsync, currencyFormat), // Выносим в отдельный метод
            const SizedBox(height: TSizes.spaceBtwSections), // Отступ
            // --- Секция Навигации (Сетка) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
              child: Text("Основные Разделы", style: theme.textTheme.titleLarge),
            ),
            _buildNavigationGrid(context, dashboardItems),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiHeader(BuildContext context, AsyncValue<SalesAnalytics> analyticsAsync, NumberFormat currencyFormat) {
    final theme = Theme.of(context);

    return analyticsAsync.when(
      loading:
          () => Shimmer.fromColors(
            baseColor: theme.brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[300]!,
            highlightColor: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Wrap(
              // \u003c--- Используем Wrap
              spacing: TSizes.md, // Горизонтальный отступ
              runSpacing: TSizes.sm, // Вертикальный отступ при переносе
              children: List.generate(
                4,
                (_) => // Показываем несколько плейсхолдеров
                    const KpiWidget(title: 'Загрузка...', value: '–––', icon: Icons.sync),
              ),
            ),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
            child: Center(
              child: Text(
                'Ошибка загр. обзора: ${formatErrorMessage(error)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      data:
          (analytics) => Wrap(
            spacing: TSizes.md, // Горизонтальный отступ
            runSpacing: TSizes.sm, // Вертикальный отступ при переносе
            alignment: WrapAlignment.start,
            children: [
              KpiWidget(title: 'Продаж Сегодня', value: analytics.salesToday.toString(), icon: Icons.today_outlined),

              KpiWidget(
                title: 'Выручка (Общая)',
                value: currencyFormat.format(analytics.totalSalesSum),
                icon: Icons.show_chart_outlined,
              ),

              KpiWidget(
                title: 'Прибыль (Расч.)',
                value: currencyFormat.format(analytics.profit),
                icon: Icons.trending_up_outlined,
                iconColor: Colors.green.shade700, // Выделим прибыль
              ),

              KpiWidget(
                title: 'Средний Чек',
                value: currencyFormat.format(analytics.averageInvoice),
                icon: Icons.price_check_outlined,
              ),
            ],
          ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context, List<_DashboardItemData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth >= 900) ? 4 : ((screenWidth >= 600) ? 3 : 2);
        // Для плиток без Card можно попробовать немного другое соотношение
        final double childAspectRatio = (crossAxisCount > 2) ? 1.1 : 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Отключаем скролл сетки
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.md),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: TSizes.md,
            mainAxisSpacing: TSizes.md,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            // Используем НОВЫЙ виджет плитки
            return DashboardGridItem(icon: item.icon, title: item.title, onTap: item.onTap);
          },
        );
      },
    );
  }
}

class _DashboardItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DashboardItemData({required this.icon, required this.title, required this.onTap});
}
