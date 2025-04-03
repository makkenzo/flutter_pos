import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:meta/meta.dart';

@immutable
class Sale {
  final String orderId;
  final int userId;
  final double totalAmount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentMethod paymentMethod;
  final List<SaleItem> items;

  const Sale({
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentMethod,
    required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Парсим список items (без изменений, но теперь SaleItem.fromJson более устойчив)
    var itemsList = <SaleItem>[];
    if (json['items'] != null && json['items'] is List) {
      itemsList =
          (json['items'] as List).map((itemJson) => SaleItem.fromJson(itemJson as Map<String, dynamic>)).toList();
    }

    try {
      return Sale(
        // --- ИЗМЕНЕНО: Строковые поля с проверкой на null ---
        orderId: json['order_id'] as String? ?? 'N/A', // Значение по умолчанию
        userId: (json['user_id'] as num?)?.toInt() ?? -1,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'UNK', // Неизвестная валюта
        status: json['status'] as String? ?? 'unknown', // Неизвестный статус
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == (json['payment_method'] as String? ?? 'other'),
          orElse: () => PaymentMethod.other,
        ),
        // ---------------------------------------------------
        // Даты с безопасным парсингом
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime(1970), // Ранняя дата по умолчанию
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime(1970),
        items: itemsList,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJsonForCreation(List<Map<String, dynamic>> itemsJsonList, String paymentMethodName) {
    return {'total_amount': totalAmount, 'payment_method': paymentMethodName, 'items': itemsJsonList};
  }
}
