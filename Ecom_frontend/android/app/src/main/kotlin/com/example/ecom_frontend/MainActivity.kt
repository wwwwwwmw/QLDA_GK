package com.example.ecom_frontend

// SỬA: Import FlutterFragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity // <<< THÊM DÒNG NÀY
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity // BỎ DÒNG NÀY

// SỬA: Thay đổi FlutterActivity thành FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() { // <<< SỬA Ở ĐÂY
    // Không cần thay đổi code bên trong class nếu bạn chưa tùy chỉnh gì
    // Đảm bảo không có override configureFlutterEngine trừ khi cần
}