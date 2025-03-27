import 'package:drift/drift.dart' hide Column;
import 'package:flutter_pos/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos/database/database.dart';

final productListProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllProducts();
});

final productFormNotifierProvider = StateNotifierProvider<ProductFormNotifier, AsyncValue<void>>((ref) {
  return ProductFormNotifier(ref.read(databaseProvider));
});

class ProductFormNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  ProductFormNotifier(this._db) : super(const AsyncValue.data(null));

  Future<bool> addProduct({
    required String name,
    required String sku,
    String? description,
    double? purchasePrice,
    required double sellingPrice,
    required int quantity,
  }) async {
    state = const AsyncValue.loading();

    try {
      final companion = ProductsCompanion.insert(
        name: name,
        sku: sku,
        description: Value(description),
        purchasePrice: Value(purchasePrice),
        sellingPrice: sellingPrice,
        quantity: quantity,
      );
      await _db.insertProduct(companion);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('Error adding product: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(
    Product existingProduct, {
    required String name,
    required String sku,
    String? description,
    double? purchasePrice,
    required double sellingPrice,
    required int quantity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final companion = ProductsCompanion(
        id: Value(existingProduct.id),
        name: Value(name),
        sku: Value(sku),
        description: Value(description),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        quantity: Value(quantity),
      );
      await _db.updateProduct(companion);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('Error updating product: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteProduct(productId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('Error deleting product: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
