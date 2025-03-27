import 'package:flutter_pos/main.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final saleNotifierProvider = StateNotifierProvider<SaleNotifier, AsyncValue<int?>>((ref) {
  return SaleNotifier(ref);
});

class SaleNotifier extends StateNotifier<AsyncValue<int?>> {
  final Ref _ref; // Храним Ref для доступа к другим провайдерам

  SaleNotifier(this._ref) : super(const AsyncValue.data(null)); // Начальное состояние - нет активной операции

  Future<void> checkout(PaymentMethod paymentMethod) async {
    final cart = _ref.read(cartProvider);

    if (cart.items.isEmpty) {
      state = AsyncValue.error('Корзина пуста!', StackTrace.current);

      Future.delayed(const Duration(seconds: 3), () {
        if (state is AsyncError) state = const AsyncValue.data(null);
      });
      return;
    }

    state = const AsyncValue.loading();

    try {
      final db = _ref.read(databaseProvider);
      final saleId = await db.createSaleTransaction(cart.items, cart.totalPrice, paymentMethod);

      state = AsyncValue.data(saleId);
      _ref.read(cartProvider.notifier).clearCart();
      print('Sale created successfully with ID: $saleId, Method: ${paymentMethod.name}');
    } catch (error, stackTrace) {
      print('Checkout failed: $error'); // Логируем ошибку
      state = AsyncValue.error(error, stackTrace);

      Future.delayed(const Duration(seconds: 5), () {
        if (state is AsyncError) state = const AsyncValue.data(null);
      });
    }
  }

  // Метод для сброса состояния вручную (если нужно)
  void resetState() {
    state = const AsyncValue.data(null);
  }
}
