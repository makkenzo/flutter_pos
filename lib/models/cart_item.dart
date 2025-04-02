import 'package:meta/meta.dart';

@immutable
class CartItem {
  final int productId;
  final String barcode;
  final String name;
  final double priceAtSale;

  int quantity;

  CartItem({
    required this.productId,
    required this.barcode,
    required this.name,
    required this.priceAtSale,

    required this.quantity,
  });

  CartItem increment() {
    return copyWith(quantity: quantity + 1);
  }

  CartItem? decrement() {
    if (quantity - 1 <= 0) {
      return null;
    }
    return copyWith(quantity: quantity - 1);
  }

  double get itemTotal => priceAtSale * quantity;

  CartItem copyWith({
    int? productId,
    String? barcode,
    String? name,
    double? priceAtSale,
    String? unit,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      priceAtSale: priceAtSale ?? this.priceAtSale,

      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          barcode == other.barcode;

  @override
  int get hashCode => barcode.hashCode;

  Map<String, dynamic> toJsonForSaleCreation() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': priceAtSale,
      'cost_price': 0,
    };
  }
}
