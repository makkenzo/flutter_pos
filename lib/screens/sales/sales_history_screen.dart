import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:flutter_pos/providers/sales_history_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_pos/utils/pdf_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(salesHistoryProvider.notifier).fetchNextPage();
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(salesHistoryProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final SalesHistoryState salesState = ref.watch(salesHistoryProvider);
    final List<Sale> sales = salesState.sales;
    final bool isLoadingInitial = salesState.isLoading && sales.isEmpty && salesState.error == null;
    final bool isLoadingMore = salesState.isLoading && sales.isNotEmpty;
    final bool hasError = salesState.error != null && !salesState.isLoading;

    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');

    return Scaffold(
      appBar: AppBar(title: const Text('История Продаж')),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            _buildSalesList(context, salesState, sales, isLoadingInitial, currencyFormat, dateFormat),

            if (hasError && sales.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Ошибка загрузки истории:\n${_formatErrorMessage(salesState.error)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _handleRefresh, child: const Text('Повторить')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(
    BuildContext context,
    SalesHistoryState salesState,
    List<Sale> sales,
    bool isLoadingInitial,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    if (isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sales.isEmpty && !salesState.isLoading && salesState.error == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'История продаж пуста.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: sales.length + (salesState.isLoading ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        if (index == sales.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final sale = sales[index];
        final paymentMethod = PaymentMethod.values.firstWhere(
          (e) => e.name == sale.paymentMethod,
          orElse: () => PaymentMethod.other,
        );

        return ListTile(
          leading: CircleAvatar(child: Text(sale.orderId.length > 2 ? sale.orderId.substring(0, 2) : sale.orderId)),
          title: Text('Заказ № ${sale.orderId}'),
          subtitle: Text(
            'Дата: ${dateFormat.format(sale.createdAt.toLocal())}\n'
            'Сумма: ${currencyFormat.format(sale.totalAmount)}\n'
            'Метод: ${paymentMethod.displayTitle}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showSaleDetailsDialog(context, ref, sale, currencyFormat, dateFormat);
          },
        );
      },
    );
  }

  void _showSaleDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) async {
    List<SaleItem>? saleItems;
    Object? detailError;

    try {
      saleItems = await ref.read(saleDetailsProvider(sale.orderId).future);
    } catch (e) {
      detailError = e;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, dialogRef, child) {
            final AsyncValue<List<SaleItem>> detailsAsync = dialogRef.watch(saleDetailsProvider(sale.orderId));

            final paymentMethod = PaymentMethod.values.firstWhere(
              (e) => e.name == sale.paymentMethod,
              orElse: () => PaymentMethod.other,
            );

            return AlertDialog(
              title: Text('Детали заказа № ${sale.orderId}'),

              contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
              content: SizedBox(
                width: double.maxFinite,

                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Дата: ${dateFormat.format(sale.createdAt.toLocal())}'),
                      Text('Сумма: ${currencyFormat.format(sale.totalAmount)}'),
                      Text('Метод оплаты: ${paymentMethod.displayTitle}'),
                      Text('Статус: ${sale.status}'),
                      const Divider(height: 16, thickness: 1),

                      Expanded(
                        child: detailsAsync.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(child: Text('Позиции не найдены.'));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.skuName, style: const TextStyle(fontSize: 14)),
                                  subtitle: Text(
                                    '${item.quantity} шт. x ${currencyFormat.format(item.price)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    currencyFormat.format(item.total),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error:
                              (error, stack) => Center(
                                child: Text(
                                  'Ошибка загрузки позиций:\n${_formatErrorMessage(error)}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Закрыть'), onPressed: () => Navigator.of(dialogContext).pop()),

                TextButton(
                  child: const Text('Печать/Просмотр'),
                  onPressed:
                      (saleItems == null || saleItems.isEmpty)
                          ? null
                          : () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            if (!context.mounted) return;

                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 2),
                                    SizedBox(width: 10),
                                    Text("Генерация чека..."),
                                  ],
                                ),
                                duration: Duration(seconds: 5),
                              ),
                            );

                            Uint8List? pdfBytes;
                            Object? pdfError;

                            try {
                              pdfBytes = await generateReceiptPdf(sale, saleItems!);
                            } catch (e) {
                              pdfError = e;
                            }

                            if (!context.mounted) return;

                            scaffoldMessenger.hideCurrentSnackBar();

                            if (pdfBytes != null) {
                              try {
                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async => pdfBytes!,
                                  name: 'receipt_${sale.orderId}.pdf',
                                );

                                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                              } catch (printError) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Ошибка печати: $printError'), backgroundColor: Colors.red),
                                );

                                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                              }
                            } else if (pdfError != null) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка при генерации чека:\n${_formatErrorMessage(pdfError)}'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatErrorMessage(Object? error) {
    if (error == null) return 'Неизвестная ошибка';
    if (error is HttpException) {
      return error.message;
    }
    return error.toString();
  }
}
