import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  // ===== Đăng nhập =====
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đăng nhập');
    }
  }

  // ===== Đăng ký tài khoản =====
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đăng ký');
    }
  }

  // ===== Xác thực email (OTP đăng ký) =====
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi xác thực OTP');
    }
  }

  // ===== Quên mật khẩu =====
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi gửi email khôi phục');
    }
  }

  // ===== Kiểm tra mã OTP khôi phục mật khẩu =====
  Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Mã xác thực không hợp lệ',
      );
    }
  }

  // ===== Đặt lại mật khẩu =====
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đặt lại mật khẩu');
    }
  }
}
