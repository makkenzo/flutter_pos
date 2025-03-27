import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final salesHistoryProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getSalesHistory();
});

final saleDetailsProvider = FutureProvider.family<List<SaleItem>, int>((ref, saleId) async {
  final db = ref.watch(databaseProvider);
  return db.getSaleItems(saleId);
});

final saleByIdProvider = FutureProvider.family<Sale?, int>((ref, saleId) async {
  final db = ref.watch(databaseProvider);
  return db.getSaleById(saleId);
});
