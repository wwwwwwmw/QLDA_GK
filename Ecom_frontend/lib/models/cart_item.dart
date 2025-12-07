import 'parsers.dart';

class CartItem {
  final String id;
  final String productId;
  final String title; // Giữ lại title để hiển thị
  final double price; // Giá gốc
  final int qty;
  final String? imageUrl;
  final double? discountPercentage;
  final double? finalPrice; // Giá sau giảm

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    required this.qty,
    this.imageUrl,
    this.discountPercentage,
    this.finalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      // Các lệnh gọi parseDouble/parseInt ở đây đã đúng (gọi hàm toàn cục)
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Product',
      price: parseDouble(json['price']) ?? 0.0,
      qty: parseInt(json['qty']) ?? 1,
      imageUrl: json['image_url'] as String?,
      discountPercentage: parseDouble(json['discount_percentage']),
      finalPrice: parseDouble(json['final_price']),
    );
  }
}
