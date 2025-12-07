import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/models/store.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
// --- THÊM IMPORT ---
import 'package:ecom_frontend/services/product_service.dart'; // Thêm dòng này
// --- KẾT THÚC THÊM IMPORT ---
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// --- THÊM IMPORT CHO AddProductScreen ---
import 'package:ecom_frontend/screens/seller/add_product_screen.dart'; // Thêm dòng này
// --- KẾT THÚC THÊM IMPORT ---
// --- THÊM IMPORT CHO ProductDetailScreen ---
import 'package:ecom_frontend/screens/product/product_detail_screen.dart'; // Thêm dòng này
// --- KẾT THÚC THÊM IMPORT ---


// Màn hình hiển thị danh sách sản phẩm của Seller
class MyProductsStoreScreen extends StatefulWidget {
  const MyProductsStoreScreen({super.key});

  @override
  State<MyProductsStoreScreen> createState() => _MyProductsStoreScreenState();
}

class _MyProductsStoreScreenState extends State<MyProductsStoreScreen> {
  List<Store> _myStores = [];
  bool _isLoadingStores = true;
  String? _storeError;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Sử dụng WidgetsBinding để đảm bảo context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        _fetchMyStores();
      }
    });
  }

  // Lấy danh sách cửa hàng của Seller
  Future<void> _fetchMyStores() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStores = true;
      _storeError = null;
    });
    try {
      // Dùng read vì chỉ cần gọi service một lần
      final storeService = context.read<StoreService>();
      _myStores = await storeService.getMyStores();
    } catch (e) {
      _storeError = "Lỗi tải thông tin cửa hàng: ${e.toString()}";
      print(_storeError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStores = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ProductProvider để lấy danh sách sản phẩm
    final productProvider = context.watch<ProductProvider>();

    // Lọc sản phẩm thuộc cửa hàng của Seller hiện tại
    List<Product> sellerProducts = [];
    if (!_isLoadingStores && _myStores.isNotEmpty && productProvider.products.isNotEmpty) {
      // Giả sử Seller chỉ có 1 cửa hàng trong bản demo này
      final myStoreId = _myStores.first.id;
      sellerProducts = productProvider.products
          .where((p) => p.storeId == myStoreId)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm của tôi'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(productProvider.status, sellerProducts),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Điều hướng đến màn hình AddProductScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) => _refreshData()); // Refresh sau khi thêm sản phẩm
        },
        label: const Text('Thêm sản phẩm'),
        icon: const Icon(Icons.add),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Hàm refresh dữ liệu (cửa hàng và sản phẩm)
  Future<void> _refreshData() async {
     // Tải lại cửa hàng để đảm bảo storeId là mới nhất (nếu cần)
     await _fetchMyStores();
     if (mounted) {
        // Tải lại danh sách sản phẩm từ ProductProvider
        await context.read<ProductProvider>().refreshProducts();
     }
  }


  Widget _buildBody(ProductStatus productStatus, List<Product> sellerProducts) {
    // Hiển thị loading nếu đang tải cửa hàng HOẶC đang tải sản phẩm (và chưa có sản phẩm nào)
    if (_isLoadingStores || (productStatus == ProductStatus.loading && sellerProducts.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    // Hiển thị lỗi tải cửa hàng
    if (_storeError != null) {
       return Center(
         child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Text(_storeError!, style: const TextStyle(color: kHeartColor), textAlign: TextAlign.center),
         )
       );
    }

    // Hiển thị thông báo nếu Seller chưa có cửa hàng
    if (_myStores.isEmpty) {
        return const Center(child: Text('Bạn cần tạo cửa hàng trước khi đăng sản phẩm.'));
    }

    // Hiển thị lỗi tải sản phẩm (nếu chưa có sản phẩm nào để hiển thị)
    if (productStatus == ProductStatus.error && sellerProducts.isEmpty) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(kDefaultPadding),
           child: Text('Lỗi tải sản phẩm: ${context.read<ProductProvider>().errorMessage ?? 'Không xác định'}',
             style: const TextStyle(color: kHeartColor), textAlign: TextAlign.center),
         )
       );
    }

    // Hiển thị thông báo nếu chưa có sản phẩm
    if (sellerProducts.isEmpty) {
      return RefreshIndicator( // Cho phép refresh cả khi rỗng
        onRefresh: _refreshData,
        color: kPrimaryColor,
        child: LayoutBuilder(
           builder: (context, constraints) => SingleChildScrollView(
             physics: const AlwaysScrollableScrollPhysics(),
             child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                       const SizedBox(height: kDefaultPadding),
                       const Text(
                         'Bạn chưa đăng sản phẩm nào.',
                         style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
                       ),
                        const SizedBox(height: kDefaultPadding * 2),
                        ElevatedButton.icon( // Nút để thêm sản phẩm nhanh
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddProductScreen()),
                            ).then((_) => _refreshData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Đăng sản phẩm đầu tiên'),
                          style: ElevatedButton.styleFrom(
                             backgroundColor: kPrimaryColor,
                             foregroundColor: Colors.white,
                          ),
                        )
                     ],
                   ),
                ),
             ),
           ),
        ),
      );
    }

    // Hiển thị danh sách sản phẩm
    return RefreshIndicator(
        onRefresh: _refreshData,
        color: kPrimaryColor,
        child: ListView.separated(
           padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2, horizontal: kDefaultPadding / 2),
           itemCount: sellerProducts.length,
           separatorBuilder: (context, index) => const Divider(height: kDefaultPadding / 2),
           itemBuilder: (context, index) {
              final product = sellerProducts[index];
              return _buildProductListItem(context, product);
           },
        ),
    );
  }

  // Widget hiển thị một sản phẩm trong danh sách
  Widget _buildProductListItem(BuildContext context, Product product) {
     final bool hasDiscount = product.discountPercentage != null && product.discountPercentage! > 0;
     final String displayPrice = _currencyFormatter.format(product.finalPrice ?? product.price);
     final String? originalPrice = hasDiscount ? _currencyFormatter.format(product.price) : null;

      return ListTile(
         leading: SizedBox(
           width: 60,
           height: 60,
           child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      // Placeholder khi đang tải
                      loadingBuilder: (context, child, loadingProgress) {
                         if (loadingProgress == null) return child;
                         return Container(color: Colors.grey[200]);
                      },
                      // Icon khi lỗi ảnh
                      errorBuilder: (context, error, stackTrace) => Container(
                         color: Colors.grey[200],
                         child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 30),
                      ),
                    )
                  : Container( // Placeholder nếu không có ảnh
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 30),
                    ),
           ),
         ),
         title: Text(
           product.title,
           maxLines: 2,
           overflow: TextOverflow.ellipsis,
           style: const TextStyle(fontWeight: FontWeight.w500),
         ),
         subtitle: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const SizedBox(height: 4),
              Row( // Hàng chứa giá bán và giá gốc (nếu có)
                 children: [
                    Text(
                       displayPrice, // Giá bán (sau giảm giá nếu có)
                       style: const TextStyle(color: kBrownDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (originalPrice != null) // Giá gốc gạch đi (chỉ hiện nếu có giảm giá)
                      Padding(
                         padding: const EdgeInsets.only(left: 8.0),
                         child: Text(
                           originalPrice,
                           style: const TextStyle(
                              fontSize: 12,
                              color: kSecondaryTextColor,
                              decoration: TextDecoration.lineThrough,
                           ),
                         ),
                      ),
                 ],
              ),
              const SizedBox(height: 4),
              Text( // Trạng thái sản phẩm
                'Trạng thái: ${product.status == 'active' ? 'Đang bán' : 'Ngừng bán'}',
                style: TextStyle(
                  fontSize: 12,
                  color: product.status == 'active' ? Colors.green.shade700 : kSecondaryTextColor,
                ),
              ),
           ],
         ),
         trailing: Row( // Thêm nút Sửa/Xóa
           mainAxisSize: MainAxisSize.min, // Giữ kích thước nhỏ nhất
           children: [
             IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                tooltip: 'Chỉnh sửa',
                onPressed: () {
                   // Điều hướng đến màn hình sửa sản phẩm, truyền product vào
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(productToEdit: product)))
                      .then((_) => _refreshData()); // Refresh lại sau khi sửa
                },
             ),
             IconButton(
                icon: const Icon(Icons.delete_outline, color: kHeartColor, size: 20),
                tooltip: 'Xóa sản phẩm',
                onPressed: () => _confirmDeleteProduct(context, product), // Gọi hàm xác nhận xóa
             ),
           ],
         ),
         onTap: () {
            // Điều hướng đến chi tiết sản phẩm
             Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)));
         },
      );
  }

  // --- Hàm xác nhận xóa sản phẩm ---
  Future<void> _confirmDeleteProduct(BuildContext context, Product product) async {
     final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
           return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text('Bạn có chắc muốn xóa sản phẩm "${product.title}" không? Hành động này không thể hoàn tác.'),
              actions: <Widget>[
                 TextButton(
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                 ),
                 TextButton(
                    style: TextButton.styleFrom(foregroundColor: kHeartColor),
                    child: const Text('Xóa'),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                 ),
              ],
           );
        },
     );

     if (confirmed == true && context.mounted) {
        try {
           // Dùng read vì đang ở trong callback
           final productService = context.read<ProductService>();
           // --- GỌI API XÓA THỰC SỰ (CẦN THÊM Ở BACKEND VÀ ProductService) ---
           // await productService.deleteProduct(product.id);
           print("Gọi API DELETE /products/${product.id} (Mô phỏng)");

           if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Đã xóa sản phẩm "${product.title}" (Mô phỏng)')),
              );
              _refreshData(); // Tải lại danh sách sau khi xóa
           }
        } catch (e) {
           print("Lỗi xóa sản phẩm: $e");
           if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Lỗi xóa sản phẩm: $e'), backgroundColor: kHeartColor),
              );
           }
        }
     }
  }
}

