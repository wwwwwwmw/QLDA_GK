import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:flutter/material.dart';

/// Trạng thái tải sản phẩm
enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  final ProductService _productService;

  List<Product> _products = [];
  List<Product> get products => _products;

  ProductStatus _status = ProductStatus.initial;
  ProductStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProductProvider(this._productService) {
    // Tự động tải danh sách sản phẩm khi khởi tạo
    fetchProducts();
  }

  /// Lấy danh sách sản phẩm từ API
  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts();
      _status = ProductStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProductStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Làm mới danh sách sản phẩm (dùng khi thêm/xóa/cập nhật)
  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}
