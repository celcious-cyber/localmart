import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/home_data.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/store_models.dart';
import '../../shared/models/review_model.dart';
import '../../features/auth/widgets/auth_utils.dart';

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
          // Token expired or invalid, clear session and global flag
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user_token');
          await prefs.remove('user_data');
          AuthUtils.isLoggedIn = false;
        }
        return handler.next(e);
      },
    ));
  }

  // --- GENERIC METHODS ---
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
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

  Future<Map<String, dynamic>> deleteStore() async {
    try {
      final response = await _dio.delete('/user/store');
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Gagal menghapus toko'};
    }
  }

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

  Future<Map<String, dynamic>> updateStoreSettings({
    String? bannerUrl,
    String? logoUrl,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (bannerUrl != null) data['banner_url'] = bannerUrl;
      if (logoUrl != null) data['logo_url'] = logoUrl;
      if (description != null) data['description'] = description;

      final response = await _dio.patch('/user/store/settings', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true, 
          'message': 'Pengaturan toko diperbarui', 
          'data': StoreModel.fromJson(response.data['data'])
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update pengaturan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<List<StoreCategoryModel>> getStoreCategories() async {
    try {
      final response = await _dio.get('/user/store/categories');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((c) => StoreCategoryModel.fromJson(c))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching store categories: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createStoreCategory(String name, {int sortOrder = 0}) async {
    try {
      final response = await _dio.post('/user/store/categories', data: {
        'name': name,
        'sort_order': sortOrder,
      });
      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'data': StoreCategoryModel.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal buat etalase'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateStoreCategory(int id, String name, {int sortOrder = 0}) async {
    try {
      final response = await _dio.put('/user/store/categories/$id', data: {
        'name': name,
        'sort_order': sortOrder,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'data': StoreCategoryModel.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update etalase'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // --- REGISTRATION ROLES ---

  Future<Map<String, dynamic>> registerStore({
    required String name,
    required String category,
    required List<String> serviceTypes,
    required String address,
  }) async {
    try {
      final response = await _dio.post('/user/store/register', data: {
        'name': name,
        'category': category,
        'service_types': serviceTypes,
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

  Future<List<Map<String, String>>> getStoreConstants() async {
    try {
      final response = await _dio.get('/store/constants');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((m) => {
                  'code': m['code'] as String,
                  'name': m['name'] as String,
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching store constants: $e');
    }
    return [];
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

  Future<Map<String, dynamic>> createStoreProductMulti(Map<String, dynamic> data, List<Uint8List> images) async {
    try {
      final formData = FormData.fromMap(data);
      
      // Ensure store_category_ids are handled correctly for multipart
      if (data.containsKey('store_category_ids')) {
        final List ids = data['store_category_ids'];
        formData.fields.removeWhere((e) => e.key == 'store_category_ids');
        for (var id in ids) {
          formData.fields.add(MapEntry('store_category_ids[]', id.toString()));
        }
      }

      for (int i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(images[i], filename: 'product_image_$i.jpg'),
        ));
      }

      final response = await _dio.post('/user/store/products', data: formData);
      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'message': 'Produka berhasil ditambahkan', 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal tambah produk'};
    } catch (e) {
      debugPrint('Error createStoreProductMulti: $e');
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateStoreProductMulti(int id, Map<String, dynamic> data, List<Uint8List> images) async {
    try {
      final formData = FormData.fromMap(data);

      // Ensure store_category_ids are handled correctly for multipart
      if (data.containsKey('store_category_ids')) {
        final List ids = data['store_category_ids'];
        formData.fields.removeWhere((e) => e.key == 'store_category_ids');
        for (var id in ids) {
          formData.fields.add(MapEntry('store_category_ids[]', id.toString()));
        }
      }
      
      for (int i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(images[i], filename: 'update_image_$i.jpg'),
        ));
      }

      // We use POST with _method=PUT for multipart compatibility if needed, 
      // but Gin handles PUT multipart fine.
      final response = await _dio.put('/user/store/products/$id', data: formData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': 'Produk berhasil diperbarui'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update produk'};
    } catch (e) {
      debugPrint('Error updateStoreProductMulti: $e');
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

  Future<List<CategoryModel>> getCategories({String? type, String? serviceType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (serviceType != null) queryParams['service_type'] = serviceType;
      
      final response = await _dio.get('/home/categories', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((c) => CategoryModel.fromJson(c))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories ($type): $e');
    }
    return [];
  }

  String getImageUrl(String path) {
    if (path.isEmpty) return 'https://via.placeholder.com/400x200?text=No+Image';
    if (path.startsWith('http')) return path;
    return 'http://localhost:8080$path';
  }

  String formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}';
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

  Future<List<BannerModel>> getBanners({String position = 'home'}) async {
    try {
      final response = await _dio.get('/home/banners', queryParameters: {'position': position});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((b) => BannerModel.fromJson(b))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching banners ($position): $e');
    }
    return [];
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

  Future<List<ProductModel>> getProducts({int? categoryId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category_id'] = categoryId;
      
      final response = await _dio.get('/products', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching global products: $e');
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

  // --- FAVORITE METHODS ---

  Future<List<ProductModel>> getFavorites() async {
    try {
      final response = await _dio.get('/user/favorites');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final response = await _dio.post('/user/favorites/$productId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'is_favorited': response.data['data']['is_favorited'],
          'message': response.data['message'],
        };
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
    return {'success': false, 'message': 'Gagal memproses favorit'};
  }

  // --- CART METHODS ---

  Future<List<CartItemModel>> getCart() async {
    try {
      final response = await _dio.get('/user/cart');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((c) => CartItemModel.fromJson(c))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    try {
      final response = await _dio.post('/user/cart/add', data: {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal tambah ke keranjang'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Stok tidak mencukupi'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateCart(int cartId, int quantity) async {
    try {
      final response = await _dio.put('/user/cart/update/$cartId', data: {'quantity': quantity});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'data': CartItemModel.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal update keranjang'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Stok tidak mencukupi'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<bool> removeFromCart(int cartId) async {
    try {
      final response = await _dio.delete('/user/cart/remove/$cartId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  // --- CHECKOUT METHODS ---

  Future<Map<String, dynamic>> calculateCheckout(List<Map<String, dynamic>> items, {String? voucherCode, String? shippingMethod, bool usePoints = false}) async {
    try {
      final response = await _dio.post('/user/checkout/calculate', data: {
        'items': items,
        'voucher_code': voucherCode,
        'shipping_method': shippingMethod,
        'use_points': usePoints,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal kalkulasi checkout'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
    String? serviceDate,
    String? voucherCode,
    required String paymentMethod,
    required String shippingMethod,
    bool usePoints = false,
  }) async {
    try {
      final response = await _dio.post('/user/checkout/create', data: {
        'items': items,
        'shipping_address': shippingAddress,
        'service_date': serviceDate,
        'voucher_code': voucherCode,
        'payment_method': paymentMethod,
        'shipping_method': shippingMethod,
        'use_points': usePoints,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal membuat pesanan'};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Stok tidak mencukupi'};
      }
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<List<ProductModel>> getDiscoveryProducts(String tag, {String? serviceType}) async {
    try {
      final queryParams = <String, dynamic>{'tag': tag};
      if (serviceType != null) queryParams['service_type'] = serviceType;
      
      final response = await _dio.get('/home/products/discovery', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['success']) {
        return (response.data['data'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- STORE METHODS ---

  Future<StoreDetailWrapper?> getStoreDetail(int id) async {
    try {
      final response = await _dio.get('/stores/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return StoreDetailWrapper.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching store detail: $e');
      return null;
    }
  }

  Future<List<StoreModel>> getStoresByModule(String module) async {
    try {
      final response = await _dio.get('/home/stores', queryParameters: {'module': module});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((s) => StoreModel.fromJson(s))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching stores for module $module: $e');
    }
    return [];
  }

  Future<List<ProductModel>> getStoreProductsPublic(int id, {int? categoryId, int? storeCategoryId, int page = 1}) async {
    try {
      String path = '/stores/$id/products?page=$page';
      if (categoryId != null) {
        path += '&category_id=$categoryId';
      }
      if (storeCategoryId != null) {
        path += '&store_category_id=$storeCategoryId';
      }
      final response = await _dio.get(path);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List?)
                ?.map((p) => ProductModel.fromJson(p))
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching store products: $e');
      return [];
    }
  }

  Future<List<StoreCategoryModel>> getStoreCategoriesPublic(int storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data']['categories'] as List?)
                ?.map((c) => StoreCategoryModel.fromJson(c))
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching public categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteStoreCategory(int id) async {
    try {
      final response = await _dio.delete('/user/store/categories/$id');
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Gagal menghapus etalase'};
    }
  }

  Future<Map<String, dynamic>> assignProductsToCategory(int? categoryId, List<int> productIds) async {
    try {
      final response = await _dio.post('/user/store/categories/assign', data: {
        'category_id': categoryId,
        'product_ids': productIds,
      });
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Gagal memindahkan produk'};
    }
  }

  Future<Map<String, dynamic>> toggleFollowStore(int id) async {
    try {
      final response = await _dio.post('/user/stores/$id/follow');
      if (response.data['success'] == true) {
        return {'success': true, 'message': response.data['message'], 'is_following': response.data['data']['is_following']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal memproses'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<bool> checkFollowStatus(int id) async {
    if (!await isLoggedIn()) return false;
    try {
      final response = await _dio.get('/user/stores/$id/following');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['is_following'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createProductReview(int productId, int rating, String comment) async {
    try {
      final response = await _dio.post('/user/products/$productId/review', data: {
        'rating': rating,
        'comment': comment,
      });
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Gagal mengirim ulasan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> checkReviewEligibility(int id) async {
    if (!await isLoggedIn()) return {'success': true, 'data': {'can_review': false}};
    try {
      final response = await _dio.get('/user/products/$id/review/eligibility');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<List<ReviewModel>> getProductReviews(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/reviews');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List?)
                ?.map((r) => ReviewModel.fromJson(r))
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching product reviews: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductDetail(int productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product detail: $e');
      return null;
    }
  }

  // --- CHAT SYSTEM METHODS ---

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/user/conversations');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    }
    return [];
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get('/user/conversations/$conversationId/messages');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> startConversation(int targetUserId) async {
    try {
      final response = await _dio.post('/user/conversations/start', data: {
        'target_user_id': targetUserId,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Error starting conversation: $e');
    }
    return {};
  }
}
