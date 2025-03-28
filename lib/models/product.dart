import 'package:meta/meta.dart';

@immutable
class Product {
  final int id;
  final String skuCode;
  final String barcode;
  final String unit;
  final String skuName; // Это будет наше основное "имя" товара
  final String status1c;
  final String department;
  final String groupName;
  final String subgroup;
  final String supplier;
  final double costPrice;
  final double price; // Это цена продажи
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Конструктор со всеми полями
  const Product({
    required this.id,
    required this.skuCode,
    required this.barcode,
    required this.unit,
    required this.skuName,
    required this.status1c,
    required this.department,
    required this.groupName,
    required this.subgroup,
    required this.supplier,
    required this.costPrice,
    required this.price,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  // Геттер для удобства, если в остальном коде используется 'name'
  String get name => skuName;

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        // Используем безопасное преобразование num -> int
        id: (json['id'] as num?)?.toInt() ?? -1, // Используем -1 как индикатор ошибки/null
        skuCode: json['sku_code'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        unit: json['unit'] as String? ?? 'шт',
        skuName: json['sku_name'] as String? ?? 'Без названия',
        status1c: json['status_1c'] as String? ?? '',
        department: json['department'] as String? ?? '',
        groupName: json['group_name'] as String? ?? '',
        subgroup: json['subgroup'] as String? ?? '',
        supplier: json['supplier'] as String? ?? '',
        // Используем безопасное преобразование num -> double
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        // Используем безопасное преобразование num -> int
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        // Парсинг дат с проверкой на null
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e, stackTrace) {
      // Добавим stackTrace
      print("!!! Error parsing Product from JSON: $e");
      print("Stack trace: $stackTrace"); // Печатаем stack trace
      print("Problematic JSON for Product: $json");
      rethrow;
    }
  }
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'sku_code': skuCode,
      'barcode': barcode,
      'unit': unit,
      'sku_name': skuName,
      'status_1c': status1c,
      'department': department,
      'group_name': groupName,
      'subgroup': subgroup,
      'supplier': supplier,
      'cost_price': costPrice,
      'price': price,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'sku_code': skuCode,
      'barcode': barcode,
      'unit': unit,
      'sku_name': skuName,
      'status_1c': status1c,
      'department': department,
      'group_name': groupName,
      'subgroup': subgroup,
      'supplier': supplier,
      'cost_price': costPrice,
      'price': price,
      'quantity': quantity,
    };
  }

  Product copyWith({
    int? id,
    String? skuCode,
    String? barcode,
    String? unit,
    String? skuName,
    String? status1c,
    String? department,
    String? groupName,
    String? subgroup,
    String? supplier,
    double? costPrice,
    double? price,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      skuCode: skuCode ?? this.skuCode,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      skuName: skuName ?? this.skuName,
      status1c: status1c ?? this.status1c,
      department: department ?? this.department,
      groupName: groupName ?? this.groupName,
      subgroup: subgroup ?? this.subgroup,
      supplier: supplier ?? this.supplier,
      costPrice: costPrice ?? this.costPrice,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
