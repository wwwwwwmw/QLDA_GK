import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/forgot_password_screen.dart';
import 'package:ecom_frontend/screens/auth/register_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/custom_text_field.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/app_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "");
  final _passwordController = TextEditingController(text: "");
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  /// Đăng nhập và điều hướng khi thành công
  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String? error;

    try {
      error = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Đăng nhập thành công → xoá stack và trở lại AppWrapper
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppWrapper()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chào mừng trở lại",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vui lòng nhập email và mật khẩu để đăng nhập",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _emailController,
              labelText: "Địa chỉ Email",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              labelText: "Mật khẩu",
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kSecondaryTextColor,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      activeColor: kPrimaryColor,
                    ),
                    const Text(
                      "Ghi nhớ đăng nhập",
                      style: TextStyle(color: kSecondaryTextColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Quên mật khẩu?",
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Đăng nhập bằng Email",
              onPressed: _login,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Chưa có tài khoản? ",
                  style: TextStyle(color: kSecondaryTextColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Đăng ký",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
