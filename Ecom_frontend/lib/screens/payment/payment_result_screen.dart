import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';

class PaymentResultScreen extends StatefulWidget {
  // Định nghĩa routeName để dễ dàng điều hướng
  static const String routeName = '/payment-result';

  final String orderId;
  final String
  initialStatus; // Trạng thái sơ bộ từ deep link ('success', 'failed', 'unknown')
  final String? message; // Tin nhắn từ backend return handler (nếu có)
  final String? vnpResponseCode; // Mã phản hồi VNPay từ return handler (nếu có)

  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.initialStatus,
    this.message,
    this.vnpResponseCode,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  String?
  _finalOrderStatus; // Trạng thái cuối cùng lấy từ backend ('paid', 'pending', 'payment_failed', etc.)
  String? _errorMessage;
  bool _isLoading = true; // Bắt đầu bằng trạng thái loading

  @override
  void initState() {
    super.initState();
    // Gọi API để kiểm tra trạng thái thực tế từ backend ngay khi màn hình được tạo
    _checkFinalOrderStatus();
  }

  Future<void> _checkFinalOrderStatus() async {
    // Đảm bảo widget vẫn còn tồn tại trước khi cập nhật state
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderService = context.read<OrderService>();
      print(
        "PaymentResultScreen: Đang kiểm tra trạng thái cuối cùng cho Đơn hàng ${widget.orderId}",
      );
      // Gọi hàm trong OrderService
      final statusResult = await orderService.checkOrderStatus(widget.orderId);

      if (mounted) {
        setState(() {
          _finalOrderStatus = statusResult; // Lưu trạng thái cuối cùng
          _isLoading = false;
          print(
            "PaymentResultScreen: Đã nhận trạng thái cuối cùng: $_finalOrderStatus",
          );
        });

        if (_finalOrderStatus == 'paid' && context.mounted) {
          print("Thanh toán thành công, làm mới giỏ hàng...");
          context.read<CartProvider>().fetchCart(force: true);
        }
      }
    } catch (e) {
      print("PaymentResultScreen: Lỗi khi kiểm tra trạng thái đơn hàng: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          // Nếu lỗi, tạm thời vẫn dựa vào initialStatus để hiển thị gì đó
          _finalOrderStatus = widget.initialStatus == 'success'
              ? 'pending'
              : 'failed'; // Giả định là pending nếu initial là success nhưng check lỗi
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String title;
    String displayMessage;

    // --- Hiển thị dựa trên trạng thái loading, lỗi, hoặc kết quả cuối cùng ---
    if (_isLoading) {
      icon = Icons.hourglass_empty_rounded;
      iconColor = Colors.orange.shade700;
      title = "Đang xác nhận...";
      displayMessage =
          "Hệ thống đang kiểm tra kết quả thanh toán cuối cùng từ VNPay. Vui lòng chờ...";
    } else if (_errorMessage != null) {
      icon = Icons.error_outline_rounded;
      iconColor = kHeartColor;
      title = "Lỗi xác nhận";
      displayMessage =
          "Không thể kiểm tra trạng thái đơn hàng:\n$_errorMessage";
    } else {
      // Dùng _finalOrderStatus (đã cập nhật từ backend) là nguồn tin cậy nhất
      bool isSuccess =
          _finalOrderStatus == 'paid'; // Chỉ coi 'paid' là thành công

      icon = isSuccess
          ? Icons.check_circle_outline_rounded
          : Icons.highlight_off_rounded;
      iconColor = isSuccess ? Colors.green.shade600 : kHeartColor;
      title = isSuccess ? "Thanh toán thành công!" : "Thanh toán thất bại";

      // Tạo thông điệp dựa trên trạng thái cuối cùng
      if (isSuccess) {
        displayMessage =
            widget.message ??
            "Đơn hàng của bạn đã được thanh toán thành công. Cảm ơn bạn đã mua hàng!";
      } else if (_finalOrderStatus == 'payment_failed') {
        displayMessage =
            widget.message ??
            "Thanh toán không thành công. Vui lòng thử lại hoặc chọn phương thức khác.";
        if (widget.vnpResponseCode != null && widget.vnpResponseCode != '00') {
          // Hiển thị thêm mã lỗi VNPay nếu có và không phải là '00'
          displayMessage += "\n(Mã lỗi VNPay: ${widget.vnpResponseCode})";
        }
      } else if (_finalOrderStatus == 'pending') {
        displayMessage =
            "Giao dịch đang chờ xử lý. Chúng tôi sẽ cập nhật trạng thái đơn hàng sớm nhất.";
        icon = Icons.pending_rounded; // Đổi icon cho trạng thái chờ
        iconColor = Colors.orange.shade800;
        title = "Giao dịch đang chờ";
      } else {
        // Các trạng thái khác ('not_found', 'forbidden', null,...)
        displayMessage =
            "Không thể xác định trạng thái thanh toán. Vui lòng liên hệ hỗ trợ.";
        icon = Icons.help_outline_rounded;
        iconColor = kSecondaryTextColor;
        title = "Trạng thái không xác định";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả thanh toán"),
        automaticallyImplyLeading: false, // Ẩn nút back mặc định
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 100),
              const SizedBox(height: kDefaultPadding * 1.5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: iconColor, // Dùng màu của icon
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kDefaultPadding),
              // Hiển thị mã đơn hàng
              Text(
                "Mã đơn hàng: ${widget.orderId}",
                style: const TextStyle(fontSize: 16, color: kTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kDefaultPadding / 2),
              // Hiển thị thông điệp chi tiết
              Text(
                displayMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: kSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kDefaultPadding * 2.5),
              // Nút quay về trang chủ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text("Về trang chủ"),
                  onPressed: () {
                    // Pop tất cả các màn hình về màn hình đầu tiên (thường là trang chủ)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
