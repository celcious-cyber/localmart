import 'package:get/get.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/home_data.dart';
import '../../shared/models/store_models.dart';

class ModularDiscoveryController extends GetxController {
  final String moduleCode;
  final String serviceType;
  final ApiService _apiService = ApiService();

  ModularDiscoveryController({
    required this.moduleCode,
    required this.serviceType,
  });

  var isLoading = true.obs;
  var categories = <CategoryModel>[].obs;
  var featuredStores = <StoreModel>[].obs;
  var featuredProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading(true);
      
      // 1. Fetch categories for this service type
      final cats = await _apiService.getCategories(serviceType: serviceType);
      categories.assignAll(cats);

      // 2. Fetch stores for this module
      final stores = await _apiService.getStoresByModule(moduleCode);
      featuredStores.assignAll(stores);

      // 3. Fetch featured products for this service type
      final products = await _apiService.getDiscoveryProducts('umkm_pilihan', serviceType: serviceType);
      featuredProducts.assignAll(products);

    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshData() async {
    await fetchData();
  }
}
