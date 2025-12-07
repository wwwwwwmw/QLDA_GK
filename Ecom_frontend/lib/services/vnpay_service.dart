import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart'; // Dùng để mở URL trong trình duyệt

class VnpayService {
  final Dio _dio;

  VnpayService(this._dio);

  // ===== TẠO URL THANH TOÁN VNPay =====
  // Gọi API backend (POST /payment/vnpay/create_payment_url)
  // để tạo đường dẫn thanh toán qua VNPay cho đơn hàng cụ thể
  Future<String?> createPaymentUrl({
    required String orderId,
    required double amount,
    String language = 'vn',
    String? bankCode, // Tùy chọn mã ngân hàng
  }) async {
    try {
      print("Gửi yêu cầu tạo VNPay URL (Order ID: $orderId, Số tiền: $amount)");

      final response = await _dio.post(
        '/payment/vnpay/create_payment_url',
        data: {
          'orderId': orderId,
          'amount': amount,
          'language': language,
          if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
        },
      );

      if (response.data != null && response.data['paymentUrl'] != null) {
        print("Đã nhận được VNPay URL: ${response.data['paymentUrl']}");
        return response.data['paymentUrl'];
      } else {
        throw Exception('Không nhận được URL thanh toán từ máy chủ');
      }
    } on DioException catch (e) {
      // Bắt lỗi từ backend
      print("DioException khi tạo VNPay URL: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tạo URL thanh toán VNPay',
      );
    } catch (e) {
      // Bắt lỗi không mong muốn
      print("Lỗi không xác định khi tạo VNPay URL: $e");
      throw Exception('Lỗi không xác định khi tạo URL thanh toán VNPay');
    }
  }

  // ===== MỞ URL THANH TOÁN =====
  // Mở đường dẫn VNPay trong trình duyệt ngoài của thiết bị
  // Trả về true nếu mở thành công, false nếu thất bại
  Future<bool> launchVNPayUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      print("Không thể mở $url");
      return false;
    }

    // Mở bằng trình duyệt ngoài (cách an toàn và phổ biến nhất)
    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      print("Không thể mở $url bằng trình duyệt ngoài");
      // Có thể thử lại với WebView nếu cần:
      // await launchUrl(url, mode: LaunchMode.inAppWebView);
    }
    return launched;
  }
}
