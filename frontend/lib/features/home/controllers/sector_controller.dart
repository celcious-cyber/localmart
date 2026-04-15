import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class SectorController extends GetxController {
  final String moduleType;
  final ApiService _api = ApiService();

  SectorController({required this.moduleType});

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Fetch categories with type filter
      final fetchedCategories = await _api.getCategories(type: moduleType);
      categories.assignAll(fetchedCategories);

      // Collect all products from categories for the main list
      final allProducts = <ProductModel>[];
      for (var cat in fetchedCategories) {
        allProducts.addAll(cat.products);
      }
      products.assignAll(allProducts);

    } catch (e) {
      error.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh helper
  Future<void> refreshData() async {
    await fetchData();
  }
}
