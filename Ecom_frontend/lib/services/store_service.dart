import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/store.dart';

class StoreService {
  final Dio _dio;

  StoreService(this._dio);

  // Lấy danh sách cửa hàng thuộc người dùng hiện tại (GET /stores/my/stores)
  Future<List<Store>> getMyStores() async {
    try {
      final response = await _dio.get('/stores/my/stores');
      final List<dynamic> data = response.data;
      return data.map((json) => Store.fromJson(json)).toList();
    } on DioException catch (e) {
      // Nếu user chưa có cửa hàng nào -> trả về danh sách rỗng
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy cửa hàng');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy cửa hàng');
    }
  }

  // Có thể bổ sung thêm hàm tạo / cập nhật cửa hàng (createStore, updateStore, ...)
}
