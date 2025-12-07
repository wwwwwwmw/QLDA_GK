import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product.dart';

class ProductService {
  final Dio _dio;
  ProductService(this._dio);

  // Lấy danh sách sản phẩm
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getProducts: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy sản phẩm');
    } catch (e) {
      print("Exception getProducts: $e");
      throw Exception('Lỗi không xác định khi lấy sản phẩm');
    }
  }

  // Lấy chi tiết 1 sản phẩm theo ID
  Future<Product> getProductDetail(String productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy sản phẩm');
      }
      print("DioException getProductDetail($productId): ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi lấy chi tiết sản phẩm',
      );
    } catch (e) {
      print("Exception getProductDetail($productId): $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết sản phẩm');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        '/products/upload-image',
        data: formData,
      );
      return response.data['image_url'];
    } on DioException catch (e) {
      print("DioException uploadImage: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi upload ảnh');
    } catch (e) {
      print("Exception uploadImage: $e");
      throw Exception('Lỗi không xác định khi upload ảnh');
    }
  }

  // Tạo sản phẩm mới
  Future<Product> addProduct({
    required String storeId,
    required String title,
    required double price,
    String? description,
    double? discountPercentage,
    String? categoryId,
    String? imageUrl,
    String status = 'active', // Mặc định là active
  }) async {
    try {
      final Map<String, dynamic> productData = {
        'store_id': storeId,
        'title': title,
        'price': price,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (discountPercentage != null)
          'discount_percentage': discountPercentage,
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
        if (imageUrl != null) 'image_url': imageUrl,
        'status': status, // Gửi status lên backend
      };

      productData.removeWhere((key, value) => value == null);

      final response = await _dio.post('/products', data: productData);
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException khi tạo sản phẩm: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo sản phẩm');
    } catch (e) {
      print("Lỗi không xác định khi tạo sản phẩm: $e");
      throw Exception('Lỗi không xác định khi tạo sản phẩm');
    }
  }

  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _dio.put(
        '/products/$productId',
        data: productData,
      );
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      print(
        "DioException khi cập nhật sản phẩm $productId: ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật sản phẩm',
      );
    } catch (e) {
      print("Lỗi không xác định khi cập nhật sản phẩm $productId: $e");
      throw Exception('Lỗi không xác định khi cập nhật sản phẩm');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final response = await _dio.delete('/products/$productId');
      // Kiểm tra status code (thường là 200 OK hoặc 204 No Content)
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Lỗi API khi xóa sản phẩm (Status: ${response.statusCode})',
        );
      }
      print("Xóa sản phẩm $productId thành công từ backend.");
      // --- KẾT THÚC GỌI API ---
    } on DioException catch (e) {
      print("DioException khi xóa sản phẩm $productId: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa sản phẩm');
    } catch (e) {
      print("Lỗi không xác định khi xóa sản phẩm $productId: $e");
      throw Exception('Lỗi không xác định khi xóa sản phẩm');
    }
  }
}
