import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  final Color _primaryGreen = const Color(0xFF1E8E5A);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Masukkan alamat email yang valid.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService().forgotPassword(email);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _successMessage = res['message'];
        _errorMessage = null;
      } else {
        _errorMessage = res['message'];
        _successMessage = null;
      }
    });

    if (res['success'] == true) {
      final token = res['token']?.toString();
      // Buka dialog konfirmasi untuk langsung lanjut ke layar Buat Password Baru
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read, color: Color(0xFF1E8E5A), size: 28),
              const SizedBox(width: 10),
              Text('Email Terkirim!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary)),
            ],
          ),
          content: Text(
            'Link dan kode reset telah dikirim ke $email. Anda bisa langsung membuat password baru sekarang di aplikasi.',
            style: TextStyle(fontSize: 13, height: 1.4, color: context.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Nanti Saja', style: TextStyle(color: context.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResetPasswordScreen(email: email, token: token),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Buat Password Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.emeraldDarkSoft : AppTheme.lightGreen.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_reset, size: 40, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Lupa Password?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Masukkan email terdaftar Anda. Kami akan mengirimkan link untuk mengatur ulang password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.emeraldDarkSoft : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.3) : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: context.isDark ? AppTheme.emeraldLight : Colors.green, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : Colors.green.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.dangerDarkSoft : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDark ? AppTheme.danger.withOpacity(0.3) : Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Email Akun',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: context.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.mail_outline, color: context.textMuted, size: 20),
                      filled: true,
                      fillColor: context.isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Color(0xFF1E8E5A), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: context.isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Kirim Link Reset Password',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
                          ),
                        );
                      },
                      child: Text(
                        'Sudah punya token reset? Buat Password Baru',
                        style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, size: 16, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A)),
                      label: Text(
                        'Kembali ke Login',
                        style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
