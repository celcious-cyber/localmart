import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class FavoritesController extends GetxController {
  final ApiService _api = ApiService();

  var favorites = <ProductModel>[].obs;
  var isLoading = false.obs;
  var favoriteIds = <int>{}.obs; // Use a set for O(1) lookups in UI

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    // Only attempt to load if user is logged in
    if (!await _api.isLoggedIn()) return;

    isLoading.value = true;
    try {
      final data = await _api.getFavorites();
      favorites.assignAll(data);
      
      // Update the quick lookup set
      favoriteIds.clear();
      for (var p in data) {
        favoriteIds.add(p.id);
      }
    } catch (e) {
      debugPrint('Error loading favorites in controller: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool isFavorited(int productId) {
    return favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    // 1. Check Login
    if (!await _api.isLoggedIn()) {
      Get.snackbar(
        'Perlu Login',
        'Silakan login untuk menyimpan produk favorit Anda',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // 2. Optimized UX: Optimistic Update
    final isCurrentlyFavorited = isFavorited(product.id);
    
    if (isCurrentlyFavorited) {
      favoriteIds.remove(product.id);
      favorites.removeWhere((p) => p.id == product.id);
    } else {
      favoriteIds.add(product.id);
      favorites.add(product);
    }

    // 3. API Call
    final result = await _api.toggleFavorite(product.id);
    
    if (result['success']) {
      // Sync with server response just in case
      final bool serverStatus = result['is_favorited'];
      if (serverStatus != !isCurrentlyFavorited) {
        // If out of sync, reload
        loadFavorites();
      }
      
      Get.snackbar(
        'Berhasil',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } else {
      // Revert optimistic update on failure
      if (isCurrentlyFavorited) {
        favoriteIds.add(product.id);
        favorites.add(product);
      } else {
        favoriteIds.remove(product.id);
        favorites.removeWhere((p) => p.id == product.id);
      }
      
      Get.snackbar(
        'Gagal',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
