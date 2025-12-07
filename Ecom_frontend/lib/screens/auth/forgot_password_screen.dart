import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/verification_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/custom_text_field.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  /// Gửi mã xác thực đặt lại mật khẩu
  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.forgotPassword(_emailController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // ✅ Gửi thành công → chuyển sang màn hình nhập OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            email: _emailController.text,
            purpose: VerificationPurpose.resetPassword,
          ),
        ),
      );
    } else {
      // ❌ Thông báo lỗi
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Quên mật khẩu", style: TextStyle(color: kTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: const BackButton(color: kTextColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Đặt lại mật khẩu",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhập email bạn đã đăng ký. Chúng tôi sẽ gửi mã xác thực để giúp bạn đặt lại mật khẩu.",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _emailController,
              labelText: "Địa chỉ Email",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Gửi mã xác thực",
              onPressed: _sendCode,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
