import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? token;

  const ResetPasswordScreen({super.key, this.email, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late TextEditingController _emailController;
  late TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final Color _primaryGreen = const Color(0xFF1E8E5A);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _tokenController = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Email wajib diisi dengan format valid.');
      return;
    }
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Kode / token reset wajib diisi.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password baru minimal harus 8 karakter.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService().resetPassword(
      email: email,
      token: token,
      password: password,
      passwordConfirmation: confirm,
    );

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF1E8E5A), size: 28),
              const SizedBox(width: 10),
              Text('Sukses!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary)),
            ],
          ),
          content: Text(
            'Password baru Anda telah berhasil disimpan. Silakan masuk dengan kata sandi baru Anda.',
            style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      'Buat Password Baru Anda.',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Pilih password yang kuat dan mudah Anda ingat untuk mengamankan akun.',
                      style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.dangerDarkSoft : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDark ? AppTheme.danger.withOpacity(0.3) : Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!, style: TextStyle(color: context.isDark ? const Color(0xFFFCA5A5) : Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.3) : const Color(0xFF1E8E5A).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_successMessage!, style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // EMAIL
                  _buildLabel('Email Akun'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'nama@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  // TOKEN RESET
                  if (_tokenController.text.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.3) : const Color(0xFF1E8E5A).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Token reset terisi otomatis dari email Anda.',
                              style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ] else ...[
                    _buildLabel('Kode / Token Reset Password'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _tokenController,
                      hintText: 'Masukkan kode token dari email Anda',
                      icon: Icons.vpn_key_outlined,
                    ),
                    const SizedBox(height: 15),
                  ],

                  // PASSWORD BARU
                  _buildLabel('Password Baru (Min. 8 Karakter)'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(fontSize: 13.5, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Minimal 8 karakter',
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.lock_outline, color: context.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: context.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // KONFIRMASI PASSWORD BARU
                  _buildLabel('Konfirmasi Password Baru'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: TextStyle(fontSize: 13.5, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ulangi password baru',
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.lock_outline, color: context.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: context.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // TOMBOL RESET
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleResetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Reset Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KEMBALI KE LOGIN
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A)),
                          const SizedBox(width: 5),
                          Text(
                            'Kembali ke Halaman Login',
                            style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13.5, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: context.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
