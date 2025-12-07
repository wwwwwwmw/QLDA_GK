import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/cart.dart';

class CartService {
  final Dio _dio;
  CartService(this._dio);

  // Lấy giỏ hàng người dùng hiện tại
  Future<Cart> getMyCart() async {
    try {
      final response = await _dio.get('/cart');
      return Cart.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Không có giỏ -> trả về giỏ rỗng
        return Cart(cartId: '', items: [], subtotal: 0.0);
      }
      print("DioException getMyCart: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy giỏ hàng');
    } catch (e) {
      print("Exception getMyCart: $e");
      throw Exception('Lỗi không xác định khi lấy giỏ hàng');
    }
  }

  // Thêm sản phẩm vào giỏ
  Future<void> addItemToCart(String productId, int quantity) async {
    try {
      await _dio.post(
        '/cart/items',
        data: {'product_id': productId, 'qty': quantity},
      );
    } on DioException catch (e) {
      print("DioException addItemToCart: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi thêm vào giỏ hàng',
      );
    } catch (e) {
      print("Exception addItemToCart: $e");
      throw Exception('Lỗi không xác định khi thêm vào giỏ hàng');
    }
  }

  // Cập nhật số lượng 1 item trong giỏ
  Future<void> updateCartItem(String itemId, int quantity) async {
    try {
      await _dio.put('/cart/items/$itemId', data: {'qty': quantity});
    } on DioException catch (e) {
      print("DioException updateCartItem: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật giỏ hàng',
      );
    } catch (e) {
      print("Exception updateCartItem: $e");
      throw Exception('Lỗi không xác định khi cập nhật giỏ hàng');
    }
  }

  // Xóa 1 item khỏi giỏ
  Future<void> removeCartItem(String itemId) async {
    try {
      await _dio.delete('/cart/items/$itemId');
    } on DioException catch (e) {
      print("DioException removeCartItem: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xóa khỏi giỏ hàng',
      );
    } catch (e) {
      print("Exception removeCartItem: $e");
      throw Exception('Lỗi không xác định khi xóa khỏi giỏ hàng');
    }
  }

  // Xóa toàn bộ giỏ
  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    } on DioException catch (e) {
      print("DioException clearCart: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa giỏ hàng');
    } catch (e) {
      print("Exception clearCart: $e");
      throw Exception('Lỗi không xác định khi xóa giỏ hàng');
    }
  }
}
