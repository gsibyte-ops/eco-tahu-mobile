import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userUsername = '';
  String _userGender = '';
  String _userBirthDate = '';
  String _userAddress = '';
  String _userPhotoBase64 = '';
  bool _isAdmin = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userUsername => _userUsername;
  String get userGender => _userGender;
  String get userBirthDate => _userBirthDate;
  String get userAddress => _userAddress;
  String get userPhotoBase64 => _userPhotoBase64;
  bool get isAdmin => _isAdmin;

  static bool isAdminFromUserMap(Map<String, dynamic>? user) {
    if (user == null) return false;
    final role = user['role'];
    String roleName = '';
    if (role is Map) {
      roleName = role['nama_role']?.toString().toLowerCase() ?? '';
    } else if (role is String) {
      roleName = role.toLowerCase();
    }
    final roleId = user['role_id'];
    return roleName == 'admin' || roleId == 1 || roleId?.toString() == '1';
  }

  Future<void> setAdminStatus(bool isAdmin) async {
    _isAdmin = isAdmin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', isAdmin);
    notifyListeners();
  }

  Future<void> syncRoleFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.readToken();
    if (token == null || token.trim().isEmpty) {
      _isAdmin = false;
      await prefs.remove('is_admin');
      notifyListeners();
      return;
    }

    final user = await ApiService().getUserProfile(token);
    if (user != null) {
      final adminFlag = isAdminFromUserMap(user);
      _isAdmin = adminFlag;
      await prefs.setBool('is_admin', adminFlag);
      notifyListeners();
    }
  }

  // HELPER: SAVE PROFIL PER-EMAIL
  Future<void> _saveProfileData() async {
    if (_userEmail.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final profileData = {
      'name': _userName,
      'email': _userEmail,
      'phone': _userPhone,
      'username': _userUsername,
      'gender': _userGender,
      'birthDate': _userBirthDate,
      'address': _userAddress,
      'photoBase64': _userPhotoBase64,
    };
    await prefs.setString('profile_$_userEmail', jsonEncode(profileData));
  }

  // HELPER: LOAD PROFIL
  Future<void> _loadProfileData(String email) async {
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('profile_$email');
    if (profileJson != null) {
      final data = jsonDecode(profileJson) as Map<String, dynamic>;
      _userName = data['name'] ?? '';
      _userEmail = data['email'] ?? email;
      _userPhone = data['phone'] ?? '';
      _userUsername = data['username'] ?? '';
      _userGender = data['gender'] ?? '';
      _userBirthDate = data['birthDate'] ?? '';
      _userAddress = data['address'] ?? '';
      _userPhotoBase64 = data['photoBase64'] ?? '';
    }
  }

  // CEK STATUS LOGIN
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isAdmin = prefs.getBool('is_admin') ?? false;

    if (_isLoggedIn) {
      final currentEmail = prefs.getString('currentEmail') ?? '';
      if (currentEmail.isNotEmpty) {
        await _loadProfileData(currentEmail);
        _userEmail = currentEmail;
      }
    }

    final token = await SecureStorageService.readToken();
    if (token != null && token.trim().isNotEmpty) {
      await syncRoleFromServer();
    }

    notifyListeners();
  }

  // REGISTER
  Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? username,
    String? phone,
    String? gender,
    String? birthDate,
    String? address,
  }) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Semua kolom wajib diisi!'};
      }
      if (password.length < 8) {
        return {'success': false, 'message': 'Password minimal 8 karakter!'};
      }
      if (!email.contains('@')) {
        return {'success': false, 'message': 'Format email tidak valid!'};
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await userCredential.user?.updateDisplayName(name);

      // Set state
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email.trim();
      _userUsername = username ?? '';
      _userPhone = phone ?? '';
      _userGender = gender ?? '';
      _userBirthDate = birthDate ?? '';
      _userAddress = address ?? '';

      // Simpan profil (per-email) + session
      await _saveProfileData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('currentEmail', _userEmail);

      notifyListeners();
      return {'success': true, 'message': 'Pendaftaran berhasil!'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar. Silakan login.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (min. 8 karakter).';
          break;
        default:
          message = 'Pendaftaran gagal: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // LOGIN
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Email dan password wajib diisi!'};
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _isLoggedIn = true;
      _userEmail = userCredential.user?.email ?? email.trim();

      // Load profil per-email
      await _loadProfileData(_userEmail);

      // Fallback nama dari Firebase kalau kosong
      if (_userName.isEmpty) {
        _userName = userCredential.user?.displayName ?? _userEmail.split('@')[0];
      }

      // Save session flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('currentEmail', _userEmail);

      // Simpan ulang profil (fallback kalau baru ada)
      await _saveProfileData();

      notifyListeners();
      return {'success': true, 'message': 'Berhasil masuk!'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Akun tidak ditemukan. Silakan daftar dulu.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Email atau password salah.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          message = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        default:
          message = 'Login gagal: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  //  SET SESSION 
  Future<void> setSession({required String token, required String email, String? name}) async {
    _isLoggedIn = true;
    _userEmail = email;
    if (name != null && name.isNotEmpty) _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService.saveToken(token);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('currentEmail', email);
    if (name != null && name.isNotEmpty) await prefs.setString('userName', name);
    notifyListeners();
  }

  //LOGIN GOOGLE
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      UserCredential? userCredential;

      String? googleIdToken;
      String? googleAccessToken;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return {'success': false, 'message': 'Login Google dibatalkan'};
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        googleIdToken = googleAuth.idToken;
        googleAccessToken = googleAuth.accessToken;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final firebaseIdToken = await userCredential.user?.getIdToken();
      final email = userCredential.user?.email ?? '';
      final name = userCredential.user?.displayName ?? '';

      if (email.isEmpty) {
        return {'success': false, 'message': 'Email Google tidak ditemukan.'};
      }

      // Hubungkan dengan Laravel Sanctum API menggunakan token Google/Firebase terverifikasi
      final apiResult = await ApiService().loginWithGoogle(
        idToken: googleIdToken,
        accessToken: googleAccessToken,
        firebaseIdToken: firebaseIdToken,
      );

      if (apiResult['success'] != true) {
        return {'success': false, 'message': apiResult['message'] ?? 'Gagal otentikasi dengan server.'};
      }

      final token = apiResult['token'] ?? '';
      final userMap = apiResult['user'] is Map<String, dynamic>
          ? apiResult['user'] as Map<String, dynamic>
          : null;
      final adminFlag = isAdminFromUserMap(userMap);

      _isLoggedIn = true;
      _userEmail = email;
      _userName = name.isNotEmpty ? name : 'Pengguna Google';
      _isAdmin = adminFlag;

      // Save session di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await SecureStorageService.saveToken(token);
      await prefs.setBool('is_admin', adminFlag);
      await prefs.setString('currentEmail', _userEmail);
      await prefs.setString('userName', _userName);

      await _loadProfileData(_userEmail);
      await _saveProfileData();

      notifyListeners();
      return {'success': true, 'message': 'Login Google berhasil!'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'user-cancelled' || e.code == 'canceled') {
        return {'success': false, 'isCancelled': true, 'message': 'Login Google dibatalkan'};
      }
      return {'success': false, 'isCancelled': false, 'message': 'Login Google gagal: ${e.message ?? e.code}'};
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup-closed-by-user') || errStr.contains('cancelled') || errStr.contains('canceled')) {
        return {'success': false, 'isCancelled': true, 'message': 'Login Google dibatalkan'};
      }
      return {'success': false, 'isCancelled': false, 'message': 'Login Google gagal: $e'};
    }
  }

  //UPDATE PROFIL
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? username,
    String? gender,
    String? birthDate,
    String? address,
    String? photoBase64,
  }) async {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    if (username != null) _userUsername = username;
    if (gender != null) _userGender = gender;
    if (birthDate != null) _userBirthDate = birthDate;
    if (address != null) _userAddress = address;
    if (photoBase64 != null) _userPhotoBase64 = photoBase64;

    // Simpan sebagai JSON per-email
    await _saveProfileData();

    notifyListeners();
  }

  //LOGOUT
  Future<void> logout() async {
    final prevEmail = _userEmail;
    try {
      final token = await SecureStorageService.readToken();
      if (token != null && token.trim().isNotEmpty) {
        await ApiService().logout(token);
      }
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout error: $e');
      }
    }

    // Hapus token terenkripsi dari Keystore
    await SecureStorageService.deleteToken();

    // Reset state di memory
    _isLoggedIn = false;
    _isAdmin = false;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _userUsername = '';
    _userGender = '';
    _userBirthDate = '';
    _userAddress = '';
    _userPhotoBase64 = '';

    // Hapus session & cache data pribadi agar tidak tertinggal di perangkat
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('currentEmail');
    await prefs.remove('userName');
    await prefs.remove('is_admin');
    if (prevEmail.isNotEmpty) {
      await prefs.remove('profile_$prevEmail');
    }

    notifyListeners();
  }
}