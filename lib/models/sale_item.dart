import 'package:drift/drift.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/models/sale.dart';

@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().named('sale_id').references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().named('product_id').references(Products, #id, onDelete: KeyAction.setNull)();
  IntColumn get quantity => integer()();
  RealColumn get priceAtSale => real().named('price_at_sale')();
  TextColumn get productSku => text().named('product_sku')();
  TextColumn get productName => text().named('product_name')();
}
