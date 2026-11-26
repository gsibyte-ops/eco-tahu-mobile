import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/google_icon.dart';
import 'login_screen.dart'; 
import 'main_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isTermsAccepted = false; 

  final Color _primaryGreen = const Color(0xFF059669);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan Konfirmasi Password tidak sama!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!RegExp(r'^(\+62|62|0)[0-9]{8,14}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon harus berupa angka valid (contoh: 081234567890).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan setujui Syarat & Ketentuan terlebih dahulu.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      passwordConfirmation: _confirmPasswordController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: _primaryGreen),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
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
            content: Text('Pendaftaran dengan Google dibatalkan.'),
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
            top: 400,
            right: -50,
            child: Container(
              width: 210,
              height: 210,
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
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Login',
                                          style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600, fontSize: 13.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                                      'Daftar',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // HEADING & SUBTITLE
                          Text(
                            'Buat Akun Baru',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Isi data di bawah untuk mulai berbelanja.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 14),

                          // PROMO BENEFIT PILL (PARITAS DENGAN WEB PERK BOX)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.tahuTagBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.tahuTagBorder),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_offer_rounded, size: 12, color: context.brandGreen),
                                    const SizedBox(width: 4),
                                    Consumer<StoreProvider>(
                                      builder: (context, store, _) {
                                        final formattedMax = store.promoMaxDiskon
                                            .toString()
                                            .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                                        return Text(
                                          'Diskon ${store.promoPersen}% (Maks. Rp $formattedMax)',
                                          style: TextStyle(color: context.brandGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_shipping_rounded, size: 12, color: context.brandGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ongkir Murah',
                                      style: TextStyle(color: context.isDark ? AppTheme.darkTextSecondary : const Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.eco_rounded, size: 12, color: context.brandGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      '100% Organik',
                                      style: TextStyle(color: context.isDark ? AppTheme.darkTextSecondary : const Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // GOOGLE REGISTER BUTTON (GLASS STYLE)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isGoogleLoading ? null : _handleGoogleRegister,
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
                                            'Daftar dengan Google',
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

                          // FORM: NAMA LENGKAP
                          _buildLabel('Nama Lengkap'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          // FORM: EMAIL
                          _buildLabel('Email'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'nama@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // FORM: NO TELEPON
                          _buildLabel('No. Telepon'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _phoneController,
                            hint: '08xxxxxxxxxx',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                              LengthLimitingTextInputFormatter(16),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // FORM: PASSWORD
                          _buildLabel('Password'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Minimal 8 karakter',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 16),

                          // FORM: KONFIRMASI PASSWORD
                          _buildLabel('Konfirmasi Password'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: 'Ulangi password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscureConfirm,
                            onTogglePassword: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          const SizedBox(height: 14),

                          // CHECKBOX TERMS & PRIVACY
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: Checkbox(
                                  value: _isTermsAccepted,
                                  activeColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  side: BorderSide(color: context.border, width: 1.3),
                                  onChanged: (value) {
                                    setState(() => _isTermsAccepted = value ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.45),
                                    children: [
                                      const TextSpan(text: 'Setuju dengan '),
                                      TextSpan(
                                        text: 'S&K',
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen()));
                                          },
                                      ),
                                      const TextSpan(text: ' dan '),
                                      TextSpan(
                                        text: 'Privasi',
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen()));
                                          },
                                      ),
                                      const TextSpan(text: ' EcoTahu.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // TOMBOL SUBMIT DAFTAR (GRADIENT GLOW)
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
                              onPressed: (_isLoading || !_isTermsAccepted) ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: context.isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade300,
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
                                          'Daftar Sekarang',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // SUDAH PUNYA AKUN? MASUK (GLASS BUTTON)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFF1F5F9).withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.border),
                                ),
                                child: Text(
                                  'Sudah Punya Akun? Masuk',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
