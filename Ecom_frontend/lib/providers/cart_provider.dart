import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Dùng cho addPostFrameCallback
import 'package:ecom_frontend/models/cart.dart';
import 'package:ecom_frontend/models/cart_item.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/services/cart_service.dart';

/// Trạng thái tải dữ liệu giỏ hàng
enum CartStatus { initial, loading, loaded, error }

class CartProvider extends ChangeNotifier {
  final CartService _cartService;
  final AuthProvider? _authProvider; // Nghe thay đổi đăng nhập

  Cart? _cart;
  Cart? get cart => _cart;

  CartStatus _status = CartStatus.initial;
  CartStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CartProvider(this._cartService, this._authProvider) {
    // Lắng nghe trạng thái đăng nhập và tải giỏ hàng khi cần
    _authProvider?.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  /// Khi trạng thái đăng nhập thay đổi
  void _onAuthChanged() {
    if (_authProvider?.authStatus == AuthStatus.authenticated) {
      // Chỉ fetch khi mới khởi tạo hoặc chưa có giỏ
      if (_status == CartStatus.initial || _cart == null) {
        debugPrint("Đã đăng nhập → tải giỏ hàng…");
        fetchCart();
      }
    } else {
      // Đăng xuất → dọn giỏ local
      debugPrint("Đã đăng xuất → xóa giỏ hàng local.");
      _cart = null;
      _status = CartStatus.initial;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Tải giỏ hàng hiện tại của người dùng
  Future<void> fetchCart({bool force = false}) async {
    // Tránh gọi thừa nếu đang loading/đã loaded, trừ khi force
    if (!force &&
        (_status == CartStatus.loading || _status == CartStatus.loaded)) {
      debugPrint("Bỏ qua fetchCart (status: $_status, force: $force)");
      return;
    }

    _status = CartStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Người dùng chưa đăng nhập.");
      }
      _cart = await _cartService.getMyCart();
      _status = CartStatus.loaded;
      debugPrint(
        "Tải giỏ hàng thành công: ${_cart?.items.length ?? 0} sản phẩm.",
      );
    } catch (e) {
      debugPrint("Lỗi tải giỏ hàng: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      _cart = null;
    } finally {
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
    }
  }

  /// Thêm sản phẩm vào giỏ
  Future<void> addToCart(String productId, {int qty = 1}) async {
    debugPrint("Thêm sản phẩm $productId vào giỏ (số lượng: $qty) …");
    try {
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để thêm vào giỏ hàng.");
      }
      await _cartService.addItemToCart(productId, qty);
      debugPrint("Thêm thành công, làm mới giỏ hàng…");
      await fetchCart(force: true);
    } catch (e) {
      debugPrint("Lỗi thêm vào giỏ: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  /// Cập nhật số lượng một item
  Future<void> updateItemQuantity(String cartItemId, int qty) async {
    debugPrint("Cập nhật số lượng item $cartItemId → $qty …");
    try {
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để cập nhật giỏ hàng.");
      }
      if (qty <= 0) {
        debugPrint("Số lượng ≤ 0 → xóa item thay vì cập nhật.");
        await removeFromCart(cartItemId);
        return;
      }
      await _cartService.updateCartItem(cartItemId, qty);
      debugPrint("Cập nhật thành công, làm mới giỏ hàng…");
      await fetchCart(force: true);
    } catch (e) {
      debugPrint("Lỗi cập nhật số lượng: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  /// Xóa một item khỏi giỏ
  Future<void> removeFromCart(String cartItemId) async {
    debugPrint("Xóa item $cartItemId khỏi giỏ…");
    try {
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để xóa sản phẩm khỏi giỏ hàng.");
      }
      await _cartService.removeCartItem(cartItemId);
      debugPrint("Xóa thành công, làm mới giỏ hàng…");
      await fetchCart(force: true);
    } catch (e) {
      debugPrint("Lỗi xóa khỏi giỏ: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  /// Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    debugPrint("Xóa toàn bộ giỏ hàng…");
    try {
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để xóa giỏ hàng.");
      }
      await _cartService.clearCart();

      // Tạo giỏ rỗng (giữ subtotal = 0 để UI hiển thị đúng)
      _cart = Cart(
        cartId: _cart?.cartId ?? '',
        items: <CartItem>[],
        subtotal: 0.0,
      );
      _status = CartStatus.loaded;
      _errorMessage = null;
      debugPrint("Đã xóa giỏ hàng.");

      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
    } catch (e) {
      debugPrint("Lỗi xóa giỏ hàng: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  /// Theo dõi vòng đời Provider
  bool _mounted = true;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _mounted = false;
    super.dispose();
  }
}
