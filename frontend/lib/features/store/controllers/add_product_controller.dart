import 'package:get/get.dart';
import '../../../shared/models/home_data.dart';
import '../../../shared/models/store_models.dart';

class AddProductController extends GetxController {
  // Use Rx variants for persistence
  final RxString name = ''.obs;
  final RxString price = ''.obs;
  final RxString description = ''.obs;
  final RxString serviceType = 'mart'.obs;
  final RxString productType = 'BARANG'.obs;
  final Rxn<CategoryModel> selectedCategory = Rxn<CategoryModel>();
  final RxList<StoreCategoryModel> selectedStoreCategories = <StoreCategoryModel>[].obs;
  
  // Track if we are editing an existing product
  int? editingProductId;

  void setFromProduct(ProductModel product) {
    editingProductId = product.id;
    name.value = product.name;
    price.value = product.price.toInt().toString();
    description.value = product.description;
    serviceType.value = product.serviceType;
    productType.value = product.productType;
    // Note: selectedCategory and selectedStoreCategories would need lookup
  }

  void clear() {
    editingProductId = null;
    name.value = '';
    price.value = '';
    description.value = '';
    serviceType.value = 'mart';
    productType.value = 'BARANG';
    selectedCategory.value = null;
    selectedStoreCategories.clear();
  }
}
