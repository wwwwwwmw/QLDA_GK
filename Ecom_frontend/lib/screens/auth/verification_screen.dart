import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/auth/create_new_password_screen.dart';
import 'package:ecom_frontend/screens/auth/login_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/primary_button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

/// Mục đích của màn hình OTP
enum VerificationPurpose { verifyEmail, resetPassword }

class VerificationScreen extends StatefulWidget {
  final String email;
  final VerificationPurpose purpose;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  /// Xác nhận mã OTP (đăng ký hoặc quên mật khẩu)
  Future<void> _confirmCode() async {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ 6 số OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    String? error;

    try {
      if (widget.purpose == VerificationPurpose.verifyEmail) {
        // Xác thực email sau khi đăng ký
        error = await authProvider.verifyEmail(
          widget.email,
          _pinController.text,
        );

        if (mounted && error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Xác thực thành công! Vui lòng đăng nhập."),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        // Kiểm tra mã OTP cho luồng quên mật khẩu
        error = await authProvider.verifyResetCode(
          widget.email,
          _pinController.text,
        );

        if (mounted && error == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateNewPasswordScreen(
                email: widget.email,
                code: _pinController.text,
              ),
            ),
          );
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error!.contains("Invalid") ||
                      error!.contains("Sai") ||
                      error!.contains("hết hạn")
                  ? "Mã xác thực không hợp lệ hoặc đã hết hạn."
                  : error!,
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: kTextColor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondaryTextColor.withValues(alpha: 0.4)),
      ),
    );

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Xác thực", style: TextStyle(color: kTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: const BackButton(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Xác thực mã OTP",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Chúng tôi đã gửi mã OTP tới email:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            Pinput(
              controller: _pinController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: kPrimaryColor, width: 2),
                ),
              ),
              onCompleted: (pin) => _confirmCode(),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {},
              child: const Text(
                "Không nhận được email? Gửi lại mã",
                style: TextStyle(color: kSecondaryTextColor),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Xác nhận",
              onPressed: _confirmCode,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
