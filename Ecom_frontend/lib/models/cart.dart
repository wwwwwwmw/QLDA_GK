import 'cart_item.dart';
import 'parsers.dart'; 
class Cart {
  final String cartId;
  final List<CartItem> items;
  final double subtotal;

  Cart({required this.cartId, required this.items, required this.subtotal});

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List<dynamic>? ?? [];
    List<CartItem> cartItems = itemsList
        .map((itemJson) => CartItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return Cart(
      cartId: json['cart_id']?.toString() ?? '',
      items: cartItems,
      subtotal: parseDouble(json['subtotal']) ?? 0.0,
    );
  }
}
