import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/login_screen.dart';
import 'package:ecom_frontend/screens/home/home_screen.dart';
import 'package:ecom_frontend/screens/payment/payment_result_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialLinkHandled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initDeepLinks();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    if (!_initialLinkHandled) {
      _initialLinkHandled = true;
      try {
        final initialUri = await _appLinks.getInitialLink();
        if (initialUri != null) _handleDeepLink(initialUri);
      } on PlatformException catch (_) {
        // ignore
      } on FormatException catch (_) {
        // ignore
      }
    }

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      _handleDeepLink(uri);
    }, onError: (err) {});
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    if (uri.scheme == 'khoiecomapp' && uri.host == 'payment-result') {
      final orderId = uri.queryParameters['orderId'];
      final status = uri.queryParameters['status'];
      final message = uri.queryParameters['message'];
      final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];

      if (orderId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              PaymentResultScreen.routeName,
              arguments: {
                'orderId': orderId,
                'initialStatus': status ?? 'unknown',
                'message': message,
                'vnpResponseCode': vnpResponseCode,
              },
            );
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Lỗi xử lý kết quả thanh toán: Thiếu mã đơn hàng.",
                ),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu app chưa khởi tạo deep links xong
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Lắng nghe thay đổi AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        switch (authProvider.authStatus) {
          case AuthStatus.authenticated:
            return const MainScreenWrapper();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.unknown:
          default:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}
