import 'package:flutter_pos/models/cart_item.dart';
import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

enum CartDiscountType { none, percentage, fixedAmount }

@immutable
class CartState {
  final List<CartItem> items;
  final CartDiscountType discountType;
  final double discountValue;

  const CartState._({
    required this.items,
    this.discountType = CartDiscountType.none, // По умолчанию скидки нет
    this.discountValue = 0.0,
  });

  factory CartState.initial() => const CartState._(items: []);

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.itemTotal);
  }

  double get cartDiscountAmount {
    switch (discountType) {
      case CartDiscountType.percentage:
        // Рассчитываем процент от subtotal
        // Убедимся, что скидка не больше 100% и не меньше 0%
        final percent = discountValue.clamp(0.0, 100.0);
        return subtotal * (percent / 100.0);
      case CartDiscountType.fixedAmount:
        // Применяем фиксированную сумму, но не больше, чем subtotal
        return discountValue.clamp(0.0, subtotal);
      case CartDiscountType.none:
      default:
        return 0.0;
    }
  }

  double get totalPrice {
    return subtotal - cartDiscountAmount;
  }

  int get totalItemsCount {
    return items.map((item) => item.quantity).sum;
  }

  int get uniqueItemsCount => items.length;

  bool get isEmpty => items.isEmpty;

  CartItem? findItemByBarcode(String barcode) {
    return items.firstWhereOrNull((item) => item.barcode == barcode);
  }

  CartState updateItem(CartItem itemToUpdate) {
    final index = items.indexWhere((item) => item.barcode == itemToUpdate.barcode);
    final newItems = List<CartItem>.from(items);

    if (index != -1) {
      newItems[index] = itemToUpdate;
    } else {
      newItems.add(itemToUpdate);
    }

    return CartState._(items: newItems, discountType: discountType, discountValue: discountValue);
  }

  CartState removeItem(String barcode) {
    final newItems = items.where((item) => item.barcode != barcode).toList();

    return CartState._(items: newItems, discountType: discountType, discountValue: discountValue);
  }

  CartState applyCartDiscount(CartDiscountType type, double value) {
    // Можно добавить валидацию value (например, % не больше 100)
    return CartState._(items: items, discountType: type, discountValue: value);
  }

  CartState removeCartDiscount() {
    return CartState._(items: items, discountType: CartDiscountType.none, discountValue: 0.0);
  }

  CartState clear() {
    return CartState.initial();
  }

  @override
  String toString() {
    return 'CartState(items: ${items.length}, total: $totalPrice)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartState &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(items, other.items);

  @override
  int get hashCode => const DeepCollectionEquality().hash(items);
}
