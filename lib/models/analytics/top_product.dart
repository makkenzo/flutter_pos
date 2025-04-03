import 'package:meta/meta.dart';

@immutable
class TopProduct {
  final int productId;
  final String productName;
  final double productPrice;
  final int totalSold; // Количество проданных штук

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.totalSold,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: (json['product_id'] as num?)?.toInt() ?? -1,
      productName: json['product_name'] as String? ?? 'Неизвестный товар',
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      totalSold: (json['total_sold'] as num?)?.toInt() ?? 0,
    );
  }
}
