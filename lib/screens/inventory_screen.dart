import 'package:flutter/material.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/screens/products/product_form_screen.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart' show Debouncer;
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:flutter_pos/widgets/list_item_placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    // Добавляем слушателя к ScrollController для пагинации
    _scrollController.addListener(_onScroll);
    // Опционально: Первичная загрузка, если она не происходит в Notifier
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(productListProvider.notifier).refresh();
    // });
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
    // Проверяем, достигли ли конца списка
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      // Загружаем чуть заранее
      // Вызываем метод загрузки следующей страницы из Notifier'а
      ref.read(productListProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      ref.read(productListProvider.notifier).search(query);
    });
  }

  Future<void> _handleRefresh() async {
    // Сбрасываем поиск при рефреше (опционально)
    // _searchController.clear();
    await ref.read(productListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ProductListState productState = ref.watch(productListProvider);
    final List<Product> products = productState.products;
    final bool isLoadingInitial = productState.isLoading && products.isEmpty && productState.error == null;
    final bool isLoadingInBackground = productState.isLoading && products.isNotEmpty; // Для LinearProgressIndicator
    final bool hasError = productState.error != null && !productState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Остатки на складе'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
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
                                _onSearchChanged(''); // Выполняем пустой поиск
                              },
                            )
                            : null,
                    // Используем стиль из темы
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
            _buildInventoryList(context, productState, products, isLoadingInitial),

            // --- Отображение ошибки (только если список пуст) ---
            if (hasError && products.isEmpty) _buildErrorWidget(context, productState.error),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    ProductListState productState,
    List<Product> products,
    bool isLoadingInitial,
  ) {
    final theme = Theme.of(context);

    if (isLoadingInitial) {
      final Brightness currentBrightness = Theme.of(context).brightness;
      final Color baseColor = currentBrightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[300]!;
      final Color highlightColor = currentBrightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        enabled: true,
        child: ListView.builder(
          itemCount: 10, // Количество плейсхолдеров
          itemBuilder:
              (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                // Используем плейсхолдер, похожий на реальный ListTile остатков
                child: Card(child: InventoryListItemPlaceholder()), // \u003c--- Новый плейсхолдер
              ),
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
              Icon(
                productState.currentQuery != null && productState.currentQuery!.isNotEmpty
                    ? Icons
                        .search_off // Иконка "ничего не найдено"
                    : Icons.inventory_2_outlined, // Иконка "нет товаров"
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                productState.currentQuery != null && productState.currentQuery!.isNotEmpty
                    ? 'Товары по запросу "${productState.currentQuery}" не найдены.'
                    : 'Список товаров пуст.', // Сообщение для пустого инвентаря
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
        controller: _scrollController, // Для пагинации
        itemCount:
            products.length + (productState.isLoading && products.isNotEmpty ? 1 : 0), // +1 для индикатора пагинации
        padding: const EdgeInsets.only(bottom: 16, top: TSizes.sm), // Отступ снизу и сверху
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              indent: TSizes.md,
              endIndent: TSizes.md, // Отступы линии
              color: Colors.grey.shade300,
            ),
        itemBuilder: (context, index) {
          if (index == products.length) {
            if (productState.error != null && !productState.isLoading) {
              return _buildPaginationErrorWidget(context, productState.error);
            } else if (productState.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            } else {
              return const SizedBox.shrink(); // Больше нечего загружать
            }
          }

          final product = products[index];
          // Определяем стиль для количества
          Color quantityColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
          FontWeight quantityWeight = FontWeight.normal;
          if (product.quantity <= 0) {
            quantityColor = theme.colorScheme.error;
            quantityWeight = FontWeight.bold;
          } else if (product.quantity <= 5) {
            // Пример порога низкого остатка
            quantityColor = Colors.orange.shade800;
            quantityWeight = FontWeight.w500;
          }

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                  // Количество товара слева
                  leading: SizedBox(
                    width: 50,
                    child: Text(
                      product.quantity.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(color: quantityColor, fontWeight: quantityWeight),
                    ),
                  ),
                  title: Text(product.skuName, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    'ШК: ${product.barcode}\nАрт: ${product.skuCode}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), // Цвет подсказки
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 22,
                    color: theme.colorScheme.secondary,
                    tooltip: 'Редактировать товар',
                    onPressed: () => _navigateToProductForm(context, product),
                  ),
                  onTap: () => _navigateToProductForm(context, product),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToProductForm(BuildContext context, Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
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
}
