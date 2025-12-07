import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/app_config.dart';

class ApiClient {
  final Dio dio;
  final StorageService _storageService;

  ApiClient(this.dio, this._storageService) {
    // Cấu hình cơ bản
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    // Interceptor: gắn token và xử lý lỗi
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Đính kèm Access Token nếu có (trừ các endpoint auth)
          final accessToken = await _storageService.readToken('access_token');
          if (accessToken != null && !options.path.contains('/auth/')) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // 401: token hết hạn -> xóa token, buộc đăng nhập lại
          if (e.response?.statusCode == 401) {
            debugPrint("Token hết hạn, yêu cầu đăng nhập lại");
            await _storageService.deleteAllTokens();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
