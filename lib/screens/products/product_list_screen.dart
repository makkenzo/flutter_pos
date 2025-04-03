import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/screens/pos/pos_screen.dart';
import 'package:flutter_pos/screens/products/product_form_screen.dart';
import 'package:flutter_pos/screens/sales/sales_history_screen.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:flutter_pos/widgets/list_item_placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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

    final bool hasError = productState.error != null && !productState.isLoading;
    final bool isLoadingInBackground = productState.isLoading && products.isNotEmpty;
    final bool isLoadingInitial = productState.isLoading && products.isEmpty && productState.error == null;

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
          preferredSize: const Size.fromHeight(TSizes.appBarHeight + 4),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
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
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(vertical: TSizes.xs),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (isLoadingInBackground) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            _buildBodyContent(context, productState, products, isLoadingInitial, currencyFormat),
            if (hasError && products.isEmpty) _buildErrorWidget(context, productState.error),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить товар',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: null)));
        },
        child: const Icon(Icons.add),
      ),
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

  Widget _buildBodyContent(
    BuildContext context,
    ProductListState productState,
    List<Product> products,
    bool isLoadingInitial,
    NumberFormat currencyFormat,
  ) {
    if (isLoadingInitial) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        enabled: true,
        child: ListView.builder(
          itemBuilder:
              (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                child: Card(child: ProductListItemPlaceholder()),
              ),
          itemCount: 10,
        ),
      );
    }

    if (products.isEmpty && !productState.isLoading && productState.error == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                productState.currentQuery != null && productState.currentQuery!.isNotEmpty
                    ? 'Товары по запросу "${productState.currentQuery}" не найдены.'
                    : 'Нет добавленных товаров.\nНажмите "+", чтобы добавить первый.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.separated(
        controller: _scrollController,
        itemCount: products.length + (productState.isLoading && products.isNotEmpty ? 1 : 0),
        padding: const EdgeInsets.only(bottom: 80, top: TSizes.sm),
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              indent: TSizes.md,
              endIndent: TSizes.md,
              color: Colors.grey.shade300,
            ),
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
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
                  title: Text(product.skuName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'ШК: ${product.barcode}\nОстаток: ${product.quantity} ${product.unit}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: TSizes.sm),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 60), // Иконка ошибки сети/сервера
            const SizedBox(height: 16),
            Text(
              'Ошибка: ${formatErrorMessage(error)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 15), // Чуть крупнее
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              // Кнопка Повторить
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              onPressed: _handleRefresh,
            ),
          ],
        ),
      ),
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
}
