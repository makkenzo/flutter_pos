import 'package:flutter_pos/models/analytics/latest_order.dart';
import 'package:flutter_pos/models/analytics/top_product.dart';
import 'package:meta/meta.dart';

@immutable
class SalesAnalytics {
  final double totalSalesSum;
  final int totalSalesCount;
  final int salesToday; // Количество продаж сегодня
  final double totalPaidSum;
  final double paidPercentage;
  final double totalUnpaidSum;
  final double unpaidPercentage;
  final double averageInvoice;
  final double profit;
  final List<LatestOrder> latestOrders;
  final List<TopProduct> topProducts;

  const SalesAnalytics({
    required this.totalSalesSum,
    required this.totalSalesCount,
    required this.salesToday,
    required this.totalPaidSum,
    required this.paidPercentage,
    required this.totalUnpaidSum,
    required this.unpaidPercentage,
    required this.averageInvoice,
    required this.profit,
    required this.latestOrders,
    required this.topProducts,
  });

  // Начальное/пустое состояние
  factory SalesAnalytics.empty() => const SalesAnalytics(
    totalSalesSum: 0,
    totalSalesCount: 0,
    salesToday: 0,
    totalPaidSum: 0,
    paidPercentage: 0,
    totalUnpaidSum: 0,
    unpaidPercentage: 0,
    averageInvoice: 0,
    profit: 0,
    latestOrders: [],
    topProducts: [],
  );

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    List<LatestOrder> orders = [];
    if (json['latest_orders'] != null && json['latest_orders'] is List) {
      orders =
          (json['latest_orders'] as List).map((item) => LatestOrder.fromJson(item as Map<String, dynamic>)).toList();
    }

    List<TopProduct> products = [];
    if (json['top_products'] != null && json['top_products'] is List) {
      products =
          (json['top_products'] as List).map((item) => TopProduct.fromJson(item as Map<String, dynamic>)).toList();
    }

    return SalesAnalytics(
      totalSalesSum: (json['total_sales_sum'] as num?)?.toDouble() ?? 0.0,
      totalSalesCount: (json['total_sales_count'] as num?)?.toInt() ?? 0,
      salesToday: (json['sales_today'] as num?)?.toInt() ?? 0,
      totalPaidSum: (json['total_paid_sum'] as num?)?.toDouble() ?? 0.0,
      paidPercentage: (json['paid_percentage'] as num?)?.toDouble() ?? 0.0,
      totalUnpaidSum: (json['total_unpaid_sum'] as num?)?.toDouble() ?? 0.0,
      unpaidPercentage: (json['unpaid_percentage'] as num?)?.toDouble() ?? 0.0,
      averageInvoice: (json['average_invoice'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      latestOrders: orders,
      topProducts: products,
    );
  }
}
