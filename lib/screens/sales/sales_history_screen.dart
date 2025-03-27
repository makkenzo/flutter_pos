import 'package:flutter/material.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/providers/sales_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesHistoryAsync = ref.watch(salesHistoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');

    return Scaffold(
      appBar: AppBar(title: const Text('История Продаж')),
      body: salesHistoryAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(child: Text('История продаж пуста.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(salesHistoryProvider);

              await ref.read(salesHistoryProvider.future);
            },
            child: ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];

                final paymentMethod = PaymentMethod.values.firstWhere(
                  (e) => e.name == sale.paymentMethod,
                  orElse: () => PaymentMethod.other,
                );

                return ListTile(
                  leading: CircleAvatar(child: Text(sale.id.toString())),
                  title: Text('Продажа №${sale.id} от ${dateFormat.format(sale.createdAt.toLocal())}'),
                  subtitle: Text(
                    'Сумма: ${currencyFormat.format(sale.totalAmount)} \nМетод: ${paymentMethod.displayTitle}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showSaleDetailsDialog(context, ref, sale, currencyFormat, dateFormat);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка загрузки истории: $error')),
      ),
    );
  }

  void _showSaleDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, dialogRef, child) {
            final detailsAsync = dialogRef.watch(saleDetailsProvider(sale.id));

            return AlertDialog(
              title: Text('Детали продажи №${sale.id}'),
              content: SizedBox(
                width: double.maxFinite,
                child: detailsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('Не найдено позиций для этой продажи.');
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Дата: ${dateFormat.format(sale.createdAt.toLocal())}'),
                        Text('Сумма: ${currencyFormat.format(sale.totalAmount)}'),
                        Text(
                          'Метод оплаты: ${PaymentMethod.values.firstWhere((e) => e.name == sale.paymentMethod, orElse: () => PaymentMethod.other).displayTitle}',
                        ),
                        const Divider(height: 20),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.productName),
                                subtitle: Text('${item.quantity} шт. x ${currencyFormat.format(item.priceAtSale)}'),
                                trailing: Text(currencyFormat.format(item.quantity * item.priceAtSale)),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Ошибка загрузки деталей: $error'),
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Закрыть'), onPressed: () => Navigator.of(dialogContext).pop()),

                TextButton(
                  child: const Text('Печать чека'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Печать чека для продажи №${sale.id} еще не реализована')));
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
