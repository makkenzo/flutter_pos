import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final saleNotifierProvider = StateNotifierProvider<SaleNotifier, AsyncValue<String?>>((ref) {
  return SaleNotifier(ref);
});

class SaleNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  SaleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> checkout(PaymentMethod paymentMethod) async {
    final cart = _ref.read(cartProvider);
    if (cart.items.isEmpty) {
      state = AsyncValue.error('Корзина пуста!', StackTrace.current);
      _resetStateAfterDelay();
      return;
    }

    state = const AsyncValue.loading();

    try {
      final apiService = _ref.read(apiServiceProvider);
      // --- ИЗМЕНЕНО: Получаем orderId (String) ---
      final String createdOrderId = await apiService.createSale(cart.items, cart.totalPrice, paymentMethod);
      // -------------------------------------------

      // --- ИЗМЕНЕНО: Сохраняем orderId в состоянии ---
      state = AsyncValue.data(createdOrderId);
      // ----------------------------------------------

      _ref.read(cartProvider.notifier).clearCart();

      // Опционально: Сброс состояния
      // _resetStateAfterDelay();
    } on UnauthorizedException catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _ref.read(authProvider.notifier).logout();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _resetStateAfterDelay();
    }
  }

  void resetState() {
    if (state is! AsyncLoading) {
      state = const AsyncValue.data(null);
    }
  }

  void _resetStateAfterDelay([Duration duration = const Duration(seconds: 5)]) {
    Future.delayed(duration, () {
      resetState();
    });
  }
}
