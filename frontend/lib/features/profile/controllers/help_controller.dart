import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class HelpController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final RxMap<String, List<dynamic>> helpData = <String, List<dynamic>>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHelpContent();
  }

  Future<void> fetchHelpContent() async {
    // If we already have data, don't show loading (cache-style)
    if (helpData.isNotEmpty) return;

    try {
      isLoading.value = true;
      final response = await _apiService.get('/help');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = response.data['data'];
        helpData.value = rawData.map((key, value) => MapEntry(key, value as List<dynamic>));
      }
    } catch (e) {
      Get.snackbar('Koneksi Gagal', 'Tidak dapat memuat pusat bantuan.');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh helper
  Future<void> refreshHelp() async {
    helpData.clear();
    await fetchHelpContent();
  }
}
