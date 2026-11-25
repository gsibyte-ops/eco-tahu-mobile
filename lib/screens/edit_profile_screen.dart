import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/media_validator.dart';
import '../services/secure_storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;

  String? _selectedGender;
  DateTime? _selectedDate;
  String? _newPhotoBase64;
  String? _existingAvatarUrl;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  
  // Warna hijau utama yang senada dengan halaman lain
  final Color _primaryGreen = const Color(0xFF1E8E5A);

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.userName);
    _emailController = TextEditingController(text: auth.userEmail);
    _phoneController = TextEditingController(text: auth.userPhone);
    _birthDateController = TextEditingController(text: auth.userBirthDate);
    _addressController = TextEditingController(text: auth.userAddress);
    _selectedGender = auth.userGender.isNotEmpty ? auth.userGender : null;
    _fetchLiveProfile();
  }

  Future<void> _fetchLiveProfile() async {
    final token = await SecureStorageService.readToken();
    if (token != null && token.isNotEmpty) {
      final user = await ApiService().getUserProfile(token);
      if (user != null && mounted) {
        setState(() {
          if (user['username'] != null) _nameController.text = user['username'];
          if (user['email'] != null) _emailController.text = user['email'];
          if (user['no_telepon'] != null) _phoneController.text = user['no_telepon'];
          if (user['alamat'] != null) _addressController.text = user['alamat'];
          final String? rawAvatar = user['avatar_url'] ?? user['avatar'];
          if (rawAvatar != null && rawAvatar.trim().isNotEmpty) {
            _existingAvatarUrl = AppConfig.fileUrl(rawAvatar);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Pilih foto dari galeri
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 75,
      );

      if (image == null) return;
      final bytes = await image.readAsBytes();
      final err = MediaValidator.validateImageFile(image.name, bytes.length, maxBytes: 2 * 1024 * 1024);
      if (err != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        return;
      }
      final base64String = base64Encode(bytes);

      setState(() {
        _newPhotoBase64 = base64String;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Pilih Tanggal Lahir
  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final token = await SecureStorageService.readToken();

    if (token != null && token.isNotEmpty) {
      final res = await ApiService().updateProfile(
        token: token,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        avatarBase64: _newPhotoBase64,
      );

      if (res['success'] != true) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan profil ke server'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender,
      birthDate: _birthDateController.text.trim(),
      address: _addressController.text.trim(),
      photoBase64: _newPhotoBase64,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil berhasil diperbarui!'),
        backgroundColor: _primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    ImageProvider? avatarImage;
    if (_newPhotoBase64 != null && _newPhotoBase64!.isNotEmpty) {
      avatarImage = MemoryImage(base64Decode(_newPhotoBase64!));
    } else if (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_existingAvatarUrl!);
    } else if (auth.userPhotoBase64.isNotEmpty) {
      avatarImage = MemoryImage(base64Decode(auth.userPhotoBase64));
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil', 
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ================= 1. FOTO PROFIL =================
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardBg,
                      border: Border.all(color: context.isDark ? AppTheme.emeraldLight : _primaryGreen, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.1), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarImage == null
                        ? Icon(Icons.person, size: 65, color: context.isDark ? AppTheme.emeraldLight : const Color(0xFF1E8E5A))
                        : null,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(color: context.isDark ? AppTheme.emeraldLight : _primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),

              // ================= 2. KARTU FORM =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.03), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Nama Lengkap ---
                    _buildLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Masukkan nama kamu',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),

                    // --- Email (Read Only) ---
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email tidak bisa diubah',
                      icon: Icons.email_outlined,
                      isReadOnly: true, // Kunci Email
                    ),
                    const SizedBox(height: 18),

                    // --- Nomor Telepon ---
                    _buildLabel('Nomor Telepon'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Contoh: 081234567890',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),

                    // --- Gender ---
                    _buildLabel('Gender'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      dropdownColor: context.cardBg,
                      decoration: _inputDecoration('Pilih gender', Icons.people_outline),
                      icon: Icon(Icons.keyboard_arrow_down, color: context.textMuted),
                      items: _genderOptions.map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender, style: TextStyle(fontSize: 14, color: context.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedGender = value),
                    ),
                    const SizedBox(height: 18),

                    // --- Tanggal Lahir ---
                    _buildLabel('Tanggal Lahir'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _birthDateController,
                      hint: 'Pilih tanggal lahir',
                      icon: Icons.cake_outlined,
                      isReadOnly: true,
                      onTap: _pickBirthDate,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: context.textMuted, size: 18),
                        onPressed: _pickBirthDate,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // --- Alamat ---
                    _buildLabel('Alamat'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hint: 'Masukkan alamat lengkap',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // ================= 3. TOMBOL SIMPAN =================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: _primaryGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGET HELPER =================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimary),
    );
  }

  // Dekorasi dasar untuk input field
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: context.textMuted, size: 20),
      filled: true,
      fillColor: context.isDark ? AppTheme.darkSurfaceElevated : Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen, width: 1.5),
      ),
    );
  }

  // Widget khusus untuk TextField agar kodenya rapi
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isReadOnly = false,
    bool obscureText = false,
    int maxLines = 1,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      obscureText: obscureText,
      maxLines: maxLines,
      onTap: onTap,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: _inputDecoration(hint, icon).copyWith(
        fillColor: isReadOnly 
            ? (context.isDark ? AppTheme.darkSurface : Colors.grey.shade100) 
            : (context.isDark ? AppTheme.darkSurfaceElevated : Colors.white),
        prefixIcon: Icon(icon, color: isReadOnly ? context.textMuted.withOpacity(0.5) : context.textMuted, size: 20),
        suffixIcon: isReadOnly 
            ? Icon(Icons.lock, color: context.textMuted.withOpacity(0.5), size: 18) 
            : suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isReadOnly ? Colors.transparent : context.border),
        ),
      ),
    );
  }
}