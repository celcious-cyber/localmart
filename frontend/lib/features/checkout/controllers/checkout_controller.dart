import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../../cart/controllers/cart_controller.dart';
import '../screens/order_success_screen.dart';
import '../../auth/widgets/auth_utils.dart';

class CheckoutController extends GetxController {
  final ApiService _api = ApiService();
  
  // Checkout Items (can be from cart or direct)
  var checkoutItems = <CartItemModel>[].obs;
  
  var isLoading = false.obs;
  var isCalculating = false.obs;
  
  // Rincian Biaya
  var subtotal = 0.0.obs;
  var shippingFee = 0.0.obs;
  var voucherDiscount = 0.0.obs;
  var pointDiscount = 0.0.obs;
  var totalAmount = 0.0.obs;
  
  // Economics State
  var voucherController = TextEditingController();
  var appliedVoucherCode = "".obs;
  var selectedPaymentMethod = "TRANSFER".obs; 
  var selectedShippingMethod = "LOCALSEND".obs; 
  var usePoints = false.obs;
  
  // User Balance
  var userPoints = 0.0.obs;
  
  // User Info
  var userAddress = "Jl. Undru, Taliwang, Sumbawa Barat".obs; 
  
  // Service Date & Time (for Jasa/Rental)
  var selectedDateTime = Rxn<DateTime>();
  
  bool get isPhysical {
    return checkoutItems.any((item) => item.product?.productType == 'BARANG');
  }

  @override
  void onInit() {
    super.onInit();
    
    // Initialize items from arguments or fallback to cart
    final args = Get.arguments;
    if (args != null && args['items'] != null) {
      checkoutItems.assignAll((args['items'] as List).cast<CartItemModel>());
    } else {
      checkoutItems.assignAll(Get.find<CartController>().cartItems);
    }

    calculateTotals();
    _loadUserAddress();
    _loadUserBalance();
    
    // Auto-recalculate when using points or shipping method changes
    ever(usePoints, (bool val) {
      if (val && userPoints.value <= 0) {
        usePoints.value = false;
        AppAlert.info(
          'LocalPoint', 
          'Yah, poin kamu masih kosong nih. Kumpulkan poin dulu yuk!',
        );
        return;
      }
      calculateTotals();
    });
    ever(selectedShippingMethod, (_) => calculateTotals());
  }

  Future<void> _loadUserBalance() async {
    if (!AuthUtils.isLoggedIn) return;
    try {
      final user = await _api.getProfile();
      if (user != null) {
        userPoints.value = user.points;
      }
    } catch (e) {
      debugPrint('Error loading user balance: $e');
    }
  }

  Future<void> _loadUserAddress() async {
    // Current Address Logic
  }

  Future<void> applyVoucher() async {
    if (voucherController.text.isEmpty) return;
    appliedVoucherCode.value = voucherController.text.trim();
    await calculateTotals();
  }

  Future<void> calculateTotals() async {
    isCalculating.value = true;
    try {
      final itemsData = checkoutItems.map((item) => {
        'product_id': item.productId,
        'variant_id': item.variantId,
        'quantity': item.quantity,
      }).toList();

      final result = await _api.calculateCheckout(
        itemsData, 
        voucherCode: appliedVoucherCode.value.isEmpty ? null : appliedVoucherCode.value,
        shippingMethod: selectedShippingMethod.value,
        usePoints: usePoints.value,
      );
      
      if (result['success'] == true) {
        final data = result['data'];
        subtotal.value = double.tryParse(data?['subtotal']?.toString() ?? '0') ?? 0.0;
        shippingFee.value = double.tryParse(data?['shipping_fee']?.toString() ?? '0') ?? 0.0;
        voucherDiscount.value = double.tryParse(data?['voucher_discount']?.toString() ?? '0') ?? 0.0;
        pointDiscount.value = double.tryParse(data?['point_discount']?.toString() ?? '0') ?? 0.0;
        totalAmount.value = double.tryParse(data?['total_amount']?.toString() ?? '0') ?? 0.0;
        
        if (appliedVoucherCode.value.isNotEmpty && voucherDiscount.value == 0) {
          AppAlert.info('Voucher', 'Kode voucher tidak valid atau syarat tidak terpenuhi');
          appliedVoucherCode.value = "";
          voucherController.clear();
        }
      }
    } finally {
      isCalculating.value = false;
    }
  }

  Future<void> pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        selectedDateTime.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  String get formattedDateTime {
    if (selectedDateTime.value == null) return "Pilih Tanggal & Waktu";
    return DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime.value!);
  }

  Future<void> createOrder() async {
    // Validation
    if (!isPhysical && selectedDateTime.value == null) {
      AppAlert.info('Opps!', 'Silakan pilih waktu layanan terlebih dahulu');
      return;
    }

    // Balance check is handled on backend, but we can do a quick check here if using points
    // if (usePoints.value && userPoints.value < pointDiscount.value) { ... }
    // Actually, backend Calculate already returns what's possible.

    isLoading.value = true;
    try {
      final itemsData = checkoutItems.map((item) => {
        'product_id': item.productId,
        'variant_id': item.variantId,
        'quantity': item.quantity,
      }).toList();

      final result = await _api.createOrder(
        items: itemsData,
        shippingAddress: userAddress.value,
        serviceDate: selectedDateTime.value != null ? formattedDateTime : null,
        voucherCode: appliedVoucherCode.value.isEmpty ? null : appliedVoucherCode.value,
        paymentMethod: selectedPaymentMethod.value,
        shippingMethod: isPhysical ? selectedShippingMethod.value : 'SELF_PICKUP',
        usePoints: usePoints.value,
      );

      if (result['success']) {
        // Success Logic
        Get.find<CartController>().fetchCart(); // Refresh cart
        Get.off(() => OrderSuccessScreen(
          orderNumber: result['data']['order_number'],
        ));
      } else {
        AppAlert.error('Gagal', result['message'] ?? 'Terjadi kesalahan');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
