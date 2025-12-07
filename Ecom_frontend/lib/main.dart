import 'package:dio/dio.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/app_wrapper.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
// import 'package:ecom_frontend/services/api_client.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/app_config.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/services/vnpay_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/screens/payment/payment_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// App thành Stateful để khởi tạo service một lần
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Khai báo service + Dio
  late final StorageService _storageService;
  late final Dio _dio;
  late final AuthService _authService;
  late final CartService _cartService;
  late final UserService _userService;
  late final CategoryService _categoryService;
  late final StoreService _storeService;
  late final ProductService _productService;
  late final OrderService _orderService;
  late final VnpayService _vnpayService;

  @override
  void initState() {
    super.initState();

    // Sử dụng baseUrl từ AppConfig thay vì hardcode
    _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

    _storageService = StorageService();

    // Interceptor: gắn token & log lỗi
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.readToken('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Không log lỗi cho các endpoint auth vì chúng không cần token
            if (!options.path.contains('/auth/')) {
              print("No auth token found for request to ${options.path}");
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print("Dio Error on ${e.requestOptions.path}: ${e.message}");
          if (e.response != null) {
            print(
              "Dio Error Response: ${e.response?.statusCode} ${e.response?.data}",
            );
          }
          if (e.response?.statusCode == 401) {
            print("Unauthorized request - need to handle logout");
            // TODO: cơ chế global để gọi logout từ AuthProvider nếu cần
          }
          return handler.next(e);
        },
      ),
    );

    // Khởi tạo service với Dio đã cấu hình
    _authService = AuthService(_dio);
    _cartService = CartService(_dio);
    _userService = UserService(_dio);
    _categoryService = CategoryService(_dio);
    _storeService = StoreService(_dio);
    _productService = ProductService(_dio);
    _orderService = OrderService(_dio);
    _vnpayService = VnpayService(_dio);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Cấp phát services và providers
      providers: [
        Provider(create: (_) => _storageService),
        Provider(create: (_) => _authService),
        Provider(create: (_) => _cartService),
        Provider(create: (_) => _userService),
        Provider(create: (_) => _categoryService),
        Provider(create: (_) => _storeService),
        Provider(create: (_) => _productService),
        Provider(create: (_) => _orderService),
        Provider(create: (_) => _vnpayService),

        // State management
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_authService, _storageService, _userService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(_cartService, null),
          update: (_, authProvider, __) =>
              CartProvider(_cartService, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(_productService)..fetchProducts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(_categoryService)..fetchCategories(),
        ),
      ],
      child: MaterialApp(
        title: 'E-commerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: kBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              side: const BorderSide(color: kPrimaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kOffWhiteColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            primary: kPrimaryColor,
            secondary: kAccentColor,
            error: kHeartColor,
          ).copyWith(background: kBackgroundColor),
          useMaterial3: true,
        ),
        // Định nghĩa routes chính
        routes: {
          '/cart': (context) => CartScreen(),
          PaymentResultScreen.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return PaymentResultScreen(
              orderId: args?['orderId'] ?? 'N/A',
              initialStatus: args?['initialStatus'] ?? 'unknown',
              message: args?['message'],
              vnpResponseCode: args?['vnpResponseCode'],
            );
          },
          VnpayWebViewScreen.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return VnpayWebViewScreen(
              paymentUrl: args?['paymentUrl'] ?? 'about:blank',
            );
          },
        },
        home: const AppWrapper(), // Màn hình khởi đầu
      ),
    );
  }
}
