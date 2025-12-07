import 'dart:io';
import 'package:ecom_frontend/models/category.dart';
import 'package:ecom_frontend/models/product.dart'; // <<< Đảm bảo có IMPORT Product
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:ecom_frontend/services/store_service.dart'; // <<< Đảm bảo có IMPORT StoreService
import 'package:flutter/material.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AddProductScreen extends StatefulWidget {
  // Tham số tùy chọn để nhận sản phẩm cần sửa
  final Product? productToEdit;

  // Constructor nhận productToEdit
  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImageFile; // File ảnh MỚI được chọn (nếu có)
  String? _existingImageUrl; // URL ảnh CŨ (khi ở chế độ sửa)
  bool _isLoading = false; // Trạng thái loading chung
  String? _selectedStoreId; // ID cửa hàng (chỉ cần khi thêm mới)
  bool _isLoadingStore = true; // Trạng thái tải cửa hàng
  String _selectedStatus = 'active'; // Trạng thái sản phẩm (mặc định 'active')

  List<Category> _categories = []; // Danh sách danh mục
  Category? _selectedCategory; // Danh mục đang được chọn (nullable)
  bool _isLoadingCategories = true; // Trạng thái tải danh mục

  late bool _isEditMode; // Biến cờ xác định chế độ Sửa

  @override
  void initState() {
    super.initState();
    // Xác định chế độ dựa vào productToEdit có được truyền vào hay không
    _isEditMode = widget.productToEdit != null;

    // Dùng addPostFrameCallback để đảm bảo context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Chỉ tải danh sách cửa hàng nếu đang ở chế độ THÊM MỚI
      if (!_isEditMode) {
        _fetchUserStore();
      } else {
        // Nếu là chế độ SỬA, lấy storeId từ sản phẩm và không cần tải lại
        _selectedStoreId = widget.productToEdit!.storeId;
        _isLoadingStore = false; // Đánh dấu đã "tải" xong store info
      }
      // Luôn tải danh sách danh mục
      _fetchCategories().then((_) {
        // Sau khi tải xong danh mục, điền dữ liệu form nếu là chế độ Sửa
        if (_isEditMode && widget.productToEdit != null) {
          _populateFormForEdit(widget.productToEdit!);
        }
      });
    });
  }

  // Hàm điền dữ liệu từ productToEdit vào các trường form khi Sửa
  void _populateFormForEdit(Product product) {
    _nameController.text = product.title;
    _priceController.text = product.price.toStringAsFixed(
      0,
    ); // Hiển thị giá không có phần thập phân
    _discountPercentageController.text =
        product.discountPercentage?.toString() ?? '';
    _descriptionController.text = product.description ?? '';
    _existingImageUrl = product.imageUrl; // Lưu URL ảnh hiện có
    _selectedStatus = product.status; // Lấy trạng thái từ sản phẩm

    // --- SỬA LỖI: Tìm category an toàn hơn ---
    // Tìm và chọn danh mục tương ứng trong dropdown
    if (product.categoryId != null && _categories.isNotEmpty) {
      // Dùng try-catch để bắt lỗi nếu không tìm thấy
      try {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          // Không cần orElse nữa vì có try-catch
        );
      } catch (e) {
        _selectedCategory = null; // Đặt là null nếu không tìm thấy
        print(
          "Warning: Category ID ${product.categoryId} not found in the list.",
        );
      }
    } else {
      _selectedCategory =
          null; // Đảm bảo là null nếu product không có categoryId
    }
    // --- KẾT THÚC SỬA LỖI ---

    // Cập nhật UI để hiển thị dữ liệu đã điền
    if (mounted) setState(() {});
  }

  // Tải danh sách danh mục từ API
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);
    try {
      final categoryService = context.read<CategoryService>();
      _categories = await categoryService.getCategories();
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh mục: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  // Lấy ID cửa hàng của Seller (chỉ gọi khi thêm mới)
  Future<void> _fetchUserStore() async {
    if (!mounted) return;
    setState(() => _isLoadingStore = true);
    try {
      final storeService = context.read<StoreService>();
      final myStores = await storeService.getMyStores();
      if (!mounted) return;

      if (myStores.isNotEmpty) {
        // Lấy ID của cửa hàng đầu tiên (giả định chỉ có 1)
        _selectedStoreId = myStores.first.id;
        print("Đã tìm thấy Store ID: $_selectedStoreId");
      } else {
        print("User không có cửa hàng nào.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần tạo cửa hàng trước.')),
        );
      }
    } catch (e) {
      print("Lỗi lấy Store ID: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin cửa hàng: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingStore = false);
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Lưu tạm file ảnh vào state
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImageFile = imageFile; // Lưu file mới chọn
          _existingImageUrl = null; // Bỏ URL ảnh cũ khi đã chọn ảnh mới
        });
      }
    } catch (e) {
      print('Lỗi chọn ảnh: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: ${e.toString()}')));
    }
  }

  // Hàm Lưu sản phẩm (Thêm mới hoặc Cập nhật)
  Future<void> _saveProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra đã tải xong thông tin cửa hàng chưa
    if (_isLoadingStore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải thông tin cửa hàng...')),
      );
      return;
    }

    // Xác định store ID sẽ lưu
    final storeIdToSave = _isEditMode
        ? widget.productToEdit!.storeId
        : _selectedStoreId;
    if (storeIdToSave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được cửa hàng.')),
      );
      return;
    }

    // Kiểm tra ảnh: Phải có ảnh khi thêm mới, có thể giữ ảnh cũ khi sửa
    if (!_isEditMode &&
        _selectedImageFile == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh sản phẩm')),
      );
      return;
    }

    setState(() => _isLoading = true); // Bắt đầu loading

    String? finalImageUrl = _existingImageUrl; // Mặc định là ảnh cũ (khi sửa)

    try {
      final productService = context.read<ProductService>();
      final productProvider = context.read<ProductProvider>();

      // 1. Upload ảnh MỚI nếu có
      if (_selectedImageFile != null) {
        print("Đang upload ảnh mới...");
        if (!await _selectedImageFile!.exists()) {
          // Kiểm tra file tồn tại
          throw Exception("File ảnh đã chọn không tồn tại.");
        }
        finalImageUrl = await productService.uploadImage(_selectedImageFile!);
        if (finalImageUrl == null) {
          throw Exception("Lỗi khi upload ảnh mới: URL trả về null.");
        }
        print("Upload ảnh mới thành công: $finalImageUrl");
      }
      // Nếu không có ảnh mới (_selectedImageFile == null) và đang sửa (_isEditMode)
      // thì finalImageUrl sẽ giữ nguyên giá trị _existingImageUrl

      // 2. Chuẩn bị dữ liệu sản phẩm
      final productData = <String, dynamic>{
        // Dùng Map<String, dynamic>
        'store_id': storeIdToSave,
        'title': _nameController.text.trim(),
        'price': double.parse(_priceController.text), // Đã validate là số
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'discount_percentage': _discountPercentageController.text.isNotEmpty
            ? double.tryParse(_discountPercentageController.text) // Đã validate
            : null,
        'category_id': _selectedCategory?.id, // Lấy ID từ Category đã chọn
        'image_url': finalImageUrl, // URL ảnh cuối cùng
        'status': _selectedStatus, // Trạng thái đã chọn
      };
      // Xóa các trường null không cần thiết (tùy chọn, backend có thể tự xử lý)
      productData.removeWhere((key, value) => value == null);

      // 3. Gọi API Thêm mới hoặc Cập nhật
      if (_isEditMode && widget.productToEdit != null) {
        print("Đang gọi API cập nhật sản phẩm ID: ${widget.productToEdit!.id}");
        await productService.updateProduct(
          widget.productToEdit!.id,
          productData,
        );
        print("Cập nhật sản phẩm thành công.");
      } else {
        print("Đang gọi API thêm sản phẩm mới...");
        await productService.addProduct(
          storeId: productData['store_id'] as String,
          title: productData['title'] as String,
          price: productData['price'] as double,
          description: productData['description'] as String?,
          discountPercentage: productData['discount_percentage'] as double?,
          categoryId: productData['category_id'] as String?,
          imageUrl: productData['image_url'] as String?,
          status: productData['status'] as String,
        );
        print("Thêm sản phẩm mới thành công.");
      }

      // 4. Xử lý sau khi thành công
      if (!mounted) return;
      await productProvider.refreshProducts(); // Tải lại danh sách sản phẩm
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Cập nhật thành công!' : 'Đăng sản phẩm thành công!',
          ),
        ),
      );
      Navigator.pop(context); // Quay về màn hình trước
    } catch (e) {
      // Xử lý lỗi (upload hoặc lưu)
      print("Lỗi khi lưu sản phẩm: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      // Luôn dừng loading
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Dispose các controller để tránh leak memory
    _nameController.dispose();
    _priceController.dispose();
    _discountPercentageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Giao diện ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Chỉnh sửa sản phẩm" : "Đăng sản phẩm mới",
        ), // Tiêu đề động
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      backgroundColor: kBackgroundColor,
      body:
          _isLoadingStore // Hiển thị loading nếu đang tải store ID
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              // Cho phép cuộn nếu nội dung dài
              padding: const EdgeInsets.all(kDefaultPadding * 1.5),
              child: Form(
                key: _formKey, // Gắn key cho Form
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // Các widget con giãn hết chiều ngang
                  children: [
                    _buildImagePicker(), // Widget chọn/hiển thị ảnh
                    const SizedBox(height: kDefaultPadding * 1.5),
                    // Các trường nhập liệu
                    _buildTextField(
                      controller: _nameController,
                      labelText: "Tên sản phẩm",
                      hintText: "Nhập tên sản phẩm",
                      prefixIcon: Icons.label_outline,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Tên sản phẩm phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _priceController,
                      labelText: "Giá",
                      hintText: "Nhập giá gốc (VND)",
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Giá phải là số dương';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _discountPercentageController,
                      labelText: "Phần trăm giảm giá (%)",
                      hintText:
                          "Nhập % giảm giá (0-100, bỏ trống nếu không giảm)",
                      prefixIcon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ), // Cho phép số thập phân
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final percentage = double.tryParse(value);
                          if (percentage == null ||
                              percentage < 0 ||
                              percentage > 100) {
                            return 'Phải là số từ 0-100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _buildCategoryDropdown(), // Dropdown chọn danh mục
                    const SizedBox(height: kDefaultPadding),
                    _buildStatusDropdown(), // Dropdown chọn trạng thái
                    const SizedBox(height: kDefaultPadding),
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: "Mô tả sản phẩm",
                      hintText:
                          "Nhập mô tả chi tiết (chất liệu, kích thước,...)",
                      prefixIcon: Icons.description_outlined,
                      maxLines: 5, // Cho phép nhập nhiều dòng
                      keyboardType: TextInputType.multiline,
                      // Không cần validator cho mô tả (tùy chọn)
                    ),
                    const SizedBox(height: kDefaultPadding * 2),
                    // Nút Lưu/Đăng
                    PrimaryButton(
                      text: _isEditMode
                          ? "Lưu thay đổi"
                          : "Đăng sản phẩm", // Text nút động
                      onPressed: _saveProduct, // Gọi hàm lưu
                      isLoading: _isLoading, // Hiển thị loading nếu đang xử lý
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget chọn/hiển thị ảnh
  Widget _buildImagePicker() {
    Widget imageWidget;
    // Ưu tiên hiển thị ảnh MỚI đã chọn (_selectedImageFile)
    if (_selectedImageFile != null) {
      imageWidget = Image.file(_selectedImageFile!, fit: BoxFit.contain);
    }
    // Nếu không có ảnh mới, hiển thị ảnh CŨ (_existingImageUrl) khi sửa
    else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _existingImageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Icon(
          Icons.broken_image_outlined,
          size: 50,
          color: kSecondaryTextColor,
        ),
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kPrimaryColor,
            ),
          );
        },
      );
    }
    // Nếu không có cả hai, hiển thị placeholder
    else {
      imageWidget = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 50,
            color: kSecondaryTextColor,
          ),
          SizedBox(height: 12),
          Text(
            "Chọn ảnh sản phẩm",
            style: TextStyle(color: kSecondaryTextColor, fontSize: 16),
          ),
        ],
      );
    }

    // Giao diện khung chứa ảnh
    return Center(
      child: GestureDetector(
        onTap: _pickImage, // Nhấn để chọn ảnh
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: imageWidget), // Hiển thị ảnh hoặc placeholder
        ),
      ),
    );
  }

  // Widget TextField chuẩn (Copy từ code cũ, không cần sửa)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: kSecondaryTextColor, size: 20),
            hintText: hintText,
            hintStyle: const TextStyle(
              color: kSecondaryTextColor,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Widget Dropdown chọn Danh mục
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Danh mục",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCategories // Hiển thị loading nếu đang tải danh mục
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimaryColor,
                ),
              )
            : _categories
                  .isEmpty // Hiển thị thông báo nếu không có danh mục
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: kSecondaryTextColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Không có danh mục",
                      style: TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : DropdownButtonFormField<Category>(
                // Widget dropdown
                value: _selectedCategory, // Giá trị đang được chọn
                hint: const Text(
                  "Chọn danh mục (tùy chọn)",
                  style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
                ),
                isExpanded: true, // Cho phép dropdown giãn hết chiều ngang
                decoration: InputDecoration(
                  // Trang trí giống TextField
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    color: kSecondaryTextColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 12.0,
                  ).copyWith(left: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                items: _categories.map((category) {
                  // Tạo các lựa chọn từ danh sách _categories
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ), // Hiển thị tên danh mục
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  // Cập nhật state khi chọn giá trị mới
                  setState(() => _selectedCategory = newValue);
                },
                // Bỏ validator vì danh mục là tùy chọn
              ),
      ],
    );
  }

  // Widget Dropdown chọn Trạng thái
  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trạng thái",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus, // Giá trị đang được chọn (mặc định 'active')
          isExpanded: true,
          decoration: InputDecoration(
            // Trang trí
            prefixIcon: Icon(
              _selectedStatus == 'active'
                  ? Icons.visibility_outlined
                  : Icons
                        .visibility_off_outlined, // Icon thay đổi theo trạng thái
              color: kSecondaryTextColor,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ).copyWith(left: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
          ),
          items: const [
            // Các lựa chọn trạng thái
            DropdownMenuItem<String>(value: 'active', child: Text('Đang bán')),
            DropdownMenuItem<String>(
              value: 'inactive',
              child: Text('Ngừng bán'),
            ),
          ],
          onChanged: (String? newValue) {
            // Cập nhật state khi chọn
            if (newValue != null) {
              setState(() => _selectedStatus = newValue);
            }
          },
          // Không cần validator vì luôn có giá trị mặc định
        ),
      ],
    );
  }
}
