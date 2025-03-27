import 'package:drift/drift.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get sku => text().withLength(min: 1, max: 50).unique()();
  TextColumn get description => text().nullable()();
  RealColumn get purchasePrice => real().named('purchase_price').nullable()();
  RealColumn get sellingPrice => real().named('selling_price')();
  IntColumn get quantity => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}
