import 'package:flutter/material.dart';
import 'package:flutter_pos/main.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/providers/sale_provider.dart';
import 'package:flutter_pos/widgets/barcode_scanner_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart' show Debouncer;

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  static const double _tabletBreakpoint = 720.0;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final ScrollController _productScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _productScrollController.addListener(_onProductScroll);
  }

  @override
  void dispose() {
    _productScrollController.removeListener(_onProductScroll);
    _productScrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onProductScroll() {
    if (_productScrollController.position.pixels >= _productScrollController.position.maxScrollExtent - 300) {
      ref.read(productListProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      ref.read(productListProvider.notifier).search(query);
    });
  }

  Future<void> _handleProductsRefresh() async {
    await ref.read(productListProvider.notifier).refresh();
  }

  Future<void> _showBarcodeScannerDialog() async {
    final String? scannedValue = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const BarcodeScannerDialog(),
    );

    if (scannedValue != null && scannedValue.isNotEmpty && context.mounted) {
      await _processScannedBarcode(scannedValue);
    } else if (scannedValue == null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сканирование отменено'), duration: Duration(seconds: 2)));
    }
  }

  Future<void> _processScannedBarcode(String barcodeValue) async {
    if (!context.mounted) return;
    print("Processing scanned barcode: $barcodeValue");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 10), Text("Поиск товара...")],
        ),
        duration: Duration(seconds: 5),
      ),
    );

    try {
      final Product? product = await ref.read(productByBarcodeProvider(barcodeValue).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (product != null) {
        _addProductToCart(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар со штрих-кодом "$barcodeValue" не найден'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Error processing barcode $barcodeValue: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при поиске товара: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _addProductToCart(Product product) {
    try {
      ref.read(cartProvider.notifier).addItem(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.skuName}" добавлен в корзину'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось добавить: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String?>>(saleNotifierProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        // Обработка ошибки (без изменений)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оформления: ${state.error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (state.hasValue && state.value != null) {
        // --- Успешное оформление ---
        final String orderId = state.value!; // Получаем orderId из состояния
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Используем orderId в сообщении
            content: Text('Продажа (Заказ № $orderId) успешно оформлена!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Сбрасываем состояние saleNotifier для следующей продажи
        ref.read(saleNotifierProvider.notifier).resetState();
        // ---------------------------
      }
    });

    final cartState = ref.watch(cartProvider);
    final saleState = ref.watch(saleNotifierProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= PosScreen._tabletBreakpoint;

        return DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Касса / Продажа'),
                  actions: _buildAppBarActions(context, cartState, currencyFormat, isTablet, tabContext),
                  bottom: isTablet ? null : _buildTabBar(context, cartState, currencyFormat),
                ),
                body:
                    isTablet
                        ? _buildTabletLayout(context, cartState, currencyFormat, saleState.isLoading)
                        : _buildMobileLayout(context, cartState, currencyFormat, saleState.isLoading),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isTablet,
    BuildContext tabContext,
  ) {
    return [
      IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        tooltip: 'Сканировать штрих-код',
        onPressed: _showBarcodeScannerDialog,
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
            label: Text(cartState.totalItemsCount.toString()),
            isLabelVisible: cartState.totalItemsCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Перейти в корзину',
              onPressed: () {
                final controller = DefaultTabController.of(tabContext);
                controller.animateTo(1);
              },
            ),
          ),
        ),
    ];
  }

  PreferredSizeWidget _buildTabBar(BuildContext context, CartState cartState, NumberFormat currencyFormat) {
    return TabBar(
      tabs: [
        const Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Товары'),
        Tab(
          icon: Badge(
            label: Text(cartState.totalItemsCount.toString()),
            isLabelVisible: cartState.totalItemsCount > 0,
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          text: 'Корзина (${currencyFormat.format(cartState.totalPrice)})',
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isCheckoutLoading,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildProductSelection()),
        const VerticalDivider(width: 1, thickness: 1),
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

  Widget _buildMobileLayout(
    BuildContext context,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isCheckoutLoading,
  ) {
    return TabBarView(
      children: [
        _buildProductSelection(),
        _CartViewWidget(cartState: cartState, currencyFormat: currencyFormat, isCheckoutLoading: isCheckoutLoading),
      ],
    );
  }

  Widget _buildProductSelection() {
    final ProductListState productState = ref.watch(productListProvider);
    final List<Product> products = productState.products;
    final bool isLoadingInitial = productState.isLoading && products.isEmpty && productState.error == null;
    final bool isLoadingMore = productState.isLoading && products.isNotEmpty;
    final bool hasError = productState.error != null && !productState.isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск товара...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleProductsRefresh,
            child: Builder(
              builder: (context) {
                if (isLoadingInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (hasError && products.isEmpty) {
                  return Center(child: Text('Ошибка: ${productState.error}'));
                }
                if (products.isEmpty && !productState.isLoading) {
                  return Center(
                    child: Text(
                      productState.currentQuery != null && productState.currentQuery!.isNotEmpty
                          ? 'Товары не найдены'
                          : 'Нет товаров для продажи',
                    ),
                  );
                }

                return GridView.builder(
                  controller: _productScrollController,
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 2 / 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    final product = products[index];
                    return _buildProductTile(product);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTile(Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    bool inStock = product.quantity > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      child: InkWell(
        onTap: inStock ? () => _addProductToCart(product) : null,

        child: Opacity(
          opacity: inStock ? 1.0 : 0.4,
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              title: Text(
                currencyFormat.format(product.price),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              trailing:
                  inStock ? null : const Icon(Icons.remove_shopping_cart_outlined, size: 18, color: Colors.white70),
            ),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.skuName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    'ШК: ${product.barcode}\nОст: ${product.quantity} ${product.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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

  const _CartViewWidget({required this.cartState, required this.currencyFormat, required this.isCheckoutLoading});

  @override
  ConsumerState<_CartViewWidget> createState() => _CartViewWidgetState();
}

class _CartViewWidgetState extends ConsumerState<_CartViewWidget> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final items = widget.cartState.items;

    return Column(
      children: [
        Expanded(
          child:
              items.isEmpty
                  ? const Center(/* ... */)
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _buildCartItemTile(context, ref, item, widget.currencyFormat);
                    },
                  ),
        ),
        const Divider(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Метод оплаты:', style: Theme.of(context).textTheme.titleSmall),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
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
                                  if (value != null) {
                                    setState(() {
                                      _selectedPaymentMethod = value;
                                    });
                                  }
                                },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

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

              ElevatedButton.icon(
                // --- СТИЛИ КНОПКИ ---
                style: ElevatedButton.styleFrom(
                  // Задаем основной цвет фона из темы
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  // Задаем основной цвет текста/иконки из темы
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  // Вертикальный отступ
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  // Стиль текста
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  // Скругление углов
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  // Минимальный размер (опционально, чтобы кнопка не была слишком маленькой)
                  minimumSize: const Size(double.infinity, 50), // Занимает всю ширину
                ).copyWith(
                  // Переопределяем цвет фона для состояния disabled (когда isLoading или корзина пуста)
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      // Используем основной цвет, но с меньшей прозрачностью
                      return Theme.of(context).colorScheme.primary.withOpacity(0.5);
                    }
                    // Для всех остальных состояний (enabled, pressed, hovered)
                    // возвращаем null, чтобы использовался backgroundColor из styleFrom
                    return null;
                  }),
                  // Можно также изменить цвет текста/иконки для disabled, если нужно
                  // foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                  //   (Set<MaterialState> states) {
                  //     if (states.contains(MaterialState.disabled)) {
                  //       return Theme.of(context).colorScheme.onPrimary.withOpacity(0.7);
                  //     }
                  //     return null; // Используем основной foregroundColor
                  //   },
                  // ),
                ),

                // --- ИКОНКА / ИНДИКАТОР ЗАГРУЗКИ ---
                icon:
                    widget.isCheckoutLoading
                        ? Container(
                          // Показываем индикатор, если isCheckoutLoading == true
                          width: 20, // Задаем размер контейнера для индикатора
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, // Толщина линии индикатора
                            // Цвет индикатора должен контрастировать с фоном кнопки (primary)
                            // Обычно onPrimary (белый) подходит
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.payment, size: 22), // Иконка по умолчанию
                // --- ТЕКСТ КНОПКИ ---
                label: Text(widget.isCheckoutLoading ? 'ОФОРМЛЕНИЕ...' : 'ОФОРМИТЬ ПРОДАЖУ'),

                // --- ОБРАБОТЧИК НАЖАТИЯ ---
                // Кнопка заблокирована (onPressed = null), если:
                // 1. Корзина пуста (items.isEmpty)
                // 2. Идет процесс оформления (widget.isCheckoutLoading)
                onPressed:
                    items.isEmpty || widget.isCheckoutLoading
                        ? null // Кнопка заблокирована
                        : () {
                          // Вызываем метод checkout из SaleNotifier, передавая выбранный метод оплаты
                          ref.read(saleNotifierProvider.notifier).checkout(_selectedPaymentMethod);
                        },
              ),

              if (items.isNotEmpty && !widget.isCheckoutLoading) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
                  label: const Text('Очистить корзину'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showClearCartConfirmation(context, ref),
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
              ref.read(cartProvider.notifier).decrementQuantity(item.barcode);
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
              ref.read(cartProvider.notifier).incrementQuantity(item.barcode);
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
              ref.read(cartProvider.notifier).removeItem(item.barcode);
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
