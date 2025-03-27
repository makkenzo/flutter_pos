import 'package:flutter/material.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/main.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/providers/cart_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/providers/sale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

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
                        ? _buildTabletLayout(context, ref, cartState, currencyFormat, saleState.isLoading)
                        : _buildMobileLayout(context, ref, cartState, currencyFormat, saleState.isLoading),
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
        onPressed: () => _showBarcodeScannerDialog(context, ref),
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

  PreferredSizeWidget _buildTabBar(BuildContext context, CartState cartState) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
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
    WidgetRef ref,
    CartState cartState,
    NumberFormat currencyFormat,
    bool isCheckoutLoading,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildProductSelection(context, ref)),
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
                      behavior: SnackBarBehavior.floating,
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

  Future<void> _processScannedBarcode(BuildContext context, WidgetRef ref, String barcodeValue) async {
    if (barcodeValue.isEmpty) return;

    final db = ref.read(databaseProvider);
    final product = await db.getProductBySku(barcodeValue);

    if (!context.mounted) return;

    if (product != null) {
      if (product.quantity > 0) {
        ref.read(cartProvider.notifier).addItem(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${product.name}" добавлен в корзину'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "${product.name}" (${product.sku}) закончился на складе'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар со штрих-кодом "$barcodeValue" не найден'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showBarcodeScannerDialog(BuildContext context, WidgetRef ref) async {
    final String? scannedValue = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const _BarcodeScannerDialog(),
    );

    if (scannedValue != null && scannedValue.isNotEmpty && context.mounted) {
      await _processScannedBarcode(context, ref, scannedValue);
    } else if (scannedValue == null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сканирование отменено'), duration: Duration(seconds: 2)));
    }
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
                icon: widget.isCheckoutLoading ? Container(/* ... Индикатор ... */) : const Icon(Icons.payment),
                label: Text(widget.isCheckoutLoading ? 'Оформление...' : 'Оформить продажу'),
                style: ElevatedButton.styleFrom(/* ... Стили ... */),

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

class _BarcodeScannerDialog extends ConsumerStatefulWidget {
  const _BarcodeScannerDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends ConsumerState<_BarcodeScannerDialog> {
  final MobileScannerController controller = MobileScannerController(facing: CameraFacing.back);
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.6;
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return AlertDialog(
      title: const Text('Сканировать штрих-код'),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.all(10),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              scanWindow: scanWindow,
              onDetect: (capture) {
                if (_isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                String? scannedValue;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                    scannedValue = barcode.rawValue;
                    break;
                  }
                }

                if (scannedValue != null) {
                  setState(() {
                    _isProcessing = true;
                  });
                  print('Barcode found! $scannedValue');

                  Navigator.of(context).pop(scannedValue);
                } else {
                  print('Detected barcode with empty value.');
                }
              },

              errorBuilder: (context, error, child) {
                print('Scanner Error: $error');

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ошибка сканера:\n${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),

            CustomPaint(size: Size.infinite, painter: ScannerOverlayPainter(scanWindow: scanWindow)),

            Positioned(
              bottom: 20,
              left: 20,
              child: IconButton(
                color: Colors.white,
                iconSize: 32.0,
                icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                tooltip: 'Фонарик',
                onPressed: () async {
                  try {
                    await controller.toggleTorch();

                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  } catch (e) {
                    print("Failed to toggle torch: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Не удалось переключить фонарик: $e')));
                    }
                  }
                },
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: IconButton(
                color: Colors.white,
                iconSize: 32.0,
                icon: const Icon(Icons.cameraswitch),
                tooltip: 'Сменить камеру',
                onPressed: () async {
                  try {
                    await controller.switchCamera();
                  } catch (e) {
                    print("Failed to switch camera: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Не удалось сменить камеру: $e')));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop())],
    );
  }
}

// ===========================================================================
// (Опционально) Вспомогательный Painter для рамки сканирования
// ===========================================================================
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({required this.scanWindow, this.borderRadius = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndCorners(
            scanWindow,
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
        );

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);

    final backgroundPathCutout = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(backgroundPathCutout, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        scanWindow,
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
