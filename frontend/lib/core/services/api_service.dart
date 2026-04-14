import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/home_data.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/store_models.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired or invalid, clear session
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user_token');
          await prefs.remove('user_data');
        }
        return handler.next(e);
      },
    ));
  }

  // --- AUTH METHODS ---

  Future<Map<String, dynamic>> login(String identifier, String password, {bool rememberMe = true}) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['user'];

        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', token);
          // Optional: we can store a snapshot of user data for instant loading
        }
        return {'success': true, 'user': UserModel.fromJson(userData)};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Login gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', token);
        return {'success': true, 'user': UserModel.fromJson(response.data['data']['user'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Registrasi gagal'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        return {'success': false, 'message': 'Email atau Nomor HP sudah terdaftar'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_data');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_token');
  }
  // --- FULL STORE MANAGEMENT ---

  Future<StoreDashboardModel?> getStoreDashboard() async {
    try {
      final response = await _dio.get('/user/store/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return StoreDashboardModel.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching store dashboard: $e');
    }
    return null;
  }

  Future<List<OrderModel>> getStoreOrders(String status) async {
    try {
      final response = await _dio.get('/user/store/orders', queryParameters: {'status': status});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((o) => OrderModel.fromJson(o))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching store orders: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _dio.patch('/user/store/orders/$orderId/status', data: {'status': status});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Status pesanan diperbarui'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update status'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateStoreProfile({
    String? name,
    String? category,
    String? description,
    String? address,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (category != null) data['category'] = category;
      if (description != null) data['description'] = description;
      if (address != null) data['address'] = address;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;

      final response = await _dio.patch('/user/store/profile', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Profil toko diperbarui', 'data': StoreModel.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update profil'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // --- REGISTRATION ROLES ---

  Future<Map<String, dynamic>> registerStore({
    required String name,
    required String category,
    required String address,
  }) async {
    try {
      final response = await _dio.post('/user/store/register', data: {
        'name': name,
        'category': category,
        'address': address,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'message': 'Toko berhasil didaftarkan'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal daftar toko'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        return {'success': false, 'message': 'Anda sudah memiliki toko'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> registerDriver({
    required String vehicleType,
    required String plateNumber,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/user/driver/register', data: {
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
        'phone_number': phoneNumber,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'message': 'Berhasil mendaftar Driver'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal daftar driver'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        return {'success': false, 'message': 'Anda sudah terdaftar sebagai Driver'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // --- STORE PRODUCT MANAGEMENT ---

  Future<List<ProductModel>> getStoreProducts() async {
    try {
      final response = await _dio.get('/user/store/products');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching store products: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createStoreProduct(ProductModel product) async {
    try {
      final response = await _dio.post('/user/store/products', data: product.toJson());
      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'message': 'Produk berhasil ditambahkan', 'data': ProductModel.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal tambah produk'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateStoreProduct(ProductModel product) async {
    try {
      final response = await _dio.put('/user/store/products/${product.id}', data: product.toJson());
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Produk berhasil diperbarui'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update produk'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> deleteStoreProduct(int id) async {
    try {
      final response = await _dio.delete('/user/store/products/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Produk berhasil dihapus'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal hapus produk'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // --- UPLOAD METHODS ---

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post('/user/upload', data: formData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['url'];
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  // --- CONTENT METHODS ---

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/home/categories');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((c) => CategoryModel.fromJson(c))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    return [];
  }

  String getImageUrl(String path) {
    if (path.isEmpty) return 'https://via.placeholder.com/400x200?text=No+Image';
    if (path.startsWith('http')) return path;
    return 'http://localhost:8080$path';
  }

  Future<HomeResponseModel?> getHomeData() async {
    try {
      final response = await _dio.get('/home');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return HomeResponseModel.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching home data: $e');
    }
    return null;
  }

  Future<List<ProductModel>> getProductsByCategory(String slug) async {
    try {
      final response = await _dio.get('/home/products/$slug');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
    }
    return [];
  }

  // --- SEARCH METHODS ---

  Future<Map<String, List<dynamic>>> searchAll(String query) async {
    try {
      final response = await _dio.get('/home/search', queryParameters: {'q': query});
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final products = (data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
        final stores = (data['stores'] as List)
            .map((s) => StoreModel.fromJson(s))
            .toList();
        
        return {
          'products': products,
          'stores': stores,
        };
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
    }
    return {
      'products': [],
      'stores': [],
    };
  }
}
