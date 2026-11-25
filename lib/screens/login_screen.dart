import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/google_icon.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';
import 'help_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import '../services/secure_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = false; 

  final Color _primaryGreen = const Color(0xFF059669);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === FUNGSI LOGIN ===
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password tidak boleh kosong!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      await SecureStorageService.saveToken(result['token']);
      if (!mounted) return;

      final userMap = result['user'] is Map<String, dynamic>
          ? result['user'] as Map<String, dynamic>
          : null;
      final isAdmin = AuthProvider.isAdminFromUserMap(userMap);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setAdminStatus(isAdmin);
      if (!mounted) return;

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setAdminMode(isAdmin);
      if (!isAdmin) {
        await cartProvider.syncWithServer();
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: _primaryGreen),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()), 
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  // === FUNGSI LOGIN GOOGLE ===
  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setAdminMode(authProvider.isAdmin);
      if (!authProvider.isAdmin) {
        await cartProvider.syncWithServer();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: _primaryGreen),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      if (result['isCancelled'] == true || result['message'] == 'Login Google dibatalkan') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Google dibatalkan.'),
            backgroundColor: Color(0xFF4B5563),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.isDark ? AppTheme.darkSurface.withOpacity(0.85) : Colors.white.withOpacity(0.75),
                shape: BoxShape.circle,
                border: Border.all(color: context.border, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ================= AMBIENT BLOB 1 (BRAND GREEN) =================
          Positioned(
            top: -60,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(context.isDark ? 0.18 : 0.32),
                    const Color(0xFF059669).withOpacity(context.isDark ? 0.06 : 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ================= AMBIENT BLOB 2 (WARM AMBER) =================
          Positioned(
            bottom: -50,
            right: -60,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(context.isDark ? 0.12 : 0.24),
                    const Color(0xFFD97706).withOpacity(context.isDark ? 0.04 : 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ================= AMBIENT BLOB 3 (SOFT BLUE-TEAL) =================
          Positioned(
            top: 320,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withOpacity(context.isDark ? 0.08 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ================= MAIN SCROLLABLE CONTENT =================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppTheme.darkSurface.withOpacity(0.9) : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: context.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(context.isDark ? 0.35 : 0.06),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LOGO ECOTAHU
                          Center(
                            child: Image.asset(
                              'assets/images/Logo_EcoTahu.png',
                              width: 175,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // SEGMENTED TAB SWITCHER (GLASS STYLE)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFF1F5F9).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF047857)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF059669).withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Daftar',
                                          style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600, fontSize: 13.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // HEADING & SUBTITLE
                          Text(
                            'Selamat Datang!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Masuk untuk lanjut belanja tahu segar.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 22),

                          // GOOGLE LOGIN BUTTON (GLASS STYLE)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isGoogleLoading ? null : _handleGoogleLogin,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: context.isDark ? AppTheme.darkSurfaceElevated : Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.border, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.025),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isGoogleLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const GoogleIcon(size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Lanjutkan dengan Google',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // DIVIDER "ATAU"
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, context.border, context.border],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'ATAU',
                                  style: TextStyle(
                                    color: context.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [context.border, context.border, Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // FORM: EMAIL
                          _buildLabel('Email atau No. HP'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Masukkan email atau nomor HP',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // FORM: PASSWORD + LUPA PASSWORD
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('Password'),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: const Text(
                                  'Lupa password?',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Masukkan kata sandi',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 14),

                          // INGAT SAYA
                          Row(
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  side: BorderSide(color: context.border, width: 1.3),
                                  onChanged: (value) {
                                    setState(() => _rememberMe = value ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ingat saya',
                                style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // TOMBOL SUBMIT LOGIN (GRADIENT GLOW)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withOpacity(0.38),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Login',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // TRUST BADGES (SSL, Organik, Verified)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge(Icons.lock_outline_rounded, 'SSL'),
                              const SizedBox(width: 10),
                              _buildBadge(Icons.eco_outlined, 'Organik'),
                              const SizedBox(width: 10),
                              _buildBadge(Icons.check_circle_outline_rounded, 'Verified'),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // FOOTER LINKS (Bantuan, S&K, Privasi)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterLink('Bantuan', () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                              }),
                              Text(' · ', style: TextStyle(color: context.textMuted)),
                              _buildFooterLink('S&K', () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                              }),
                              Text(' · ', style: TextStyle(color: context.textMuted)),
                              _buildFooterLink('Privasi', () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: context.textMuted, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: context.textMuted,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: context.isDark ? AppTheme.darkSurfaceElevated : Colors.white.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.border, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF059669), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.isDark ? AppTheme.emeraldDarkSoft : const Color(0xFFE8F5E9).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.isDark ? AppTheme.emeraldLight.withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669), size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(color: context.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}
