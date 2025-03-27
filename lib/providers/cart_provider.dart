import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  // CartNotifier не зависит напрямую от других провайдеров при создании,
  // но может читать их внутри своих методов с помощью 'ref'.
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  // Начинаем с пустого состояния корзины
  CartNotifier() : super(CartState.initial());

  // --- Методы для изменения корзины ---

  /// Добавляет товар в корзину.
  /// Если товар уже есть, увеличивает его количество на 1.
  void addItem(Product product) {
    // Ищем, есть ли уже такой товар в корзине по SKU
    final existingItem = state.findItemBySku(product.sku);

    if (existingItem != null) {
      // Товар найден - увеличиваем количество
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
      // Обновляем состояние новым списком, где измененный элемент заменен
      state = state.updateItem(updatedItem);
    } else {
      // Товара нет - создаем новый CartItem
      final newItem = CartItem(
        productId: product.id,
        sku: product.sku,
        name: product.name,
        priceAtSale: product.sellingPrice, // Фиксируем цену продажи!
        quantity: 1,
      );
      // Обновляем состояние, добавляя новый элемент
      state = state.updateItem(newItem);
    }
    // ВАЖНО: Здесь пока НЕ проверяем остаток товара (product.quantity).
    // Проверка остатков будет происходить на этапе оформления заказа (Шаг 8).
    // Корзина - это лишь намерение купить.
  }

  /// Увеличивает количество товара с указанным SKU на 1.
  void incrementQuantity(String sku) {
    final item = state.findItemBySku(sku);
    if (item != null) {
      final updatedItem = item.copyWith(quantity: item.quantity + 1);
      state = state.updateItem(updatedItem);
    }
  }

  /// Уменьшает количество товара с указанным SKU на 1.
  /// Если количество становится 0, товар удаляется из корзины.
  void decrementQuantity(String sku) {
    final item = state.findItemBySku(sku);
    if (item != null) {
      if (item.quantity > 1) {
        // Уменьшаем количество
        final updatedItem = item.copyWith(quantity: item.quantity - 1);
        state = state.updateItem(updatedItem);
      } else {
        // Количество равно 1, удаляем товар
        removeItem(sku);
      }
    }
  }

  /// Полностью удаляет товар с указанным SKU из корзины.
  void removeItem(String sku) {
    state = state.removeItem(sku);
  }

  /// Очищает всю корзину.
  void clearCart() {
    state = state.clear();
  }
}
