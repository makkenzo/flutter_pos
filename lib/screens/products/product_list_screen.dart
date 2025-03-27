import 'package:flutter/material.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/screens/pos/pos_screen.dart';
import 'package:flutter_pos/screens/products/product_form_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_pos/providers/product_providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                // Используем push для перехода
                context,
                MaterialPageRoute(builder: (_) => const PosScreen()), // Переходим на PosScreen
              );
            },
            icon: const Icon(Icons.point_of_sale),
          ),
        ],
      ),
      body: productListAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Нет товаров. Добавьте первый!'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Артикул: ${product.sku} | Остаток: ${product.quantity} шт.'),
                trailing: Text(currencyFormat.format(product.sellingPrice)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
                },
                onLongPress: () => _showDeleteConfirmation(context, ref, product),
              );
            },
          );
        },
        error: (error, stack) => Center(child: Text('Ошибка загрузки товаров: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Добавить товар',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Подтвердить удаление'),
          content: Text('Вы уверены, что хотите удалить товар ${product.name}?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await ref.read(productFormNotifierProvider.notifier).deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Товар "${product.name}" удален' : 'Ошибка удаления товара'),
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
  }
}
