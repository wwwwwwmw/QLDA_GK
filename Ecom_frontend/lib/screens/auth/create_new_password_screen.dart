import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/login_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/custom_text_field.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Đổi mật khẩu với mã OTP hợp lệ
  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Mật khẩu không khớp"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mật khẩu phải ít nhất 6 ký tự"),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    final error = await authProvider.resetPassword(
      email: widget.email,
      code: widget.code,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đổi mật khẩu thành công! Vui lòng đăng nhập lại."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Mật khẩu mới", style: TextStyle(color: kTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: const BackButton(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tạo mật khẩu mới",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhập mật khẩu mới cho tài khoản của bạn.",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _passwordController,
              labelText: "Mật khẩu mới",
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kSecondaryTextColor,
                ),
                onPressed: () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _confirmPasswordController,
              labelText: "Xác nhận mật khẩu",
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kSecondaryTextColor,
                ),
                onPressed: () => setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                }),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "Tiếp tục",
              onPressed: _resetPassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
