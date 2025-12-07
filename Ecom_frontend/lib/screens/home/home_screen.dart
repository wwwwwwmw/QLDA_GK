import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/screens/search/search_screen.dart';
import 'package:ecom_frontend/screens/seller/add_product_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';

class CountdownTicker extends StatefulWidget {
  final Duration initial;
  const CountdownTicker({super.key, required this.initial});

  @override
  State<CountdownTicker> createState() => _CountdownTickerState();
}

class _CountdownTickerState extends State<CountdownTicker> {
  late Duration _left;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _left = widget.initial;
    _ticker = Ticker(_tick)..start();
  }

  void _tick(Duration _) {
    if (!mounted) return;
    if (_left.inSeconds <= 0) {
      _ticker.stop();
      return;
    }
    // chỉ rebuild mỗi 1 giây
    final next = _left - const Duration(seconds: 1);
    if (next.inSeconds != _left.inSeconds) {
      setState(() => _left = next);
    } else {
      _left = next;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<String> _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      two(d.inHours),
      two(d.inMinutes.remainder(60)),
      two(d.inSeconds.remainder(60)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final parts = _format(_left);
    return Row(
      children: parts.asMap().entries.map((entry) {
        final value = entry.value;
        final isLast = entry.key == parts.length - 1;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  ":",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// Ticker nhẹ không kéo theo SchedulerBinding (tránh thêm dependency)
class Ticker {
  Ticker(this.onTick);
  final void Function(Duration elapsed) onTick;
  bool _running = false;
  Duration _elapsed = Duration.zero;

  void start() {
    if (_running) return;
    _running = true;
    _schedule();
  }

  void _schedule() async {
    while (_running) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_running) break;
      _elapsed += const Duration(seconds: 1);
      onTick(_elapsed);
    }
  }

  void stop() => _running = false;
  void dispose() => stop();
}
// ================================================================================

// --- Widget chính giữ trạng thái các trang ---
class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 0; // Trang hiện tại được chọn (bắt đầu từ 0)

  static List<Widget> _widgetOptions(BuildContext context) {
    return [
      const HomeScreenContent(), // Home (index 0)
      const SearchScreen(), // Search (index 1)
      const ProfileScreen(), // Profile (index 2) - Sử dụng Widget mới
    ];
  }

  void _onItemTapped(int index) {
    final userRole = context.read<AuthProvider>().currentUser?.role;
    final bool canAddProduct = userRole == 'ADMIN' || userRole == 'SELLER';
    int actualIndex = index;

    if (canAddProduct) {
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        );
        return;
      } else if (index > 2) {
        actualIndex = index - 1; 
      }
    }

    if (actualIndex < _widgetOptions(context).length &&
        actualIndex != _selectedIndex) {
      setState(() => _selectedIndex = actualIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions(context),
      ),
      bottomNavigationBar: _buildBottomNavBar(
        context,
        _selectedIndex,
        _onItemTapped,
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    int currentActualIndex,
    ValueChanged<int> onTap,
  ) {
    final userRole = context.select(
      (AuthProvider provider) => provider.currentUser?.role,
    );
    final bool canAddProduct = userRole == 'ADMIN' || userRole == 'SELLER';

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Tìm kiếm',
      ),
      if (canAddProduct)
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 28),
          activeIcon: Icon(Icons.add_circle, size: 28),
          label: 'Thêm',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ];

    int displayIndex = currentActualIndex;
    if (canAddProduct && currentActualIndex >= 2) {
      displayIndex = currentActualIndex + 1;
    }

    return BottomNavigationBar(
      items: items,
      currentIndex: displayIndex,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: kSecondaryTextColor.withOpacity(0.7),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: onTap,
    );
  }
}

// --- Nội dung trang Home ---
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _bannerCurrentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  // ===== Helper hiển thị ảnh từ URL thường hoặc data URL base64 =====
  Widget _buildImageFromUrlOrBase64(
    String? url, {
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    double? width,
    double? height,
  }) {
    final Widget ph =
        placeholder ??
        Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported_outlined, size: 30),
        );

    if (url == null || url.isEmpty) return ph;

    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Part = commaIndex != -1
            ? url.substring(commaIndex + 1)
            : url;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => ph,
        );
      } catch (_) {
        return ph;
      }
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (c, e, s) => ph,
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
      context.read<CartProvider>().fetchCart();
    });
  }

  // --- AppBar (Search + Cart badge + Notifications) ---
  AppBar _buildAppBar(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 0,
      leadingWidth: 0,
      titleSpacing: kDefaultPadding,
      title: TextField(
        onTap: () {
          final wrapperState = context
              .findAncestorStateOfType<_MainScreenWrapperState>();
          wrapperState?._onItemTapped(1); // sang tab Search
        },
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Tìm kiếm sản phẩm",
          hintStyle: TextStyle(
            color: kSecondaryTextColor.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: kSecondaryTextColor.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: kOffWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
        ),
      ),
      actions: [
        // --- Icon Giỏ hàng ---
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: const Color.fromARGB(
                  255,
                  253,
                  253,
                  253,
                ).withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  // SỬA: Xóa const
                  MaterialPageRoute(builder: (_) => CartScreen()),
                  // --- KẾT THÚC SỬA ---
                );
              },
            ),
            if (cartProvider.cart != null &&
                cartProvider.cart!.items.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: kHeartColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Text(
                    cartProvider.cart!.items
                        .fold<int>(0, (sum, item) => sum + item.qty)
                        .toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // --- Icon Thông báo ---
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withOpacity(0.7),
              ),
              onPressed: () {
                /* TODO: Notifications */
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: kHeartColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                child: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  // --- Banner carousel ---
  Widget _buildBannerCarousel(BuildContext context) {
    final List<String> bannerImages = [
      'lib/assets/images/banner_1.jpg',
      'lib/assets/images/banner_2.jpg',
    ];

    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            viewportFraction: 0.92,
            enlargeCenterPage: false,
            enlargeFactor: 0.2,
            onPageChanged: (index, reason) {
              setState(() => _bannerCurrentIndex = index);
            },
          ),
          items: bannerImages.map((imgPath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: kOffWhiteColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print("Lỗi tải ảnh banner: $imgPath, $error");
                            return const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: kSecondaryTextColor,
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding * 1.5,
                            vertical: kDefaultPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Ưu đãi Năm Mới",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Giảm 40%",
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              CountdownTicker(
                                initial: Duration(
                                  hours: 2,
                                  minutes: 9,
                                  seconds: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withOpacity(
                  _bannerCurrentIndex == entry.key ? 0.9 : 0.3,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerRight,
            ),
            child: const Text(
              "Xem tất cả",
              style: TextStyle(
                fontSize: 13,
                color: kAccentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionHeader("Danh mục", () {
          final wrapperState = context
              .findAncestorStateOfType<_MainScreenWrapperState>();
          wrapperState?._onItemTapped(1);
        }),
        Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            if (provider.status == CategoryStatus.loading ||
                provider.status == CategoryStatus.initial) {
              return const SizedBox(
                height: 95,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  ),
                ),
              );
            }
            if (provider.status == CategoryStatus.error) {
              return SizedBox(
                height: 95,
                child: Center(
                  child: Text(
                    "Lỗi tải danh mục: ${provider.errorMessage ?? 'Lỗi không xác định'}",
                  ),
                ),
              );
            }
            if (provider.categories.isEmpty) {
              return const SizedBox(
                height: 95,
                child: Center(child: Text("Chưa có danh mục nào.")),
              );
            }

            final cats = provider.categories;
            return SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75,
                ),
                itemCount: cats.length,
                itemBuilder: (context, index) {
                  final cat = cats[index];
                  return GestureDetector(
                    onTap: () {
                      final wrapperState = context
                          .findAncestorStateOfType<_MainScreenWrapperState>();
                      wrapperState?._onItemTapped(1);
                    },
                    child: Container(
                      width: 85,
                      margin: const EdgeInsets.only(
                        right: kDefaultPadding * 0.75,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: kOffWhiteColor,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 55,
                            width: 55,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildImageFromUrlOrBase64(
                                cat.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularProductsSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionHeader("Sản phẩm nổi bật", () {
          /* TODO: Điều hướng */
        }),
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.status == ProductStatus.loading ||
                provider.status == ProductStatus.initial) {
              return const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              );
            }
            if (provider.status == ProductStatus.error) {
              return Center(
                heightFactor: 5,
                child: Text(
                  "Lỗi tải sản phẩm: ${provider.errorMessage ?? 'Lỗi không xác định'}",
                ),
              );
            }
            if (provider.products.isEmpty) {
              return const Center(
                heightFactor: 5,
                child: Text("Không có sản phẩm nào."),
              );
            }
            final popularProducts = provider.products.take(6).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 0.75,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68, // Điều chỉnh tỷ lệ này nếu cần
                crossAxisSpacing: kDefaultPadding * 0.75,
                mainAxisSpacing: kDefaultPadding * 0.75,
              ),
              itemCount: popularProducts.length,
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return _buildPopularProductCard(context, product);
              },
            );
          },
        ),
      ],
    );
  }

  // --- SỬA: Hàm xây dựng Card sản phẩm phổ biến ---
  Widget _buildPopularProductCard(BuildContext context, Product product) {
    bool hasDiscount =
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
          color: Colors.white, // Nền trắng thay vì kOffWhite
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ), // Thêm viền nhẹ
          boxShadow: [
            // Thêm đổ bóng nhẹ
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          // Dùng Column thay vì Stack để dễ căn chỉnh text
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Phần ảnh ---
            Expanded(
              flex: 3, // Ảnh chiếm nhiều không gian hơn
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ), // Bo góc trên
                child: Stack(
                  // Stack để đặt badge giảm giá lên ảnh
                  children: [
                    Center(
                      // Căn giữa ảnh
                      child: Padding(
                        padding: const EdgeInsets.all(
                          kDefaultPadding / 2,
                        ), // Padding nhỏ quanh ảnh
                        child:
                            (product.imageUrl == null ||
                                product.imageUrl!.isEmpty)
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: kSecondaryTextColor,
                                  size: 40,
                                ),
                              )
                            : _buildImageFromUrlOrBase64(
                                product.imageUrl,
                                fit: BoxFit
                                    .contain, // Contain để thấy rõ sản phẩm
                              ),
                      ),
                    ),
                    // Discount Badge (nếu có)
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kHeartColor.withOpacity(0.9), // Màu badge
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.discountPercentage!.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // --- Phần thông tin (Tên, Giá, Rating) ---
            Expanded(
              flex: 2, // Thông tin chiếm ít không gian hơn
              child: Padding(
                padding: const EdgeInsets.all(kDefaultPadding * 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: kTextColor,
                      ),
                      maxLines: 2, // Cho phép 2 dòng
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Giảm khoảng cách
                    // Hàng Giá và Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          CrossAxisAlignment.end, // Căn đáy cho đẹp
                      children: [
                        // --- SỬA: Hiển thị giá gốc và giá mới ---
                        Column(
                          // Dùng Column để giá gốc ở trên, giá mới ở dưới
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Giá mới (luôn hiển thị)
                            Text(
                              currencyFormatter.format(
                                product.finalPrice ?? product.price,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBrownDark, // Màu giá chính
                                fontSize: 16,
                              ),
                              maxLines: 1,
                            ),
                            // Giá gốc (chỉ hiển thị nếu có giảm giá)
                            if (hasDiscount)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 2.0,
                                ), // Khoảng cách nhỏ giữa 2 giá
                                child: Text(
                                  currencyFormatter.format(product.price),
                                  style: const TextStyle(
                                    fontSize: 12, // Nhỏ hơn giá mới
                                    color: kSecondaryTextColor,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: kHeartColor,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // --- KẾT THÚC SỬA ---

                        // Rating (nếu có)
                        if (product.rating != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: kStarColor,
                                size: 16,
                              ), // Kích thước sao nhỏ hơn
                              const SizedBox(width: 3),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12, // Kích thước rating nhỏ hơn
                                  color: kTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // const Spacer(), // Bỏ nếu không cần đẩy xuống
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- KẾT THÚC SỬA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProductProvider>().fetchProducts(),
            context.read<CategoryProvider>().fetchCategories(),
            context.read<CartProvider>().fetchCart(),
          ]);
        },
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: ListView(
          children: [
            SizedBox(height: kDefaultPadding * 2),
            _buildBannerCarousel(context),
            const SizedBox(height: kDefaultPadding / 2),
            _buildCategoriesSection(context),
            const SizedBox(height: kDefaultPadding / 2),
            _buildPopularProductsSection(context),
            const SizedBox(height: kDefaultPadding * 1.5),
          ],
        ),
      ),
    );
  }
}
