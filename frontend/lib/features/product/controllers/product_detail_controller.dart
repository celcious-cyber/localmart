import 'package:get/get.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/models/home_data.dart';
import '../../../shared/models/review_model.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../checkout/screens/checkout_screen.dart';
import '../../auth/widgets/auth_utils.dart';
import '../../../core/services/api_service.dart';

class ProductDetailController extends GetxController {
  final ProductModel product;
  final _api = ApiService();
  
  ProductDetailController({required this.product});

  var selectedVariant = Rxn<ProductVariantModel>();
  var quantity = 1.obs;
  var userBalance = 0.obs;
  var canReview = false.obs;
  var reviews = <ReviewModel>[].obs;
  var isLoadingReviews = false.obs;
  var productDetail = Rxn<ProductModel>();
  var isLoadingDetail = false.obs;
  
  bool get needsVariant => product.variants.isNotEmpty && selectedVariant.value == null;

  @override
  void onInit() {
    super.onInit();
    productDetail.value = product; // Set initial data
    _loadUserBalance();
    checkReviewEligibility();
    fetchReviews();
    fetchProductDetail();
  }

  Future<void> checkReviewEligibility() async {
    final result = await _api.checkReviewEligibility(product.id);
    if (result['success'] && result['data'] != null) {
      canReview.value = result['data']['can_review'] ?? false;
    }
  }

  Future<void> submitReview(int rating, String comment) async {
    final result = await _api.createProductReview(product.id, rating, comment);
    if (result['success']) {
      AppAlert.success('Terima kasih!', 'Ulasanmu sangat membantu warga KSB lainnya.');
      canReview.value = false; // Successfully reviewed
      fetchReviews(); // Refresh list
      fetchProductDetail(); // Refresh rating
    } else {
      AppAlert.error('Gagal', result['message']);
    }
  }

  Future<void> fetchReviews() async {
    isLoadingReviews.value = true;
    try {
      final list = await _api.getProductReviews(product.id);
      reviews.assignAll(list);
    } finally {
      isLoadingReviews.value = false;
    }
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

  Future<void> fetchProductDetail() async {
    isLoadingDetail.value = true;
    try {
      final updated = await _api.getProductDetail(product.id);
      if (updated != null) {
        productDetail.value = updated;
      }
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void _showVariantError() {
    AppAlert.info('Pilih Varian', 'Silakan pilih varian produk terlebih dahulu');
  }
}
