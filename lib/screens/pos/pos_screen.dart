import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/providers/sale_provider.dart';
import 'package:flutter_pos/screens/products/product_form_screen.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/widgets/barcode_scanner_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:intl/intl.dart';
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
    if (!context.mounted || barcodeValue.isEmpty) return;
    print("Processing scanned barcode: $barcodeValue");

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 10), Text("Поиск товара...")],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final Product? product = await apiService.getProductByBarcode(barcodeValue);

      if (!context.mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();

      if (product == null) {
        print("Product not found globally. Navigating to create form.");
        await _navigateToProductForm(barcodeValue: barcodeValue);
      } else {
        print("Product found globally: ${product.skuName}, Quantity: ${product.quantity}");
        if (product.quantity > 0) {
          print("Product is LOCAL. Adding to cart.");
          _addProductToCart(product);
        } else {
          print("Product is GLOBAL-ONLY. Navigating to create form with prefill.");
          await _navigateToProductForm(product: product);
        }
      }
    } on UnauthorizedException catch (e) {
      print("Unauthorized during barcode processing: $e");
      if (!context.mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Ошибка авторизации: $e"), backgroundColor: Colors.red));
      ref.read(authProvider.notifier).logout();
    } catch (e) {
      print("Error processing barcode $barcodeValue: $e");
      if (!context.mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Ошибка при поиске товара: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _navigateToProductForm({Product? product, String? barcodeValue}) async {
    if (!context.mounted) return;

    final Product productToEdit =
        product ??
        Product(
          id: 0,
          skuCode: '',
          barcode: barcodeValue ?? '',
          unit: 'шт',
          skuName: '',
          status1c: '',
          department: '',
          groupName: '',
          subgroup: '',
          supplier: '',
          costPrice: 0.0,
          price: 0.0,
          quantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          product == null
              ? 'Товар с ШК $barcodeValue не найден. Создайте его.'
              : 'Товар \"${product.skuName}\" нужно добавить в ваш каталог. Заполните данные.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    final createdProduct = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: productToEdit)),
    );

    if (createdProduct != null && context.mounted) {
      print("Product created via form: ${createdProduct.skuName}. Adding to cart.");
      _addProductToCart(createdProduct);
    } else {
      print("Product creation cancelled or failed.");
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оформления: ${state.error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (state.hasValue && state.value != null) {
        final String orderId = state.value!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Продажа (Заказ № $orderId) успешно оформлена!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        ref.read(saleNotifierProvider.notifier).resetState();
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

  Widget _buildPaginationErrorWidget(BuildContext context, Object? error) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'Не удалось загрузить еще:\n${formatErrorMessage(error)}', // Используем форматтер
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            // Используем TextButton для компактности
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Повторить'),
            onPressed: () {
              // Вызываем загрузку СЛЕДУЮЩЕЙ страницы (не refresh всего списка)
              ref.read(productListProvider.notifier).fetchNextPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelection() {
    final ProductListState productState = ref.watch(productListProvider);
    final List<Product> products = productState.products;
    final bool isLoadingInitial = productState.isLoading && products.isEmpty && productState.error == null;
    final bool isLoadingMore = productState.isLoading && products.isNotEmpty;
    final bool hasError = productState.error != null && !productState.isLoading;
    final bool isLoadingInBackground = productState.isLoading && productState.products.isNotEmpty;

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
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (isLoadingInBackground) const LinearProgressIndicator(minHeight: 2),
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
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      // Если есть ошибка и мы не грузим следующую страницу
                      if (productState.error != null && !productState.isLoading) {
                        return _buildPaginationErrorWidget(context, productState.error); // Показываем виджет ошибки
                      }
                      // Если ошибки нет, но идет загрузка - показываем индикатор
                      else if (productState.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      // Иначе (нет ошибки, не идет загрузка, но сюда дошли - например, hasReachedMax) - ничего не показываем
                      else {
                        return const SizedBox.shrink();
                      }
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
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: inStock ? 3.0 : 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: inStock ? () => _addProductToCart(product) : null,
        child: Opacity(
          opacity: inStock ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.skuName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),

                Text(
                  'Остаток: ${product.quantity} ${product.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: inStock ? theme.colorScheme.primary : theme.disabledColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,

                  foregroundColor: Theme.of(context).colorScheme.onPrimary,

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                  minimumSize: const Size(double.infinity, 50),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Theme.of(context).colorScheme.primary.withOpacity(0.5);
                    }

                    return null;
                  }),
                ),

                icon:
                    widget.isCheckoutLoading
                        ? Container(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,

                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.payment, size: 22),

                label: Text(widget.isCheckoutLoading ? 'ОФОРМЛЕНИЕ...' : 'ОФОРМИТЬ ПРОДАЖУ'),

                onPressed:
                    items.isEmpty || widget.isCheckoutLoading
                        ? null
                        : () {
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

  Future<void> _showQuantityEditDialog(CartItem item) async {
    final TextEditingController qtyController = TextEditingController(text: item.quantity.toString());
    int currentQty = item.quantity;

    final int? newQuantity = await showDialog<int?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Изменить количество', style: Theme.of(context).textTheme.titleLarge),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    tooltip: 'Уменьшить',
                    onPressed:
                        currentQty <= 1
                            ? null
                            : () {
                              if (currentQty > 1) {
                                setStateDialog(() {
                                  currentQty--;
                                  qtyController.text = currentQty.toString();
                                });
                              }
                            },
                  ),
                  const SizedBox(width: TSizes.sm),

                  Expanded(
                    child: SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: qtyController,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: TSizes.xs),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                        onChanged: (value) {
                          setStateDialog(() {
                            currentQty = int.tryParse(value) ?? currentQty;
                          });
                        },

                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          final intValue = int.tryParse(value ?? '');
                          if (intValue == null || intValue <= 0) {
                            return '!\u003e0';
                          }

                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.sm),

                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: 'Увеличить',
                    onPressed: () {
                      setStateDialog(() {
                        currentQty++;
                        qtyController.text = currentQty.toString();
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
              actions: <Widget>[
                TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(dialogContext).pop(null)),

                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: qtyController,
                  builder: (context, value, child) {
                    final isValid = (int.tryParse(value.text) ?? 0) > 0;
                    return TextButton(
                      onPressed:
                          !isValid
                              ? null
                              : () {
                                final qty = int.tryParse(qtyController.text);
                                if (qty != null && qty > 0) {
                                  Navigator.of(dialogContext).pop(qty);
                                } else {
                                  Navigator.of(dialogContext).pop(null);
                                }
                              },
                      child: const Text('Сохранить'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (newQuantity != null && newQuantity > 0) {
      ref.read(cartProvider.notifier).setQuantity(item.barcode, newQuantity);
    } else if (newQuantity != null && newQuantity <= 0) {
      ref.read(cartProvider.notifier).removeItem(item.barcode);
    }
  }

  Widget _buildCartItemTile(BuildContext context, WidgetRef ref, CartItem item, NumberFormat currencyFormat) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 0),
      dense: true,
      title: Text(item.name, style: theme.textTheme.bodyMedium),
      subtitle: Text('${currencyFormat.format(item.priceAtSale)} / шт.', style: theme.textTheme.bodySmall),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.orange.shade700,
            iconSize: 24,
            padding: EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Уменьшить',
            onPressed: () {
              ref.read(cartProvider.notifier).decrementQuantity(item.barcode);
            },
          ),
          InkWell(
            onTap: () => _showQuantityEditDialog(item),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                item.quantity.toString(),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.green.shade700,
            iconSize: 24,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Увеличить',
            onPressed: () => ref.read(cartProvider.notifier).incrementQuantity(item.barcode),
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
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: TSizes.xs),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            iconSize: 22,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Удалить из корзины',
            onPressed: () => ref.read(cartProvider.notifier).removeItem(item.barcode),
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
