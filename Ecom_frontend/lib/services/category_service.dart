import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/category.dart';

class CategoryService {
  final Dio _dio;
  CategoryService(this._dio);

  // Lấy danh sách danh mục sản phẩm
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories'); // API public
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException khi lấy danh mục: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy danh sách danh mục',
      );
    } catch (e) {
      print("Lỗi không xác định khi lấy danh mục: $e");
      throw Exception('Lỗi không xác định khi tải danh mục.');
    }
  }
}
