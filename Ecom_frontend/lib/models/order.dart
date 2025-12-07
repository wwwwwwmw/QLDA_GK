import 'parsers.dart';

class Order {
  final String id;
  final String code;
  final String buyerId;
  final String storeId;
  final double subtotal;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firstItemImageUrl;

  Order({
    required this.id,
    required this.code,
    required this.buyerId,
    required this.storeId,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.firstItemImageUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Backend service đã format ID thành String
    return Order(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? 'N/A',
      buyerId: json['buyer_id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      subtotal: parseDouble(json['subtotal']) ?? 0.0,
      total: parseDouble(json['total']) ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      firstItemImageUrl: json['first_item_image_url'] as String?,
    );
  }
}
