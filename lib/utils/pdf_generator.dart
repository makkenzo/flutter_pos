import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Font> _loadPdfFont(String fontAssetPath) async {
  final fontData = await rootBundle.load(fontAssetPath);
  return pw.Font.ttf(fontData);
}

Future<Uint8List> generateReceiptPdf(Sale sale, List<SaleItem> items) async {
  final pw.Document pdf = pw.Document();
  final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸');
  final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', 'ru_RU');

  final pw.Font regularFont = await _loadPdfFont(
    'assets/fonts/Roboto-Regular.ttf',
  );
  final pw.Font boldFont = await _loadPdfFont('assets/fonts/Roboto-Bold.ttf');

  final pw.ThemeData theme = pw.ThemeData.withFont(
    base: regularFont,
    bold: boldFont,
  );

  final pw.TextStyle textStyle = pw.TextStyle.defaultStyle();
  final pw.TextStyle boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  final pw.TextStyle smallStyle = textStyle.copyWith(fontSize: 9);
  final pw.TextStyle smallBoldStyle = boldStyle.copyWith(fontSize: 9);
  final pw.TextStyle headerStyle = boldStyle.copyWith(fontSize: 16);
  final pw.TextStyle totalStyle = boldStyle.copyWith(fontSize: 12);

  const String storeName = 'SAMPLE SHOP';
  const String storeAddress = 'SAMPLE ADDRESS';
  const String storePhone = '+7 (777) 123-45-67';

  final paymentMethod = PaymentMethod.values.firstWhere(
    (e) => e.name == sale.paymentMethod,
    orElse: () => PaymentMethod.other,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      theme: theme,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(storeName, style: headerStyle)),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text(storeAddress, style: smallStyle)),
              pw.Center(child: pw.Text(storePhone, style: smallStyle)),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('КАССОВЫЙ ЧЕК', style: boldStyle)),
              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Заказ №:', style: smallStyle),
                  pw.Text(sale.orderId, style: smallBoldStyle),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Дата:', style: smallStyle),
                  pw.Text(
                    dateFormat.format(sale.createdAt.toLocal()),
                    style: smallStyle,
                  ),
                ],
              ),
              pw.Divider(height: 10, thickness: 0.5),
              _buildItemsTable(
                items,
                currencyFormat,
                smallStyle,
                smallBoldStyle,
              ),
              pw.Divider(height: 10, thickness: 0.5),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('ИТОГО К ОПЛАТЕ:', style: totalStyle),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(sale.totalAmount),
                    style: totalStyle,
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Метод оплаты:', style: smallStyle),
                  pw.SizedBox(width: 10),
                  pw.Text(paymentMethod.displayTitle, style: smallStyle),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('Спасибо за покупку!', style: textStyle),
              ),
              pw.SizedBox(height: 10),
              // Опционально: Штрих-код или QR-код заказа
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(), // Или pw.Barcode.qrCode()
                  data: sale.orderId,
                  width: 100,
                  height: 40,
                  textStyle: smallStyle.copyWith(fontSize: 7),
                  drawText: true,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildItemsTable(
  List<SaleItem> items,
  NumberFormat currencyFormat,
  pw.TextStyle normalStyle,
  pw.TextStyle boldStyle,
) {
  final headers = ['Наименование', 'Кол-во', 'Цена', 'Сумма'];
  // Уменьшаем шрифт для таблицы
  final cellStyle = normalStyle.copyWith(fontSize: 8);
  final cellBoldStyle = boldStyle.copyWith(fontSize: 8);

  // Формируем строки таблицы
  final data =
      items.map((item) {
        return [
          item.skuName, // Наименование
          item.quantity.toString(), // Кол-во
          currencyFormat.format(item.price), // Цена
          currencyFormat.format(item.total), // Сумма
        ];
      }).toList();

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: null, // Без внешних границ
    headerStyle: cellBoldStyle,
    cellStyle: cellStyle,
    headerDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
    ),
    cellHeight: 15, // Уменьшаем высоту ячеек
    // Выравнивание ячеек
    cellAlignments: {
      0: pw.Alignment.centerLeft, // Наименование - слева
      1: pw.Alignment.centerRight, // Кол-во - справа
      2: pw.Alignment.centerRight, // Цена - справа
      3: pw.Alignment.centerRight, // Сумма - справа
    },
    // Установка ширины колонок (подбирается экспериментально под формат)
    columnWidths: const {
      0: pw.FlexColumnWidth(4.0), // Наименование шире
      1: pw.FlexColumnWidth(1.0), // Кол-во
      2: pw.FlexColumnWidth(1.5), // Цена
      3: pw.FlexColumnWidth(1.5), // Сумма
    },
  );
}
