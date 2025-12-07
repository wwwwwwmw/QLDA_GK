import 'package:ecom_frontend/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// <<< THÊM IMPORT OrderService và Order >>>
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/models/order.dart';
// <<< THÊM IMPORT VnpayService >>>
import 'package:ecom_frontend/services/vnpay_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để chỉ rebuild khi CartProvider thay đổi
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text("Giỏ hàng của tôi"),
            actions: [
              if (cartProvider.cart != null &&
                  cartProvider.cart!.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: "Xóa tất cả",
                  onPressed: () => _confirmClearCart(context, cartProvider),
                ),
            ],
          ),
          body: _buildBody(context, cartProvider),
          bottomNavigationBar: _buildBottomBar(context, cartProvider),
        );
      },
    );
  }

  // Hộp thoại xác nhận xóa tất cả
  Future<void> _confirmClearCart(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc muốn xóa tất cả sản phẩm khỏi giỏ hàng?',
          ),
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
        await cartProvider.clearCart();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa toàn bộ giỏ hàng'),
              backgroundColor: kPrimaryColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa giỏ hàng: $e'),
              backgroundColor: kHeartColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildBody(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.status == CartStatus.loading &&
        cartProvider.cart == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }

    if (cartProvider.status == CartStatus.error && cartProvider.cart == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: kHeartColor, size: 60),
              const SizedBox(height: kDefaultPadding),
              Text(
                "Lỗi tải giỏ hàng:\n${cartProvider.errorMessage ?? 'Lỗi không xác định'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: kHeartColor),
              ),
              const SizedBox(height: kDefaultPadding),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: () => cartProvider.fetchCart(force: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: kDefaultPadding),
            const Text(
              "Giỏ hàng của bạn đang trống.",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: kDefaultPadding * 2),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text("Tiếp tục mua sắm"),
            ),
          ],
        ),
      );
    }

    final cart = cartProvider.cart!;

    return RefreshIndicator(
      onRefresh: () => cartProvider.fetchCart(force: true),
      color: kPrimaryColor,
      child: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _buildCartItem(context, item, cartProvider);
            },
            separatorBuilder: (context, index) => const Divider(
              height: kDefaultPadding * 1.5,
              thickness: 1,
              color: kOffWhiteColor,
            ),
          ),
          const SizedBox(height: kDefaultPadding * 1.5),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        try {
          await cartProvider.removeFromCart(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Đã xóa "${item.title}"')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi xóa sản phẩm: $e'),
                backgroundColor: kHeartColor,
              ),
            );
          }
        }
      },
      background: Container(
        color: kHeartColor.withOpacity(0.8),
        padding: const EdgeInsets.only(right: 20.0),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: kOffWhiteColor,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.error_outline,
                              color: kSecondaryTextColor,
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: kSecondaryTextColor,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyFormatter.format(item.finalPrice ?? item.price),
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.discountPercentage != null &&
                          item.discountPercentage! > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            currencyFormatter.format(item.price),
                            style: const TextStyle(
                              fontSize: 13,
                              color: kSecondaryTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildQuantityButtons(context, item, cartProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButtons(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    bool isUpdating = false;

    return StatefulBuilder(
      builder: (context, setQtyState) {
        return Container(
          decoration: BoxDecoration(
            color: kOffWhiteColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.remove,
                    color: item.qty > 1 && !isUpdating
                        ? kTextColor
                        : kSecondaryTextColor.withOpacity(0.5),
                    size: 18,
                  ),
                  onPressed: (isUpdating || item.qty <= 0)
                      ? null
                      : () async {
                          setQtyState(() => isUpdating = true);
                          try {
                            await cartProvider.updateItemQuantity(
                              item.id,
                              item.qty - 1,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setQtyState(() => isUpdating = false);
                            }
                          }
                        },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        item.qty.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTextColor,
                        ),
                      ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add,
                    color: !isUpdating
                        ? kTextColor
                        : kSecondaryTextColor.withOpacity(0.5),
                    size: 18,
                  ),
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setQtyState(() => isUpdating = true);
                          try {
                            await cartProvider.updateItemQuantity(
                              item.id,
                              item.qty + 1,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setQtyState(() => isUpdating = false);
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    final bool isEmpty =
        cartProvider.cart == null || cartProvider.cart!.items.isEmpty;
    final double subtotal = isEmpty ? 0.0 : cartProvider.cart!.subtotal;
    String? orderIdForPayment;
    bool _isCheckingOut = false;

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding).copyWith(
        top: kDefaultPadding * 0.75,
        bottom: kDefaultPadding + MediaQuery.of(context).padding.bottom / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tạm tính (${cartProvider.cart?.items.length ?? 0} sản phẩm)",
                style: const TextStyle(
                  fontSize: 16,
                  color: kSecondaryTextColor,
                ),
              ),
              Text(
                currencyFormatter.format(subtotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding),
          StatefulBuilder(
            builder: (context, setCheckoutState) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (isEmpty || _isCheckingOut)
                      ? null
                      : () async {
                          // --- Bắt đầu logic thanh toán VNPay ---
                          setCheckoutState(() => _isCheckingOut = true);
                          Order? newOrder; // Khai báo newOrder ở đây
                          final cartProv = context
                              .read<CartProvider>(); // Thêm dòng này

                          try {
                            // 1. Tạo Order trên Backend trước khi thanh toán
                            print("--- Bắt đầu quy trình thanh toán ---");
                            print("Bước 1: Tạo đơn hàng từ giỏ hàng...");
                            final orderService = context.read<OrderService>();
                            newOrder = await orderService.createOrderFromCart();
                            orderIdForPayment = newOrder.id;
                            print(
                              "Tạo đơn hàng thành công: ID = $orderIdForPayment, Tổng = ${newOrder.total}",
                            );

                            if (orderIdForPayment == null || newOrder == null) {
                              throw Exception("Không thể tạo mã đơn hàng.");
                            }

                            // --- Gọi VNPay ---
                            final vnpayService = context.read<VnpayService>();
                            // 2. Lấy URL thanh toán từ backend
                            print(
                              "Bước 2: Lấy URL thanh toán VNPay cho Order $orderIdForPayment, Số tiền ${newOrder.total}",
                            );
                            final paymentUrl = await vnpayService
                                .createPaymentUrl(
                                  orderId: orderIdForPayment!,
                                  amount: newOrder.total,
                                );

                            if (paymentUrl != null) {
                              // 3. Điều hướng sang WebView
                              print(
                                "Bước 3: Điều hướng tới màn hình WebView VNPay...",
                              );
                              if (context.mounted) {
                                Navigator.of(context).pushNamed(
                                  VnpayWebViewScreen.routeName,
                                  arguments: {
                                    'paymentUrl': paymentUrl,
                                    // 'orderId': orderIdForPayment,
                                  },
                                );
                              }
                            } else {
                              throw Exception(
                                "Không lấy được URL thanh toán VNPay.",
                              );
                            }
                            // --- Kết thúc logic VNPay ---
                          } catch (e) {
                            // Xử lý lỗi (chung cho cả tạo order và VNPay)
                            print("Lỗi quy trình thanh toán: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Lỗi thanh toán: ${e.toString()}",
                                  ),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            // Luôn dừng loading nút
                            if (context.mounted) {
                              setCheckoutState(() => _isCheckingOut = false);
                            }
                            print("--- Kết thúc quy trình thanh toán ---");
                          }
                          // --- Kết thúc logic thanh toán ---
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isCheckingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tiến hành đặt hàng",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock_outline, size: 20),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
