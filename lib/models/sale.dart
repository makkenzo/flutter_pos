import 'package:drift/drift.dart';

@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  RealColumn get totalAmount => real().named('total_amount')();
  // Можно добавить другие поля: customerId, paymentMethod, discountAmount и т.д.
}
