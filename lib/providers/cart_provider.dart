import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial());

  void addItem(Product product) {
    final existingItem = state.findItemByBarcode(product.barcode);

    if (existingItem != null) {
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
      state = state.updateItem(updatedItem);
    } else {
      final newItem = CartItem(
        productId: product.id,
        barcode: product.barcode,
        name: product.skuName,
        priceAtSale: product.price,
        costPrice: product.costPrice,
        quantity: 1,
      );
      state = state.updateItem(newItem);
    }
  }

  void incrementQuantity(String sku) {
    final item = state.findItemByBarcode(sku);
    if (item != null) {
      final updatedItem = item.copyWith(quantity: item.quantity + 1);
      state = state.updateItem(updatedItem);
    }
  }

  void decrementQuantity(String sku) {
    final item = state.findItemByBarcode(sku);
    if (item != null) {
      if (item.quantity > 1) {
        final updatedItem = item.copyWith(quantity: item.quantity - 1);
        state = state.updateItem(updatedItem);
      } else {
        removeItem(sku);
      }
    }
  }

  void setQuantity(String barcode, int newQuantity) {
    final item = state.findItemByBarcode(barcode);
    if (item != null) {
      if (newQuantity <= 0) {
        removeItem(barcode);
      } else {
        final updatedItem = item.copyWith(quantity: newQuantity);
        state = state.updateItem(updatedItem);
      }
    }
  }

  void removeItem(String sku) {
    state = state.removeItem(sku);
  }

  void clearCart() {
    state = state.clear();
  }
}
