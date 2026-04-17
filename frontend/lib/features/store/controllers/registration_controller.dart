import 'package:get/get.dart';

class RegistrationController extends GetxController {
  final RxString storeName = ''.obs;
  final RxString address = ''.obs;
  final RxList<String> selectedModules = <String>[].obs;
  
  // Track if we are already in the middle of a registration
  final RxBool hasStarted = false.obs;

  void updateStoreName(String val) {
    storeName.value = val;
    hasStarted.value = true;
  }

  void updateAddress(String val) {
    address.value = val;
    hasStarted.value = true;
  }

  void toggleModule(String code) {
    if (selectedModules.contains(code)) {
      selectedModules.remove(code);
    } else {
      selectedModules.add(code);
    }
    hasStarted.value = true;
  }

  void clearForm() {
    storeName.value = '';
    address.value = '';
    selectedModules.clear();
    hasStarted.value = false;
  }
}
