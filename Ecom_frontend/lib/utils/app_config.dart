import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Tự động chọn baseURL dựa trên môi trường
  static String get baseUrl {
    if (kDebugMode) {
      // Trong chế độ debug
      if (Platform.isAndroid) {
        // Nếu không kết nối được qua LAN, dùng ngrok
        return "https://natalee-vixenish-nonevilly.ngrok-free.dev";
        // return "http://192.168.1.12:8080"; // Backup: IP LAN
      } else if (Platform.isIOS) {
        return "http://localhost:8080"; // iOS simulator
      }
    }
    // Production hoặc các trường hợp khác
    return "https://natalee-vixenish-nonevilly.ngrok-free.dev";
  }
}
