import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // State & formatter
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch("");
    });
    // Lắng nghe thay đổi ô tìm kiếm
    _searchController.addListener(() {
      if (_searchController.text != _currentQuery) {
        _performSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lọc kết quả theo từ khóa
  void _performSearch(String query) {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query.toLowerCase();
    });

    final allProducts = context.read<ProductProvider>().products;

    if (_currentQuery.isEmpty) {
      _searchResults = List.from(allProducts);
    } else {
      _searchResults = allProducts.where((p) {
        final titleLower = p.title.toLowerCase();
        return titleLower.contains(_currentQuery);
      }).toList();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // AppBar có ô tìm kiếm
  AppBar _buildSearchBar(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false,
      titleSpacing: kDefaultPadding,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Tìm kiếm sản phẩm...",
          hintStyle: TextStyle(
            color: kSecondaryTextColor.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: kSecondaryTextColor.withOpacity(0.9),
            size: 22,
          ),
          filled: true,
          fillColor: kOffWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: kPrimaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: kSecondaryTextColor.withOpacity(0.7),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list_alt, color: kTextColor.withOpacity(0.8)),
          onPressed: () {
            // TODO: Bộ lọc
            print("Nhấn nút Bộ lọc");
          },
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  // Header kết quả
  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _currentQuery.isEmpty
                  ? "Hiển thị tất cả sản phẩm"
                  : 'Kết quả cho "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isLoading)
            Text(
              "${_searchResults.length} kết quả",
              style: const TextStyle(fontSize: 13, color: kSecondaryTextColor),
            ),
        ],
      ),
    );
  }

  // Lưới kết quả
  Widget _buildSearchResultsGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return const Center(child: Text("Không tìm thấy sản phẩm phù hợp."));
    }
    if (_searchResults.isEmpty && _currentQuery.isEmpty) {
      return const Center(child: Text("Nhập từ khóa để bắt đầu tìm kiếm."));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 1.5,
      ).copyWith(bottom: kDefaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: kDefaultPadding / 1.5,
        mainAxisSpacing: kDefaultPadding / 1.5,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _buildProductCard(context, _searchResults[index]),
    );
  }

  // Card sản phẩm
  Widget _buildProductCard(BuildContext context, Product product) {
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh + nút yêu thích
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: kOffWhiteColor,
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: kSecondaryTextColor,
                                    ),
                                  ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              kPrimaryColor,
                                            ),
                                      ),
                                    );
                                  },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: kSecondaryTextColor,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => print(
                        "Chuyển trạng thái yêu thích: ${product.title}",
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: Icon(
                          Icons.favorite_border,
                          color: kHeartColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin sản phẩm
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: kTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Giá + badge giảm giá
                      Row(
                        children: [
                          Text(
                            _currency.format(
                              product.finalPrice ?? product.price,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                              fontSize: 15,
                            ),
                          ),
                          if (hasDiscount)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${product.discountPercentage!.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Rating (nếu có)
                      if (product.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: kSecondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout tổng
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildSearchBar(context),
      body: Column(
        children: [
          _buildResultHeader(),
          Expanded(child: _buildSearchResultsGrid(context)),
        ],
      ),
    );
  }
}
