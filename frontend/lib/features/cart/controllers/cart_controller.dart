import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class CartController extends GetxController {
  final ApiService _api = ApiService();

  var cartItems = <CartItemModel>[].obs;
  var isLoading = false.obs;
  var isUpdatingId = 0.obs; // Tracks specific item being updated for mini-loaders
  var cartUpdateSignal = 0.obs; // Trigger for animations

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  double get totalPrice {
    return cartItems.fold(0, (sum, item) {
      double price = item.variant?.price ?? item.product?.price ?? 0;
      return sum + (price * item.quantity);
    });
  }

  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> fetchCart() async {
    isLoading.value = true;
    try {
      final items = await _api.getCart();
      cartItems.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(ProductModel product, ProductVariantModel? variant, int quantity) async {
    isLoading.value = true;
    try {
      final result = await _api.addToCart(
        productId: product.id,
        variantId: variant?.id,
        quantity: quantity,
      );

      if (result['success']) {
        HapticFeedback.lightImpact();
        cartUpdateSignal.value++;
        
        Get.snackbar(
          'Berhasil',
          '${product.name} dimasukkan ke keranjang',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchCart(); // Refresh cart list
      } else {
        Get.snackbar(
          'Gagal',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    if (newQuantity < 1) return;
    
    isUpdatingId.value = cartId; // Start mini-loader for this item
    try {
      final result = await _api.updateCart(cartId, newQuantity);
      if (result['success']) {
        HapticFeedback.lightImpact();
        cartUpdateSignal.value++;
        
        // PESSIMISTIC UPDATE: Local state only changes after successful API response
        int index = cartItems.indexWhere((item) => item.id == cartId);
        if (index != -1) {
          cartItems[index] = result['data'];
        }
      } else {
        Get.snackbar(
          'Opps!',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } finally {
      isUpdatingId.value = 0; // Stop mini-loader
    }
  }

  Future<void> removeItem(int cartId) async {
    isUpdatingId.value = cartId;
    try {
      final success = await _api.removeFromCart(cartId);
      if (success) {
        cartItems.removeWhere((item) => item.id == cartId);
      }
    } finally {
      isUpdatingId.value = 0;
    }
  }
}
