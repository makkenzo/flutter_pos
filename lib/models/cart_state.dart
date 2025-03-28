import 'package:flutter_pos/models/cart_item.dart';
import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

@immutable
class CartState {
  final List<CartItem> items;

  const CartState._(this.items);

  factory CartState.initial() => const CartState._([]);

  double get totalPrice {
    return items.map((item) => item.itemTotal).sum;
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

    return CartState._(List.unmodifiable(newItems));
  }

  CartState removeItem(String barcode) {
    final newItems = items.where((item) => item.barcode != barcode).toList();

    return CartState._(List.unmodifiable(newItems));
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
