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
    // --- УБИРАЕМ ПРОВЕРКУ ОСТАТКОВ ЗДЕСЬ ---
    // final existingItem = state.findItemByBarcode(product.barcode);
    // final quantityInCart = existingItem?.quantity ?? 0;
    // if (product.quantity <= quantityInCart) {
    //   print('Cannot add...');
    //   throw Exception('Недостаточно товара...');
    // }
    // --------------------------------------

    // Ищем товар в корзине по barcode
    final existingItem = state.findItemByBarcode(
      product.barcode,
    ); // Убедитесь, что этот метод есть в CartState

    if (existingItem != null) {
      // Товар найден - увеличиваем количество
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      state = state.updateItem(updatedItem);
    } else {
      // Товара нет - создаем новый CartItem
      final newItem = CartItem(
        productId: product.id,
        barcode: product.barcode, // Сохраняем barcode
        name: product.skuName,
        priceAtSale: product.price,
        quantity: 1,
        // costPrice: product.costPrice, // Если вы решили хранить costPrice в CartItem
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

  void removeItem(String sku) {
    state = state.removeItem(sku);
  }

  void clearCart() {
    state = state.clear();
  }
}
