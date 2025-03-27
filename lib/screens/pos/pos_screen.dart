import 'package:flutter/material.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/providers/sale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  // Точка перелома для определения, какой layout использовать
  static const double _tabletBreakpoint = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<int?>>(saleNotifierProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оформления: ${state.error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (state.hasValue && state.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Продажа №${state.value} успешно оформлена'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(saleNotifierProvider.notifier).resetState();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= _tabletBreakpoint;

        return DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) {
              final cartState = ref.watch(cartProvider);
              final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');

              final saleState = ref.watch(saleNotifierProvider);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Касса / Продажа'),
                  actions: _buildAppBarActions(context, ref, cartState, currencyFormat, isTablet, tabContext),

                  bottom: isTablet ? null : _buildTabBar(context, cartState),
                ),
                body:
                    isTablet
                        ? _buildTabletLayout(
                          context,
                          ref,
                          cartState,
                          currencyFormat,
                          saleState.isLoading,
                        ) // Широкий экран
                        : _buildMobileLayout(
                          context,
                          ref,
                          cartState,
                          currencyFormat,
                          saleState.isLoading,
                        ), // Узкий экран (TabBarView)
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isTablet,
    BuildContext tabContext,
  ) {
    return [
      IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        tooltip: 'Сканировать штрих-код',
        onPressed: () {
          // TODO: Реализовать сканирование штрих-кода (Шаг 9)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сканер еще не реализован')));
        },
      ),
      if (isTablet)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              'Итого: ${currencyFormat.format(cartState.totalPrice)} (${cartState.totalItemsCount} шт.)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Badge(
            // Виджет Badge для отображения количества
            label: Text(cartState.totalItemsCount.toString()),
            isLabelVisible: cartState.totalItemsCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Перейти в корзину',
              onPressed: () {
                // Переключаемся на вторую вкладку (Корзина)
                final controller = DefaultTabController.of(tabContext);
                controller.animateTo(1);
              },
            ),
          ),
        ),
    ];
  }

  // ===========================================================================
  // TabBar (только для мобильного вида)
  // ===========================================================================
  PreferredSizeWidget _buildTabBar(BuildContext context, CartState cartState) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    return TabBar(
      tabs: [
        const Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Товары'),
        Tab(
          // Добавляем бейдж на иконку корзины
          icon: Badge(
            label: Text(cartState.totalItemsCount.toString()),
            isLabelVisible: cartState.totalItemsCount > 0,
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          // Показываем сумму на вкладке корзины
          text: 'Корзина (${currencyFormat.format(cartState.totalPrice)})',
        ),
      ],
    );
  }

  // ===========================================================================
  // Layout для широких экранов (планшет/ландшафт) - ИСПОЛЬЗУЕТ ROW
  // ===========================================================================
  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isCheckoutLoading,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Область выбора товаров ---
        Expanded(flex: 2, child: _buildProductSelection(context, ref)),
        const VerticalDivider(width: 1, thickness: 1),
        // --- 2. Область корзины ---
        Expanded(
          flex: 1,
          child: _CartViewWidget(
            cartState: cartState,
            currencyFormat: currencyFormat,
            isCheckoutLoading: isCheckoutLoading,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Layout для узких экранов (телефон/портрет) - ИСПОЛЬЗУЕТ TABBARVIEW
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isCheckoutLoading,
  ) {
    return TabBarView(
      children: [
        _buildProductSelection(context, ref),
        _CartViewWidget(cartState: cartState, currencyFormat: currencyFormat, isCheckoutLoading: isCheckoutLoading),
      ],
    );
  }

  // ===========================================================================
  // Метод для построения области выбора товаров (БЕЗ ИЗМЕНЕНИЙ)
  // ===========================================================================
  Widget _buildProductSelection(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск товара по названию или SKU...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onChanged: (value) {
              /* TODO: Поиск */
            },
          ),
        ),
        Expanded(
          child: productListAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('Нет доступных товаров'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 2 / 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductTile(context, ref, product);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Ошибка загрузки товаров: $error')),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Виджет для отображения одного товара в сетке
  // ===========================================================================
  Widget _buildProductTile(BuildContext context, WidgetRef ref, Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    bool inStock = product.quantity > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      child: InkWell(
        onTap:
            inStock
                ? () {
                  ref.read(cartProvider.notifier).addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${product.name}" добавлен в корзину'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating, // Улучшение для мобильных
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
                : null,
        child: Opacity(
          opacity: inStock ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.sku}\nОстаток: ${product.quantity} шт.',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    currencyFormat.format(product.sellingPrice),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!inStock)
                  const Align(
                    alignment: Alignment.center,
                    child: Text('Нет в наличии', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartViewWidget extends ConsumerStatefulWidget {
  final CartState cartState;
  final NumberFormat currencyFormat;
  final bool isCheckoutLoading;

  const _CartViewWidget({
    required this.cartState,
    required this.currencyFormat,
    required this.isCheckoutLoading,
    // Key? key не нужен здесь, если не используется явно
  }); // Убран key

  @override
  ConsumerState<_CartViewWidget> createState() => _CartViewWidgetState();
}

class _CartViewWidgetState extends ConsumerState<_CartViewWidget> {
  // Локальное состояние для хранения выбранного метода оплаты
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash; // По умолчанию - наличные

  @override
  Widget build(BuildContext context) {
    final items = widget.cartState.items; // Доступ к параметрам через widget

    return Column(
      children: [
        // --- Список товаров в корзине (без изменений) ---
        Expanded(
          child:
              items.isEmpty
                  ? const Center(/* ... */)
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // Передаем ref явно в _buildCartItemTile
                      return _buildCartItemTile(context, ref, item, widget.currencyFormat);
                    },
                  ),
        ),
        const Divider(),

        // --- Итоговая информация, ВЫБОР МЕТОДА ОПЛАТЫ и кнопка оформления ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Уменьшен верхний отступ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Выбор метода оплаты ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Метод оплаты:', style: Theme.of(context).textTheme.titleSmall),
              ),
              // Используем Column для RadioListTile
              Column(
                mainAxisSize: MainAxisSize.min, // Занимать минимум места
                children:
                    PaymentMethod.values.map((method) {
                      return RadioListTile<PaymentMethod>(
                        title: Text(method.displayTitle),
                        value: method,
                        groupValue: _selectedPaymentMethod,
                        onChanged:
                            widget.isCheckoutLoading
                                ? null
                                : (PaymentMethod? value) {
                                  // Блокируем во время загрузки
                                  if (value != null) {
                                    setState(() {
                                      _selectedPaymentMethod = value;
                                    });
                                  }
                                },
                        dense: true, // Делаем компактнее
                        contentPadding: EdgeInsets.zero, // Убираем лишние отступы
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16), // Отступ перед итоговой суммой
              // --- Итоговая сумма (без изменений) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого:', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    widget.currencyFormat.format(widget.cartState.totalPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Кнопка Оформить продажу (передаем выбранный метод) ---
              ElevatedButton.icon(
                icon: widget.isCheckoutLoading ? Container(/* ... Индикатор ... */) : const Icon(Icons.payment),
                label: Text(widget.isCheckoutLoading ? 'Оформление...' : 'Оформить продажу'),
                style: ElevatedButton.styleFrom(/* ... Стили ... */),
                // Передаем _selectedPaymentMethod в checkout()
                onPressed:
                    items.isEmpty || widget.isCheckoutLoading
                        ? null
                        : () {
                          ref
                              .read(saleNotifierProvider.notifier)
                              .checkout(_selectedPaymentMethod); // <--- ПЕРЕДАЕМ МЕТОД
                        },
              ),

              // --- Кнопка очистки корзины (без изменений) ---
              if (items.isNotEmpty && !widget.isCheckoutLoading) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
                  label: const Text('Очистить корзину'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showClearCartConfirmation(context, ref), // Передаем ref
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemTile(BuildContext context, WidgetRef ref, CartItem item, NumberFormat currencyFormat) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('${currencyFormat.format(item.priceAtSale)} / шт.'),
      // Управление количеством
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Уменьшить',
            onPressed: () {
              ref.read(cartProvider.notifier).decrementQuantity(item.sku);
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Увеличить',
            onPressed: () {
              ref.read(cartProvider.notifier).incrementQuantity(item.sku);
              // Важно: Здесь мы не проверяем остаток! Проверка будет при оформлении.
            },
          ),
        ],
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              currencyFormat.format(item.itemTotal),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Удалить из корзины',
            onPressed: () {
              ref.read(cartProvider.notifier).removeItem(item.sku);
            },
          ),
        ],
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Очистить корзину?'),
          content: const Text('Вы уверены...?'),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Очистить'),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
          ],
        );
      },
    );
  }
}
