import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class HomeDataController extends GetxController {
  final ApiService _api = ApiService();

  final Rxn<HomeResponseModel> homeData = Rxn<HomeResponseModel>();
  final RxBool isLoading = true.obs;

  // State per module
  final RxMap<String, List<ProductModel>> moduleProducts = <String, List<ProductModel>>{}.obs;
  final RxMap<String, bool> isModuleLoading = <String, bool>{}.obs;
  final RxMap<String, int> activeCategoryIds = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    try {
      isLoading.value = true;
      final data = await _api.getHomeData();
      if (data != null) {
        homeData.value = data;
        
        // Initialize module states from home data
        for (var module in data.modules) {
          moduleProducts[module.slug] = module.products;
          isModuleLoading[module.slug] = false;
          
          // Set first category as active by default if categories exist
          if (module.categories.isNotEmpty) {
            activeCategoryIds[module.slug] = module.categories.first.id;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchCategory(String moduleSlug, int categoryId) async {
    // Avoid double fetch
    if (activeCategoryIds[moduleSlug] == categoryId) return;

    try {
      isModuleLoading[moduleSlug] = true;
      activeCategoryIds[moduleSlug] = categoryId;
      
      // Artificial delay for premium shimmer feel as requested
      await Future.delayed(const Duration(milliseconds: 600));

      final products = await _api.getProducts(categoryId: categoryId);
      moduleProducts[moduleSlug] = products;
    } catch (e) {
      debugPrint('Error switching category: $e');
    } finally {
      isModuleLoading[moduleSlug] = false;
    }
  }

  List<ProductModel> getProductsForModule(String moduleSlug) {
    return moduleProducts[moduleSlug] ?? [];
  }

  bool isModuleRefreshing(String moduleSlug) {
    return isModuleLoading[moduleSlug] ?? false;
  }

  int? getActiveCategoryId(String moduleSlug) {
    return activeCategoryIds[moduleSlug];
  }
}
