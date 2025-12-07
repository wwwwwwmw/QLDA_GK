import 'package:ecom_frontend/models/category.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:flutter/material.dart';

/// Trạng thái tải danh mục
enum CategoryStatus { initial, loading, loaded, error }

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  CategoryStatus _status = CategoryStatus.initial;
  CategoryStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CategoryProvider(this._categoryService) {
    // Tự động tải danh mục khi khởi tạo Provider
    fetchCategories();
  }

  /// Lấy danh sách danh mục từ API
  Future<void> fetchCategories() async {
    _status = CategoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
      _status = CategoryStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CategoryStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Làm mới lại danh sách danh mục
  Future<void> refreshCategories() async {
    await fetchCategories();
  }
}
