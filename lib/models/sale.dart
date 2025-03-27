import 'package:drift/drift.dart';
import 'package:flutter_pos/models/payment_method.dart';

@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  RealColumn get totalAmount => real().named('total_amount')();
  TextColumn get paymentMethod => text().named('payment_method').withDefault(Constant(PaymentMethod.cash.name))();
}
