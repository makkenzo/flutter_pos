import 'package:meta/meta.dart';

@immutable
class LatestOrder {
  final String orderId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const LatestOrder({required this.orderId, required this.totalAmount, required this.status, required this.createdAt});

  factory LatestOrder.fromJson(Map<String, dynamic> json) {
    return LatestOrder(
      orderId: json['order_id'] as String? ?? 'N/A',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime(1970),
    );
  }
}
