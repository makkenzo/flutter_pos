import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_pos/models/product.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Products, Sales, SaleItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  Stream<List<Product>> watchAllProducts() => select(products).watch();
  Future<Product?> getProductById(int id) => (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<Product?> getProductBySku(String sku) =>
      (select(products)..where((tbl) => tbl.sku.equals(sku))).getSingleOrNull();
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);
  Future<bool> updateProduct(ProductsCompanion product) => update(products).replace(product);
  Future<int> deleteProduct(int id) => (delete(products)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> _updateStockInTransaction(int productId, int change) async {
    final currentProduct = await (select(products)..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();

    if (currentProduct != null) {
      final newQuantity = currentProduct.quantity + change;

      if (newQuantity < 0) {
        throw Exception(
          'Insufficient stock for product ID $productId (needs ${-change}, has ${currentProduct.quantity})',
        );
      }

      await (update(products)
        ..where((tbl) => tbl.id.equals(productId))).write(ProductsCompanion(quantity: Value(newQuantity)));
    } else {
      throw Exception('Product with ID $productId not found during stock update.');
    }
  }

  Future<int> createSaleTransaction(List<CartItem> cartItems, double totalAmount, PaymentMethod paymentMethod) async {
    if (cartItems.isEmpty) {
      throw Exception("Cannot create sale with empty cart.");
    }

    return transaction(() async {
      for (final item in cartItems) {
        final productInfo =
            await (select(products, distinct: true)
                  ..where((p) => p.id.equals(item.productId))
                  ..map((p) => p.quantity))
                .getSingleOrNull();

        if (productInfo == null) {
          throw Exception('Product "${item.name}" (ID: ${item.productId}) not found.');
        }
        if (productInfo.quantity < item.quantity) {
          throw Exception(
            'Insufficient stock for "${item.name}". Available: $productInfo, Requested: ${item.quantity}',
          );
        }
      }

      final saleCompanion = SalesCompanion.insert(totalAmount: totalAmount, paymentMethod: Value(paymentMethod.name));
      final newSale = await into(sales).insertReturning(saleCompanion);

      for (final item in cartItems) {
        final saleItemCompanion = SaleItemsCompanion.insert(
          saleId: newSale.id,
          productId: item.productId,
          quantity: item.quantity,
          priceAtSale: item.priceAtSale,
          productSku: item.sku,
          productName: item.name,
        );
        await into(saleItems).insert(saleItemCompanion);

        await _updateStockInTransaction(item.productId, -item.quantity);
      }

      return newSale.id;
    });
  }

  Future<List<Sale>> getSalesHistory({int limit = 50, int offset = 0}) async {
    return (select(sales)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return (select(saleItems)..where((tbl) => tbl.saleId.equals(saleId))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFOlder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFOlder.path, 'pos_db.sqlite'));
    return NativeDatabase(file);
  });
}
