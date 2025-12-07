// SỬA: Import file chứa hàm parseDouble (giả sử là parsers.dart)
// Hoặc import cart_item.dart nếu bạn đặt hàm parse ở đó
import 'parsers.dart'; 

class Product {
  final String id;
  final String storeId;
  final String title;
  final String? categoryId;
  final double price; // Giá gốc
  final double? discountPercentage; // Phần trăm giảm giá
  final double? finalPrice; // Giá sau khi giảm (thường được tính toán)
  final double? rating;
  final String? imageUrl;
  final String status;
  final String? description; // Mô tả sản phẩm

  Product({
    required this.id,
    required this.storeId,
    required this.title,
    this.categoryId,
    required this.price,
    this.discountPercentage,
    this.finalPrice,
    this.rating,
    this.imageUrl,
    required this.status,
    this.description, // Thêm vào constructor
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      title: json['title'] ?? '',
      categoryId: json['category_id']?.toString(),
      price: parseDouble(json['price']) ?? 0.0,
      discountPercentage: parseDouble(json['discount_percentage']),
      finalPrice: parseDouble(json['final_price']),
      rating: parseDouble(json['rating']),
      imageUrl: json['image_url'] as String?,
      status: json['status'] ?? 'inactive',
      description: json['description'] as String?,
    );
  }

}