import 'package:flutter_pos/main.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final saleNotifierProvider = StateNotifierProvider<SaleNotifier, AsyncValue<int?>>((ref) {
  return SaleNotifier(ref); // Передаем Ref для доступа к другим провайдерам
});

class SaleNotifier extends StateNotifier<AsyncValue<int?>> {
  final Ref _ref; // Храним Ref для доступа к другим провайдерам

  SaleNotifier(this._ref) : super(const AsyncValue.data(null)); // Начальное состояние - нет активной операции

  /// Метод оформления продажи
  Future<void> checkout() async {
    // Получаем текущее состояние корзины
    final cart = _ref.read(cartProvider); // Используем read, так как это одноразовое действие

    if (cart.items.isEmpty) {
      state = AsyncValue.error('Корзина пуста!', StackTrace.current);
      // Сбрасываем состояние обратно в data(null) через некоторое время,
      // чтобы пользователь мог снова нажать кнопку, если захочет (хотя она должна быть заблокирована)
      Future.delayed(const Duration(seconds: 3), () {
        if (state is AsyncError) state = const AsyncValue.data(null);
      });
      return;
    }

    // Устанавливаем состояние загрузки
    state = const AsyncValue.loading();

    try {
      // Вызываем метод транзакции из базы данных
      final db = _ref.read(databaseProvider);
      final saleId = await db.createSaleTransaction(cart.items, cart.totalPrice);

      // Успех!
      state = AsyncValue.data(saleId); // Сохраняем ID продажи в состоянии

      // Очищаем корзину ПОСЛЕ успешного завершения транзакции
      _ref.read(cartProvider.notifier).clearCart();

      print('Sale created successfully with ID: $saleId'); // Логируем успех

      // Можно добавить задержку перед сбросом состояния, чтобы UI успел показать успех
      // await Future.delayed(const Duration(seconds: 2));
      // state = const AsyncValue.data(null); // Сброс для следующей продажи (опционально)
    } catch (error, stackTrace) {
      // Ошибка (например, нехватка товара или ошибка БД)
      print('Checkout failed: $error'); // Логируем ошибку
      state = AsyncValue.error(error, stackTrace); // Устанавливаем состояние ошибки

      // Сбрасываем состояние обратно в data(null) через некоторое время
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
