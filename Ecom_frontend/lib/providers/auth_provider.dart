import 'package:ecom_frontend/models/user.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';

/// Trạng thái xác thực người dùng
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  final UserService _userService;

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  String? _accessToken;
  String? get accessToken => _accessToken;

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthProvider(this._authService, this._storageService, this._userService) {
    _init();
  }

  /// ===== Khởi tạo và kiểm tra trạng thái đăng nhập =====
  Future<void> _init() async {
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storageService.readToken('access_token');
    if (token != null) {
      _accessToken = token;
      try {
        _currentUser = await _userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
      } catch (e) {
        await logout();
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// ===== Đăng nhập =====
  Future<String?> login(String email, String password) async {
    try {
      final responseData = await _authService.login(email, password);
      final accessToken = responseData['access_token'];

      if (accessToken is String) {
        _accessToken = accessToken;
        await _storageService.saveToken('access_token', accessToken);

        _currentUser = await _userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return null;
      } else {
        throw Exception("API không trả về access_token hợp lệ.");
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _currentUser = null;
      await _storageService.deleteAllTokens();
      notifyListeners();
      return e.toString();
    }
  }

  /// ===== Đăng xuất =====
  Future<void> logout() async {
    await _storageService.deleteAllTokens();
    _accessToken = null;
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// ===== Đăng ký tài khoản mới =====
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// ===== Xác thực email sau khi đăng ký =====
  Future<String?> verifyEmail(String email, String code) async {
    try {
      await _authService.verifyEmail(email, code);
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// ===== Quên mật khẩu (gửi mã OTP về email) =====
  Future<String?> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// ===== Kiểm tra mã OTP đặt lại mật khẩu =====
  Future<String?> verifyResetCode(String email, String code) async {
    try {
      await _authService.verifyResetCode(email, code);
      // Không thay đổi trạng thái, vì người dùng chưa đăng nhập lại
      return null;
    } catch (e) {
      return e.toString().contains("400") || e.toString().contains("Mã")
          ? "Mã xác thực không đúng hoặc đã hết hạn."
          : e.toString();
    }
  }

  /// ===== Đặt lại mật khẩu mới =====
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
