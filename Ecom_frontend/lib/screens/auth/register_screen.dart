import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/verification_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/custom_text_field.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Vai trò người dùng chọn (USER/SELLER)
  String _selectedRole = 'USER';

  Future<void> _register() async {
    // Validate cơ bản
    if (_nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tên phải có ít nhất 2 ký tự."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_emailController.text.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email không hợp lệ."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mật khẩu phải ít nhất 6 ký tự."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    final error = await authProvider.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Đăng ký thành công → chuyển sang nhập OTP để xác thực email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            email: _emailController.text.trim(),
            purpose: VerificationPurpose.verifyEmail,
          ),
        ),
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
    _nameController.dispose();
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
              "Tạo tài khoản",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Đăng ký để bắt đầu mua sắm và bán hàng.",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),

            CustomTextField(
              controller: _nameController,
              labelText: "Họ và tên",
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            CustomTextField(
              controller: _emailController,
              labelText: "Địa chỉ Email",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Chọn vai trò đăng ký
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vai trò",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'USER',
                      child: Text('Người dùng (Mua hàng)'),
                    ),
                    DropdownMenuItem(
                      value: 'SELLER',
                      child: Text('Người bán (Cửa hàng)'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    setState(() => _selectedRole = newValue);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.manage_accounts_outlined,
                      color: kSecondaryTextColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(
                        color: kPrimaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
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

            const SizedBox(height: 24),

            PrimaryButton(
              text: "Đăng ký bằng Email",
              onPressed: _register,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Đã có tài khoản? ",
                  style: TextStyle(color: kSecondaryTextColor),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Đăng nhập",
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
