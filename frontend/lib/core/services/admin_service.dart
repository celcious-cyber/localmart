import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1/admin',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static const String _tokenKey = 'admin_jwt_token';

  // Getter for Token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Interceptor for Admin Token
  void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle session expiry for Admin specifically
          logout();
        }
        return handler.next(e);
      },
    ));
  }

  // --- AUTH ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final token = response.data['data']['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          return {'success': true, 'message': 'Login Admin Berhasil'};
        }
      }
      return {'success': false, 'message': response.data['message'] ?? 'Login Gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isAdminLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // --- DASHBOARD ---
  Future<Map<String, dynamic>?> getStats() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/stats');
      if (response.data['success']) {
        return response.data['data'];
      }
    } catch (_) {}
    return null;
  }

  // --- STORES ---
  Future<List<dynamic>> getStores() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/stores');
      if (response.data['success']) {
        return response.data['data'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> updateStoreStatus(int storeId, {String? status, String? level}) async {
    _setupInterceptors();
    try {
      final response = await _dio.patch('/stores/$storeId/status', data: {
        'status': status,
        'level': level,
      }..removeWhere((_, v) => v == null));
      return {
        'success': response.data['success'],
        'message': response.data['message'] ?? 'Update Berhasil'
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal update toko: $e'};
    }
  }

  // --- DRIVERS ---
  Future<List<dynamic>> getDrivers() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/drivers');
      if (response.data['success']) {
        return response.data['data'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> updateDriverStatus(int driverId, String status) async {
    _setupInterceptors();
    try {
      final response = await _dio.patch('/drivers/$driverId/status', data: {'status': status});
      return {
        'success': response.data['success'],
        'message': response.data['message'] ?? 'Update Berhasil'
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal update driver: $e'};
    }
  }
}
