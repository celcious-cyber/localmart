import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/widgets/auth_utils.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();
  
  final ApiService _api = ApiService();
  
  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    isLoading.value = true;
    final loggedIn = await _api.isLoggedIn();
    isLoggedIn.value = loggedIn;
    AuthUtils.isLoggedIn = loggedIn;
    
    if (loggedIn) {
      await refreshUser();
    }
    isLoading.value = false;
  }

  Future<void> refreshUser() async {
    try {
      final profile = await _api.getProfile();
      if (profile != null) {
        user.value = profile;
        isLoggedIn.value = true;
        AuthUtils.isLoggedIn = true;
      } else {
        // Session might be expired
        isLoggedIn.value = false;
        AuthUtils.isLoggedIn = false;
        user.value = null;
      }
    } catch (e) {
      // Quiet fail or handle error
    }
  }

  Future<void> logout() async {
    await _api.logout();
    user.value = null;
    isLoggedIn.value = false;
    AuthUtils.isLoggedIn = false;
  }
}
