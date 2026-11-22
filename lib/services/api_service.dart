import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // WAJIB UNTUK UPLOAD FILE
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/article.dart';
import '../models/recipe.dart';
import '../models/limbah.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../config/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;

  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 45);

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) =>
      http.get(url, headers: headers).timeout(_timeout);

  Future<http.Response> _post(Uri url, {Map<String, String>? headers, Object? body}) =>
      http.post(url, headers: headers, body: body).timeout(_timeout);

  Future<http.Response> _put(Uri url, {Map<String, String>? headers, Object? body}) =>
      http.put(url, headers: headers, body: body).timeout(_timeout);

  Future<http.Response> _delete(Uri url, {Map<String, String>? headers, Object? body}) =>
      http.delete(url, headers: headers, body: body).timeout(_timeout);

  String _formatError(Object e) {
    if (e is TimeoutException) {
      return 'Koneksi ke server melebihi batas waktu. Periksa jaringan Anda lalu coba lagi.';
    }
    return 'Terjadi kesalahan koneksi: $e';
  }

  // === FUNGSI LOGIN ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'token': data['access_token'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email atau password salah'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI REGISTER ===
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/register'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'no_telepon': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Registrasi berhasil'};
      } else {
        String errorMessage = data['message'] ?? 'Gagal mendaftar.';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) errorMessage = errors.values.first[0];
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI LOGIN / REGISTER GOOGLE ===
  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    String? name,
    String? googleId,
    String? avatar,
  }) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'google_id': googleId,
          'avatar': avatar,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login Google berhasil',
          'token': data['access_token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal login dengan Google',
        };
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI LUPA PASSWORD ===
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'] ?? 'Link reset password telah dikirim ke email.',
          'token': data['token'],
          'email': data['email'] ?? email,
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mengirim link reset password.'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI RESET PASSWORD ===
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password berhasil direset!'};
      } else {
        String errorMessage = data['message'] ?? 'Gagal mereset password.';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) errorMessage = errors.values.first[0];
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI GET PRODUK TAHU ===
  Future<List<Product>> getProducts([String? token]) async {
    try {
      Map<String, String> headers = {'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final response = await _get(Uri.parse('$baseUrl/produk-tahu'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['data'];
        return results.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat produk. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(_formatError(e));
    }
  }

  // === FUNGSI GET PRODUK LIMBAH ===
  Future<List<Limbah>> getLimbah() async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/limbah'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['data'];
        return results.map((json) => Limbah.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat limbah. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(_formatError(e));
    }
  }

  // === FUNGSI GET ARTIKEL EDUKASI ===
  Future<List<Article>> getArticles([String? token]) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await _get(
        Uri.parse('$baseUrl/edukasi'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['data'];
        return results.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat artikel. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(_formatError(e));
    }
  }

  // === FUNGSI LIKE ARTIKEL EDUKASI ===
  Future<Map<String, dynamic>> toggleArticleLike(String token, int articleId) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/edukasi/$articleId/like'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'liked': data['liked'] == true,
          'likes_count': int.tryParse(data['likes_count']?.toString() ?? '0') ?? 0,
          'message': data['message'] ?? 'Berhasil',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui suka',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI GET RESEP OLAHAN TAHU ===
  Future<List<Recipe>> getRecipes([String? token]) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await _get(
        Uri.parse('$baseUrl/resep'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['data'] ?? [];
        return results.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat resep. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(_formatError(e));
    }
  }

  // === FUNGSI LIKE RESEP OLAHAN TAHU ===
  Future<Map<String, dynamic>> toggleRecipeLike(String token, int recipeId) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/resep/$recipeId/like'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'liked': data['liked'] == true,
          'likes_count': int.tryParse(data['likes_count']?.toString() ?? '0') ?? 0,
          'message': data['message'] ?? 'Berhasil',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui suka',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI GET PROFIL USER ===
  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/user'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // === FUNGSI UPDATE PROFIL ===
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    String? phone,
    String? address,
    String? avatarBase64,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'name': name,
        'username': name,
        'email': email,
        'no_telepon': phone,
        'alamat': address,
      };
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        payload['avatar_base64'] = avatarBase64;
      }

      final response = await _post(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Profil berhasil diperbarui', 'user': data['user']};
      } else {
        String msg = data['message'] ?? 'Gagal memperbarui profil.';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) msg = errors.values.first[0];
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI GANTI PASSWORD ===
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _put(
        Uri.parse('$baseUrl/user/password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password berhasil diperbarui'};
      } else {
        String msg = data['message'] ?? 'Gagal memperbarui password.';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) msg = errors.values.first[0];
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI HAPUS AKUN ===
  Future<Map<String, dynamic>> deleteAccount({
    required String token,
    required String password,
  }) async {
    try {
      final response = await _delete(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Akun berhasil dihapus'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menghapus akun.'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI LOGOUT ===
  Future<bool> logout(String token) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return (response.statusCode == 200 || response.statusCode == 401);
    } catch (e) {
      return false;
    }
  }

  // === FUNGSI CEK PROMO ORDER PERTAMA ===
  Future<Map<String, dynamic>?> checkFirstOrderPromo({
    required String token,
    required int subtotal,
    String? noTelepon,
  }) async {
    try {
      final queryParams = <String, String>{
        'subtotal': subtotal.toString(),
      };
      if (noTelepon != null && noTelepon.trim().isNotEmpty) {
        queryParams['no_telepon'] = noTelepon.trim();
      }
      final uri = Uri.parse('$baseUrl/promo/first-order').replace(queryParameters: queryParams);
      final response = await _get(
        uri,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // === FUNGSI GET RIWAYAT PESANAN ===
  Future<List<dynamic>?> getOrders(String token) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/pesanan'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === FUNGSI MEMBUAT PESANAN ===
  Future<Map<String, dynamic>> createOrder({
    required String token, 
    required String kodePesanan, 
    required int subtotal,      
    required int ongkir,        
    required int totalHarga,
    required String paymentMethod, 
    String? bankTujuan, 
    required String deliveryType, 
    required String alamat,
    required String noTelepon, 
    required String catatan, 
    required List<Map<String, dynamic>> items,
    double? latPin,
    double? lngPin,
    String? kecamatan,
  }) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/pesanan'),
        headers: {
          'Accept': 'application/json', 'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'kode_pesanan': kodePesanan, 
          'subtotal': subtotal,       
          'ongkir': ongkir,           
          'total_harga': totalHarga,
          'payment_method': paymentMethod, 
          'bank_tujuan': bankTujuan, 
          'delivery_type': deliveryType,
          'alamat': alamat, 
          'no_telepon': noTelepon,
          'catatan': catatan, 
          'items': items,
          'lat_pin': latPin,
          'lng_pin': lngPin,
          'kecamatan': kecamatan,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal membuat pesanan'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI BATALKAN PESANAN ===
  Future<Map<String, dynamic>> cancelOrder({
    required String token,
    required dynamic pesananId,
    required String alasan,
    String? namaBank,
    String? nomorRekening,
    String? atasNama,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'alasan_batal': alasan,
      };
      if (namaBank != null && namaBank.isNotEmpty) body['nama_bank'] = namaBank;
      if (nomorRekening != null && nomorRekening.isNotEmpty) body['nomor_rekening'] = nomorRekening;
      if (atasNama != null && atasNama.isNotEmpty) body['atas_nama'] = atasNama;

      final response = await _post(
        Uri.parse('$baseUrl/pesanan/$pesananId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal membatalkan pesanan'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI UPLOAD BUKTI TRANSFER ===
  Future<Map<String, dynamic>> uploadBuktiTransfer({
    required String token,
    required dynamic pesananId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/pesanan/$pesananId/upload-bukti'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(http.MultipartFile.fromBytes(
        'bukti_transfer',
        fileBytes,
        filename: fileName,
      ));

      var streamedResponse = await request.send().timeout(_uploadTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal upload bukti'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI TOKO & ONGKIR ===
  Future<Map<String, dynamic>?> getTokoInfo() async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/toko'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> calculateOngkir(double lat, double lng) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/toko/hitung-ongkir'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === FUNGSI NOTIFIKASI ===
  Future<Map<String, dynamic>> getNotifications(String token) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List raw = data['data'] ?? [];
        List<NotificationModel> list = raw.map((json) => NotificationModel.fromJson(json)).toList();
        return {
          'success': true,
          'unread_count': data['unread_count'] ?? 0,
          'notifications': list,
        };
      }
      return {'success': false, 'unread_count': 0, 'notifications': <NotificationModel>[]};
    } catch (e) {
      return {'success': false, 'unread_count': 0, 'notifications': <NotificationModel>[]};
    }
  }

  Future<bool> markNotificationAsRead(String token, String id) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String token) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // === FUNGSI ULASAN / REVIEWS ===
  Future<List<ReviewModel>> getReviews(String itemType, int itemId) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/reviews?item_type=$itemType&item_id=$itemId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['data'] ?? [];
        return results.map((json) => ReviewModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required String token,
    required int pesananId,
    required String reviewableType,
    required int reviewableId,
    required int rating,
    String? komentar,
    Uint8List? mediaBytes,
    String? mediaName,
  }) async {
    try {
      if (mediaBytes != null && mediaName != null && mediaName.isNotEmpty) {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reviews'));
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
        request.fields['pesanan_id'] = pesananId.toString();
        request.fields['reviewable_type'] = reviewableType;
        request.fields['reviewable_id'] = reviewableId.toString();
        request.fields['rating'] = rating.toString();
        if (komentar != null && komentar.isNotEmpty) {
          request.fields['komentar'] = komentar;
        }
        request.files.add(http.MultipartFile.fromBytes(
          'media',
          mediaBytes,
          filename: mediaName,
        ));

        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {'success': true, 'message': data['message'] ?? 'Ulasan berhasil dikirim'};
        } else {
          String msg = data['message'] ?? 'Gagal mengirim ulasan';
          if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
            final firstVal = (data['errors'] as Map).values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              msg = firstVal.first.toString();
            }
          }
          return {'success': false, 'message': msg};
        }
      }

      final response = await _post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pesanan_id': pesananId,
          'reviewable_type': reviewableType,
          'reviewable_id': reviewableId,
          'rating': rating,
          'komentar': komentar,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Ulasan berhasil dikirim'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mengirim ulasan'};
      }
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // === FUNGSI TRACKING KURIR ===
  Future<Map<String, dynamic>?> getOrderTracking(String token, dynamic pesananId) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/pesanan/$pesananId/tracking'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === ADMIN DASHBOARD OVERVIEW (READ-ONLY) ===
  Future<Map<String, dynamic>> getAdminOverview(String token) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/admin/overview'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': data['message'] ?? 'Gagal memuat ringkasan admin.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _formatError(e),
      };
    }
  }

  // === KERANJANG PERSISTENT API ===
  Future<List<Map<String, dynamic>>?> getCart(String token) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/cart'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['items'] is List) {
          return List<Map<String, dynamic>>.from(
            (data['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> addCartItem(
    String token, {
    required String itemType,
    required int itemId,
    int qty = 1,
  }) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'item_type': itemType == 'limbah' ? 'limbah' : 'tahu',
          'item_id': itemId,
          'qty': qty,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCartItem(
    String token, {
    required String itemType,
    required int itemId,
    required int qty,
  }) async {
    try {
      final response = await _put(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'item_type': itemType == 'limbah' ? 'limbah' : 'tahu',
          'item_id': itemId,
          'qty': qty,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCartItem(
    String token, {
    required String itemType,
    required int itemId,
  }) async {
    try {
      final response = await _delete(
        Uri.parse('$baseUrl/cart/item'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'item_type': itemType == 'limbah' ? 'limbah' : 'tahu',
          'item_id': itemId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCartApi(String token) async {
    try {
      final response = await _delete(
        Uri.parse('$baseUrl/cart'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
