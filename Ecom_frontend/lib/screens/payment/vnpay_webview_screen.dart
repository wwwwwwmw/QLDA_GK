import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/screens/payment/payment_result_screen.dart';

class VnpayWebViewScreen extends StatefulWidget {
  static const String routeName = '/vnpay-webview';

  final String paymentUrl;

  const VnpayWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<VnpayWebViewScreen> createState() => _VnpayWebViewScreenState();
}

class _VnpayWebViewScreenState extends State<VnpayWebViewScreen> {
  // Controller cho WebView
  late final WebViewController _controller;
  // Trạng thái loading ban đầu
  bool _isLoadingPage = true;
  // Lưu URL deep link mong muốn (để so sánh)
  final String _targetReturnScheme =
      'khoiecomapp'; // << Đặt scheme của bạn ở đây
  final String _targetReturnHost =
      'payment-result'; // << Đặt host của bạn ở đây

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Bật JavaScript
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Cập nhật trạng thái loading nếu cần
            print('WebView đang tải (tiến độ: $progress%)');
            if (progress == 100 && _isLoadingPage && mounted) {
              setState(() {
                _isLoadingPage = false; // Hoàn thành tải trang ban đầu
              });
            }
          },
          onPageStarted: (String url) {
            print('Bắt đầu tải trang: $url');
            if (mounted) {
              setState(() {
                _isLoadingPage = true; // Bắt đầu tải trang mới
              });
            }
          },
          onPageFinished: (String url) {
            print('Hoàn tất tải trang: $url');
            if (mounted) {
              setState(() {
                _isLoadingPage = false; // Hoàn thành tải trang mới
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('''Lỗi tài nguyên trang:
  mã lỗi: ${error.errorCode}
  mô tả: ${error.description}
  loại lỗi: ${error.errorType}
  khung chính: ${error.isForMainFrame}
''');
            // Có thể hiển thị lỗi cho người dùng nếu cần
            if (mounted) {
              setState(() {
                _isLoadingPage = false;
              });
              // Cân nhắc pop màn hình hoặc hiển thị thông báo lỗi
            }
          },
          // --- QUAN TRỌNG: Xử lý chuyển hướng ---
          onNavigationRequest: (NavigationRequest request) {
            print('Cho phép điều hướng tới: ${request.url}');
            final Uri uri = Uri.parse(request.url);

            // Kiểm tra xem có phải là deep link trả về không
            if (uri.scheme == _targetReturnScheme &&
                uri.host == _targetReturnHost) {
              print('Chặn và xử lý deep link trả về: ${request.url}');
              // Ngăn WebView điều hướng đến deep link
              _handleReturnUrl(uri); // Gọi hàm xử lý và điều hướng
              return NavigationDecision.prevent;
            }

            // Cho phép điều hướng đến các URL khác (của VNPay)
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl)); // Tải URL thanh toán ban đầu
  }

  // Hàm xử lý khi bắt được URL trả về
  void _handleReturnUrl(Uri uri) {
    if (!mounted) return; // Kiểm tra

    print("Xử lý kết quả thanh toán từ WebView...");
    final orderId = uri.queryParameters['orderId'];
    final status = uri.queryParameters['status'];
    final message = uri.queryParameters['message'];
    final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];

    print(
      "Tham số parse được: orderId=$orderId, status=$status, message=$message, vnpCode=$vnpResponseCode",
    );

    if (orderId != null) {
      // --- Điều hướng đến màn hình kết quả ---
      // Pop màn hình WebView và Push màn hình kết quả
      // Dùng pushReplacementNamed để không quay lại WebView từ màn hình kết quả
      Navigator.of(context).pushReplacementNamed(
        PaymentResultScreen.routeName,
        arguments: {
          'orderId': orderId,
          'initialStatus': status ?? 'unknown',
          'message': message,
          'vnpResponseCode': vnpResponseCode,
        },
      );
    } else {
      print("Deep link kết quả thanh toán thiếu orderId.");
      // Hiển thị lỗi và pop về màn hình trước (Cart)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi xử lý kết quả: Thiếu mã đơn hàng.")),
      );
      Navigator.of(context).pop(); // Quay lại màn hình giỏ hàng
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Hỏi người dùng xác nhận hủy nếu họ bấm back
            _confirmCancelPayment();
          },
        ),
        actions: [
          // Thêm nút refresh để tải lại nếu cần
          if (_isLoadingPage)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
        ],
      ),
      // Dùng Stack để hiển thị loading indicator đè lên WebView
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Hiển thị loading indicator ở giữa màn hình khi trang đang tải
          if (_isLoadingPage)
            const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
        ],
      ),
    );
  }

  // Hàm hỏi xác nhận hủy thanh toán
  Future<void> _confirmCancelPayment() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hủy thanh toán?'),
          content: const Text(
            'Bạn có chắc muốn hủy bỏ giao dịch thanh toán này?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ở lại'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kHeartColor),
              child: const Text('Hủy thanh toán'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Nếu xác nhận hủy, quay lại màn hình trước đó (CartScreen)
      Navigator.of(context).pop();
    }
  }
}
