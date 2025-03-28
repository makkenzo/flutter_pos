import 'package:meta/meta.dart';

@immutable
class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final String skuName;
  final int quantity;
  final double price;
  final double costPrice;
  final double total;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.skuName,
    required this.quantity,
    required this.price,
    required this.costPrice,
    required this.total,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    try {
      return SaleItem(
        // Числовые поля с безопасным парсингом из num?
        id: (json['id'] as num?)?.toInt() ?? -1,
        saleId: (json['sale_id'] as num?)?.toInt() ?? -1,
        productId: (json['product_id'] as num?)?.toInt() ?? -1,
        // --- ИЗМЕНЕНО: Строковое поле skuName с проверкой на null ---
        skuName: json['sku_name'] as String? ?? 'Неизвестный товар', // Значение по умолчанию
        // -----------------------------------------------------------
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e, stackTrace) {
      print("!!! Error parsing SaleItem from JSON: $e");
      print("Stack trace: $stackTrace");
      print("Problematic JSON for SaleItem: $json");
      rethrow;
    }
  }

  Map<String, dynamic> toJsonForSaleCreation() {
    return {'product_id': productId, 'quantity': quantity, 'price': price};
  }
}
