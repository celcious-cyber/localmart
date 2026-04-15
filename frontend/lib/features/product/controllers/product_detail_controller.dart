import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/home_data.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../checkout/screens/checkout_screen.dart';
import '../../auth/widgets/auth_utils.dart';

class ProductDetailController extends GetxController {
  final ProductModel product;
  
  ProductDetailController({required this.product});

  var selectedVariant = Rxn<ProductVariantModel>();
  var quantity = 1.obs;
  var userBalance = 0.obs;
  
  bool get needsVariant => product.variants.isNotEmpty && selectedVariant.value == null;

  @override
  void onInit() {
    super.onInit();
    _loadUserBalance();
  }

  Future<void> _loadUserBalance() async {
    if (!AuthUtils.isLoggedIn) return;
    // Logic to fetch balance would go here
  }

  void selectVariant(ProductVariantModel variant) {
    selectedVariant.value = variant;
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void addToCart() async {
    if (needsVariant) {
      _showVariantError();
      return;
    }

    if (!AuthUtils.isLoggedIn) {
      final success = await AuthUtils.showLoginRequirement(Get.context!);
      if (success != true) return;
    }
    
    final CartController cartController = Get.find<CartController>();
    cartController.addToCart(product, selectedVariant.value, quantity.value);
  }

  void buyNow() async {
    if (needsVariant) {
      _showVariantError();
      return;
    }

    if (!AuthUtils.isLoggedIn) {
      final success = await AuthUtils.showLoginRequirement(Get.context!);
      if (success != true) return;
    }

    // Create a virtual cart item for direct checkout
    final directItem = CartItemModel(
      id: 0, // Virtual ID
      userId: 0, 
      productId: product.id,
      variantId: selectedVariant.value?.id,
      quantity: quantity.value,
      createdAt: DateTime.now(),
      product: product,
      variant: selectedVariant.value,
    );
    
    // Navigate directly to Checkout with the single item
    Get.to(
      () => const CheckoutScreen(),
      arguments: {'items': [directItem]},
    );
  }

  void _showVariantError() {
    Get.snackbar(
      'Pilih Varian', 
      'Silakan pilih varian produk terlebih dahulu',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
