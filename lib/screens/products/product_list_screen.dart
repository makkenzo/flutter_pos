import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/screens/pos/pos_screen.dart';
import 'package:flutter_pos/screens/products/product_form_screen.dart';
import 'package:flutter_pos/screens/sales/sales_history_screen.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      ref.read(productListProvider.notifier).search(query);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(productListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ProductListState productState = ref.watch(productListProvider);
    final List<Product> products = productState.products;
    final bool isLoadingInitial = productState.isLoading && products.isEmpty && productState.error == null;
    final bool isLoadingMore = productState.isLoading && products.isNotEmpty;
    final bool hasError = productState.error != null && !productState.isLoading;
    final bool canLoadMore = !productState.isLoading && !productState.hasReachedMax;

    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История продаж',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            tooltip: 'Касса',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Подтверждение выхода'),
                      content: const Text('Вы уверены, что хотите выйти из системы?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию, SKU, штрих-коду...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Очистить поиск',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            _buildBodyContent(context, productState, products, isLoadingInitial, currencyFormat),

            if (hasError && products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Ошибка загрузки товаров:\n${_formatErrorMessage(productState.error)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _handleRefresh, child: const Text('Повторить')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Добавить товар',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: null)));
        },
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    ProductListState productState,
    List<Product> products,
    bool isLoadingInitial,
    NumberFormat currencyFormat,
  ) {
    if (isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty && !productState.isLoading && productState.error == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            productState.currentQuery != null && productState.currentQuery!.isNotEmpty
                ? 'Товары по запросу "${productState.currentQuery}" не найдены.'
                : 'Нет добавленных товаров.\nНажмите "+", чтобы добавить первый.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: products.length + (productState.isLoading ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(product.skuName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              'ШК: ${product.barcode}\nОстаток: ${product.quantity} ${product.unit}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
            },
            onLongPress: () => _showDeleteConfirmation(context, product),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (context, dialogRef, child) {
            return AlertDialog(
              title: const Text('Подтвердить удаление'),
              content: Text('Вы уверены, что хотите удалить товар "${product.skuName}" (ID: ${product.id})?'),
              actions: <Widget>[
                TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(ctx).pop()),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Удалить'),

                  onPressed: () async {
                    Navigator.of(ctx).pop();

                    final success = await dialogRef
                        .read(productFormNotifierProvider.notifier)
                        .deleteProduct(product.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Товар "${product.skuName}" удален' : 'Ошибка удаления товара'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatErrorMessage(Object? error) {
    if (error == null) return 'Неизвестная ошибка';
    if (error is HttpException) {
      return error.message;
    }

    return error.toString();
  }
}
