import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyOrdersScreen extends StatefulWidget {
  // Định nghĩa routeName để dễ dàng điều hướng nếu cần
  static const String routeName = '/my-orders';

  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>> _ordersFuture;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchMyOrders();
  }

  // Lấy đơn hàng từ service
  Future<List<Order>> _fetchMyOrders() async {
    final orderService = context.read<OrderService>();
    try {
      return await orderService.getMyOrders();
    } catch (e) {
      // Ném lỗi để FutureBuilder xử lý
      throw Exception('Lỗi tải đơn hàng: ${e.toString()}');
    }
  }

  // Làm mới danh sách
  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: kPrimaryColor,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            // Đang tải
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              );
            }
            // Có lỗi
            else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: kHeartColor,
                        size: 60,
                      ),
                      const SizedBox(height: kDefaultPadding),
                      Text(
                        'Lỗi: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kHeartColor),
                      ),
                      const SizedBox(height: kDefaultPadding),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Thử lại"),
                        onPressed: _refreshOrders,
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
            // Có dữ liệu
            else if (snapshot.hasData) {
              final orders = snapshot.data!;
              // Không có đơn hàng
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: kDefaultPadding),
                      const Text(
                        'Bạn chưa có đơn hàng nào.',
                        style: TextStyle(
                          fontSize: 16,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Hiển thị danh sách
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 2,
                ),
                itemCount: orders.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[200],
                  indent: kDefaultPadding,
                  endIndent: kDefaultPadding,
                ),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: kDefaultPadding / 1.5, // Tăng padding dọc chút
                    ),
                    // --- SỬA Ở ĐÂY: Thêm hình ảnh vào leading ---
                    leading: SizedBox(
                      width: 60, // Kích thước ảnh
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Bo góc ảnh
                        child:
                            (order.firstItemImageUrl != null &&
                                order.firstItemImageUrl!.isNotEmpty)
                            ? Image.network(
                                order.firstItemImageUrl!,
                                fit: BoxFit.cover, // Cover để lấp đầy khung
                                // Placeholder khi đang tải
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  kPrimaryColor,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                // Icon hiển thị khi lỗi ảnh
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                                    ),
                              )
                            : Container(
                                // Placeholder nếu không có URL ảnh
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                    // --- KẾT THÚC SỬA ---
                    title: Text(
                      'Mã đơn: ${order.code}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Ngày đặt: ${_dateFormatter.format(order.createdAt.toLocal())}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: kSecondaryTextColor,
                          ), // Giảm size chữ
                        ),
                        const SizedBox(height: 4), // Tăng khoảng cách
                        Text(
                          'Tổng tiền: ${_currencyFormatter.format(order.total)}',
                          style: const TextStyle(
                            color: kBrownDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ), // Tăng size chữ giá
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getOrderStatusText(order.status),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ), // Giảm size chữ trạng thái
                      ),
                      backgroundColor: _getOrderStatusColor(order.status),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ), // Giảm padding dọc
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ), // Bo tròn hơn
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // Giảm vùng chạm
                      side: BorderSide.none, // Bỏ viền
                    ),
                    onTap: () {
                      // TODO: Điều hướng đến trang chi tiết đơn hàng (nếu cần)
                      print('Xem chi tiết đơn hàng: ${order.id}');
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
                    },
                  );
                },
              );
            }
            // Trường hợp khác
            else {
              return const Center(child: Text('Không có dữ liệu đơn hàng.'));
            }
          },
        ),
      ),
    );
  }

  // --- Helper functions ---
  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'payment_failed':
        return 'Thanh toán lỗi';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'paid':
        return Colors.green.shade600;
      case 'payment_failed':
        return kHeartColor;
      case 'processing':
        return Colors.blue.shade600;
      case 'shipped':
        return Colors.purple.shade600;
      case 'delivered':
        return kPrimaryColor;
      case 'cancelled':
        return kSecondaryTextColor;
      default:
        return Colors.grey.shade500;
    }
  }
}
