import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/order.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  
  Future<Order> createOrderFromCart() async {
    try {
      print("Gọi API backend (POST /orders) để tạo đơn hàng từ giỏ hàng...");
      final response = await _dio.post('/orders');

      if (response.statusCode == 201 && response.data != null) {
        print(
          "Đơn hàng đã được tạo thành công trên backend. ID: ${response.data['id']}",
        );
        return Order.fromJson(response.data);
      } else {
        final message =
            response.data?['message'] ??
            response.statusMessage ??
            'Lỗi khi tạo đơn hàng';

        print("Lỗi tạo đơn hàng (không phải 201): $message");
        throw Exception(message);
      }
    } on DioException catch (e) {
      print("DioException khi tạo đơn hàng: ${e.response?.data ?? e.message}");
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi tạo đơn hàng',
      );
    } catch (e) {
      print("Lỗi không xác định khi tạo đơn hàng: $e");
      throw Exception('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}');
    }
  }

  Future<String> checkOrderStatus(String orderId) async {
    try {
      print("OrderService: Gọi API backend GET /orders/$orderId/status");
      final response = await _dio.get('/orders/$orderId/status');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] != null) {
        final status = response.data['status'] as String;

        print(
          "OrderService: Đã nhận trạng thái cho đơn hàng $orderId: $status",
        );
        return status;
      } else {
        print(
          "OrderService: Định dạng phản hồi không hợp lệ từ kiểm tra trạng thái cho đơn hàng $orderId",
        );
        throw Exception('Phản hồi trạng thái không hợp lệ từ server');
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException khi kiểm tra trạng thái đơn hàng $orderId: ${e.response?.statusCode} - ${e.response?.data}",
      );
      if (e.response?.statusCode == 404) return 'not_found';
      if (e.response?.statusCode == 403) return 'forbidden';
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi kiểm tra trạng thái',
      );
    } catch (e) {
      print(
        "OrderService: Lỗi không xác định khi kiểm tra trạng thái đơn hàng $orderId: $e",
      );
      throw Exception(
        'Lỗi không xác định khi kiểm tra trạng thái: ${e.toString()}',
      );
    }
  }

  Future<List<Order>> getMyOrders() async {
    try {
      print("OrderService: Gọi API backend GET /orders/my");

      final response = await _dio.get('/orders/my');

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;

        print("OrderService: Đã nhận ${data.length} đơn hàng.");

        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        print("OrderService: Định dạng phản hồi không hợp lệ từ getMyOrders.");

        return [];
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException khi lấy đơn hàng của tôi: ${e.response?.data ?? e.message}",
      );

      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi lấy đơn hàng',
      );
    } catch (e) {
      print("OrderService: Lỗi không xác định khi lấy đơn hàng của tôi: $e");
      throw Exception('Lỗi không xác định khi lấy đơn hàng: ${e.toString()}');
    }
  }

  
}
