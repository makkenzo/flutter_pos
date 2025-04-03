import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos/models/analytics/top_product.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:intl/intl.dart';

class TopProductsBarChart extends StatelessWidget {
  final List<TopProduct> topProducts;
  final NumberFormat currencyFormat; // Для форматирования подсказок

  const TopProductsBarChart({super.key, required this.topProducts, required this.currencyFormat});

  static const List<Color> _barColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (topProducts.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("Нет данных для графика топ-товаров.")));
    }

    // Ограничим количество товаров на графике (например, топ-5)
    final displayedProducts = topProducts.take(5).toList();

    // Готовим данные для столбцов
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0; // Максимальное значение для оси Y

    for (int i = 0; i < displayedProducts.length; i++) {
      final product = displayedProducts[i];
      // Считаем сумму продаж для товара
      final double totalSum = product.productPrice * product.totalSold;
      if (totalSum > maxY) {
        maxY = totalSum; // Обновляем максимум
      }

      barGroups.add(
        BarChartGroupData(
          x: i, // Позиция по X (индекс товара)
          barRods: [
            BarChartRodData(
              toY: totalSum, // Высота столбца - сумма продаж
              color: _barColors[i % _barColors.length], // Циклический выбор цвета
              width: 16, // Ширина столбца
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.borderRadiusSm),
                topRight: Radius.circular(TSizes.borderRadiusSm),
              ),
            ),
          ],
          // Показываем подсказку при нажатии на столбец
          showingTooltipIndicators: [], // Будет управляться интерактивно
        ),
      );
    }

    maxY = maxY * 1.15;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.only(top: TSizes.md, right: TSizes.sm),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(TSizes.sm),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final product = displayedProducts[group.x];
                  final value = rod.toY;
                  return BarTooltipItem(
                    '${product.productName}\n',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: currencyFormat.format(value),
                        style: const TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < displayedProducts.length) {
                      final product = displayedProducts[index];
                      String title = product.productName;
                      if (title.length > 10) title = '${title.substring(0, 8)}...';
                      return SideTitleWidget(
                        space: 4,
                        meta: meta,
                        child: Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == meta.max) return const Text('');
                    String yValueText;
                    if (value >= 1000000) {
                      yValueText = '${(value / 1000000).toStringAsFixed(1)}M';
                    } else if (value >= 1000) {
                      yValueText = '${(value / 1000).toStringAsFixed(0)}k';
                    } else {
                      yValueText = value.toStringAsFixed(0);
                    }
                    return Text(
                      yValueText,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: theme.dividerColor.withValues(alpha: 0.5), strokeWidth: 0.5);
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            alignment: BarChartAlignment.spaceAround,
          ),
        ),
      ),
    );
  }
}
