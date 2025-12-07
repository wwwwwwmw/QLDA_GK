import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  // Lưu token vào bộ nhớ an toàn (Secure Storage)
  Future<void> saveToken(String tokenKey, String tokenValue) async {
    await _storage.write(key: tokenKey, value: tokenValue);
  }

  // Đọc token từ bộ nhớ an toàn
  Future<String?> readToken(String tokenKey) async {
    return await _storage.read(key: tokenKey);
  }

  // Xóa token theo key
  Future<void> deleteToken(String tokenKey) async {
    await _storage.delete(key: tokenKey);
  }

  // Xóa toàn bộ token (thường dùng khi đăng xuất)
  Future<void> deleteAllTokens() async {
    await _storage.deleteAll();
  }
}
