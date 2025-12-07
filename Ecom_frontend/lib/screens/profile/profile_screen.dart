import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecom_frontend/screens/orders/my_orders_screen.dart';
import 'package:ecom_frontend/screens/seller/my_products_store_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getVietnameseRole(String? role) {
    switch (role) {
      case 'USER':
        return 'Người dùng';
      case 'SELLER':
        return 'Người bán';
      case 'ADMIN':
        return 'Quản trị viên';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    // Kiểm tra vai trò Seller (đã sửa lỗi null)
    final bool isSeller = user?.role == 'SELLER';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Tài khoản'),
        automaticallyImplyLeading: false,
      ),
      body:
          user ==
              null // Hiển thị loading nếu user chưa có
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : ListView(
              padding: const EdgeInsets.all(kDefaultPadding),
              children: [
                // --- Phần thông tin người dùng ---
                const SizedBox(height: kDefaultPadding),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Center(
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName : '(Chưa có tên)',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Center(
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kSecondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Center(
                  // --- SỬA: Sử dụng hàm _getVietnameseRole ---
                  child: Chip(
                    label: Text(
                      _getVietnameseRole(user.role),
                    ), // Gọi hàm helper
                    backgroundColor: kPrimaryColor.withOpacity(0.2),
                    labelStyle: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ), // Thêm fontWeight
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // --- KẾT THÚC SỬA ---
                ),
                const SizedBox(height: kDefaultPadding * 1.5),
                const Divider(),
                const SizedBox(height: kDefaultPadding),
                // --- KẾT THÚC Phần thông tin người dùng ---

                // --- Mục Đơn hàng của tôi ---
                ListTile(
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                    color: kPrimaryColor,
                  ),
                  title: const Text('Đơn hàng của tôi'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: kSecondaryTextColor,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
                      ),
                    );
                  },
                ),

                // --- Mục Sản phẩm đã đăng (chỉ cho Seller) ---
                if (isSeller) ...[
                  const SizedBox(height: kDefaultPadding / 2),
                  ListTile(
                    leading: const Icon(
                      Icons.storefront_outlined,
                      color: kPrimaryColor,
                    ),
                    title: const Text('Sản phẩm đã đăng'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: kSecondaryTextColor,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProductsStoreScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  const Divider(),
                ],

                // --- Thêm các mục khác tại đây ---
                // ...
                const SizedBox(height: kDefaultPadding * 2),

                // --- Nút Đăng xuất ---
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Đăng xuất"),
                    // Chỉ enable nút khi user đã load xong
                    onPressed: user == null
                        ? null
                        : () => _confirmLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kHeartColor.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
    );
  }

  // Hàm xác nhận đăng xuất
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kHeartColor),
              child: const Text('Đăng xuất'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }
}
