import 'package:flutter/material.dart';
import 'package:flutter_pos/models/analytics/latest_order.dart';
import 'package:flutter_pos/models/analytics/sales_analytics.dart';
import 'package:flutter_pos/models/analytics/top_product.dart';
import 'package:flutter_pos/providers/analytics_provider.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:flutter_pos/widgets/top_products_bar_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsState analyticsState = ref.watch(analyticsProvider);
    final AsyncValue<SalesAnalytics> dataAsync = analyticsState.analyticsData;
    final DateTimeRange? dateRange = analyticsState.selectedDateRange;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
    final dateTimeFormat = DateFormat('dd.MM HH:mm', 'ru_RU');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика Продаж'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Выбрать период',
            onPressed: () async {
              final now = DateTime.now();
              final initialRange = dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                initialDateRange: initialRange,
                firstDate: DateTime(2020),
                lastDate: now,
                locale: const Locale('ru', 'RU'),
              );
              if (picked != null) {
                ref.read(analyticsProvider.notifier).setDateRange(picked);
              } else if (dateRange != null) {}
            },
          ),

          if (dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Сбросить период (показать все время)',
              onPressed: () => ref.read(analyticsProvider.notifier).setDateRange(null),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(analyticsProvider.notifier).refresh(),
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error:
              (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      Text('Ошибка загрузки аналитики:\n${formatErrorMessage(error)}', textAlign: TextAlign.center),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      ElevatedButton(
                        onPressed: () => ref.read(analyticsProvider.notifier).refresh(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),

          data:
              (analytics) => _buildAnalyticsContent(
                context,
                analytics,
                dateRange,
                theme,
                currencyFormat,
                dateFormat,
                dateTimeFormat,
                ref,
              ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    SalesAnalytics analytics,
    DateTimeRange? dateRange,
    ThemeData theme,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    DateFormat dateTimeFormat,
    WidgetRef ref,
  ) {
    final bool hasData =
        analytics.totalSalesCount > 0 || analytics.latestOrders.isNotEmpty || analytics.topProducts.isNotEmpty;

    String periodTitle = "За все время";
    if (dateRange != null) {
      periodTitle = "Период: ${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}";
    }

    return ListView(
      padding: const EdgeInsets.all(TSizes.md),
      children: [
        Text(periodTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: TSizes.spaceBtwItems),

        Wrap(
          spacing: TSizes.spaceBtwItems,
          runSpacing: TSizes.spaceBtwItems,
          alignment: WrapAlignment.center,
          children: [
            _buildKpiCard(context, 'Общая Сумма', currencyFormat.format(analytics.totalSalesSum), Icons.attach_money),
            _buildKpiCard(context, 'Продаж Всего', analytics.totalSalesCount.toString(), Icons.receipt_long),
            _buildKpiCard(context, 'Продаж Сегодня', analytics.salesToday.toString(), Icons.today),
            _buildKpiCard(context, 'Средний Чек', currencyFormat.format(analytics.averageInvoice), Icons.price_check),
            _buildKpiCard(context, 'Прибыль (Расч.)', currencyFormat.format(analytics.profit), Icons.trending_up),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        if (!hasData)
          const Center(
            child: Text("Нет данных для отображения за выбранный период.", style: TextStyle(color: Colors.grey)),
          ),

        if (hasData) ...[
          Text('Последние Заказы', style: theme.textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          _buildLatestOrdersList(analytics.latestOrders, currencyFormat, dateTimeFormat, ref, context),
          const SizedBox(height: TSizes.spaceBtwSections),

          Text('Топ Товаров', style: theme.textTheme.titleLarge),
          const SizedBox(height: TSizes.sm),
          TopProductsBarChart(topProducts: analytics.topProducts, currencyFormat: currencyFormat),
          _buildTopProductsList(analytics.topProducts, currencyFormat),
        ],
      ],
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: TSizes.iconLg, color: theme.colorScheme.primary),
              const SizedBox(height: TSizes.sm),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: TSizes.xs),
              Text(title, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestOrdersList(
    List<LatestOrder> orders,
    NumberFormat currencyFormat,
    DateFormat dateTimeFormat,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (orders.isEmpty) return const Text("Нет недавних заказов.", style: TextStyle(color: Colors.grey));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: CircleAvatar(radius: 16, child: Text((index + 1).toString())),
          title: Text('Заказ № ${order.orderId}', style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(dateTimeFormat.format(order.createdAt.toLocal())),
          trailing: Text(
            currencyFormat.format(order.totalAmount),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildTopProductsList(List<TopProduct> products, NumberFormat currencyFormat) {
    if (products.isEmpty) return const Text("Нет данных по топ товарам.", style: TextStyle(color: Colors.grey));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: CircleAvatar(radius: 16, child: Text((index + 1).toString())),
          title: Text(product.productName, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text('Цена: ${currencyFormat.format(product.productPrice)}'),
          trailing: Text(
            '${product.totalSold} шт.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
