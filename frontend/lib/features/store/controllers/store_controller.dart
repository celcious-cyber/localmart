import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../../../shared/models/store_models.dart';
import '../../../core/utils/app_alert.dart';
import '../../auth/widgets/auth_utils.dart';

class StoreController extends GetxController {
  final int storeId;
  final ApiService _api = ApiService();

  StoreController({required this.storeId});

  // Store Detail State
  final Rxn<StoreDetailWrapper> storeDetail = Rxn<StoreDetailWrapper>();
  final RxBool isLoading = true.obs;
  final RxBool isFollowing = false.obs;
  final RxBool isOwner = false.obs;

  // Products State
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxInt selectedCategoryId = 0.obs;
  final RxInt selectedStoreCategoryId = 0.obs;

  // Management State (For Sellers)
  final RxList<StoreCategoryModel> storeCategories = <StoreCategoryModel>[].obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Reaction: re-fetch products when store category changed
    ever(selectedStoreCategoryId, (int catId) {
      fetchStoreProducts(storeCategoryId: catId > 0 ? catId : null);
    });

    fetchStoreDetail();
    fetchStoreProducts();
    checkFollowStatus();
  }

  Future<void> fetchStoreDetail() async {
    isLoading.value = true;
    try {
      final detail = await _api.getStoreDetail(storeId);
      if (detail != null) {
        storeDetail.value = detail;
        
        // Check if owner
        if (AuthUtils.isLoggedIn) {
          final profile = await _api.getProfile();
          if (profile != null && profile.id == detail.store.userId) {
            isOwner.value = true;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStoreProducts({int? categoryId, int? storeCategoryId}) async {
    isLoadingProducts.value = true;
    try {
      final list = await _api.getStoreProductsPublic(
        storeId, 
        categoryId: categoryId,
        storeCategoryId: storeCategoryId,
      );
      products.assignAll(list);
      
      // For Beranda/Highlights, just take top 4
      if (categoryId == null && storeCategoryId == null) {
        featuredProducts.assignAll(list.take(4).toList());
      }
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> checkFollowStatus() async {
    if (AuthUtils.isLoggedIn) {
      isFollowing.value = await _api.checkFollowStatus(storeId);
    }
  }

  Future<void> toggleFollow() async {
    if (!AuthUtils.isLoggedIn) {
      final success = await AuthUtils.showLoginRequirement(Get.context!);
      if (success != true) return;
    }

    if (isOwner.value) {
      AppAlert.error('Gagal', 'Ciee, mau follow diri sendiri ya? Enggak bisa dong!');
      return;
    }

    final result = await _api.toggleFollowStore(storeId);
    if (result['success']) {
      isFollowing.value = result['is_following'];
      
      // Update follower count locally for immediate feedback
      if (storeDetail.value != null) {
        final currentCount = storeDetail.value!.followerCount;
        storeDetail.value = StoreDetailWrapper(
          store: storeDetail.value!.store,
          followerCount: isFollowing.value ? currentCount + 1 : currentCount - 1,
          transactionCount: storeDetail.value!.transactionCount,
          categories: storeDetail.value!.categories,
        );
      }

      AppAlert.success(
        isFollowing.value ? 'Berhasil Mengikuti' : 'Berhenti Mengikuti',
        result['message'],
      );
    } else {
      AppAlert.error('Gagal', result['message']);
    }
  }

  void filterByCategory(int categoryId) {
    if (selectedCategoryId.value == categoryId) {
      selectedCategoryId.value = 0;
      fetchStoreProducts();
    } else {
      selectedStoreCategoryId.value = 0; // Clear etalase filter
      selectedCategoryId.value = categoryId;
      fetchStoreProducts(categoryId: categoryId);
    }
  }

  void filterByStoreCategory(int storeCategoryId) {
    if (selectedStoreCategoryId.value == storeCategoryId) {
      selectedStoreCategoryId.value = 0;
    } else {
      selectedCategoryId.value = 0; // Clear global category filter
      selectedStoreCategoryId.value = storeCategoryId;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SELLER MANAGEMENT LOGIC
  // ══════════════════════════════════════════════════════════════

  Future<void> fetchStoreCategories() async {
    try {
      final list = await _api.getStoreCategories();
      storeCategories.assignAll(list);
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> createCategory(String name) async {
    isProcessing.value = true;
    try {
      final result = await _api.createStoreCategory(name, sortOrder: 0);
      if (result['success']) {
        AppAlert.success('Etalase Dibuat', 'Etalase "$name" berhasil ditambahkan!');
        fetchStoreCategories();
        fetchStoreDetail(); // Refresh detail for counts
      } else {
        AppAlert.error('Gagal', result['message']);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> editCategory(int id, String name) async {
    isProcessing.value = true;
    try {
      final result = await _api.updateStoreCategory(id, name, sortOrder: 0);
      if (result['success']) {
        AppAlert.success('Etalase Diperbarui', 'Perubahan berhasil disimpan!');
        fetchStoreCategories();
      } else {
        AppAlert.error('Gagal', result['message']);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    isProcessing.value = true;
    try {
      final result = await _api.deleteStoreCategory(id);
      if (result['success']) {
        AppAlert.success('Etalase Dihapus', 'Etalase berhasil dihapus. Produk dipindahkan ke "Semua Produk".');
        fetchStoreCategories();
        fetchStoreDetail();
        fetchStoreProducts(); // Refresh products list
      } else {
        AppAlert.error('Gagal', result['message']);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> assignProductsToCategory(int? categoryId, List<int> productIds) async {
    isProcessing.value = true;
    try {
      final result = await _api.assignProductsToCategory(categoryId, productIds);
      if (result['success']) {
        AppAlert.success('Berhasil', result['message']);
        fetchStoreProducts(); // Refresh inventory
      } else {
        AppAlert.error('Gagal', result['message']);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  // Helper for UI to get unique categories from products
  List<CategoryModel> get availableCategories {
    // This is a simplified logic. In a real app, backend might provide this.
    // For now, we extract from current products or just show some defaults.
    return []; // Will implement if needed or use global categories
  }
}
