import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../controllers/checkout_controller.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.put(CheckoutController());
    final ApiService api = ApiService();

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Konfirmasi Pesanan',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 1, 114, 112),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📦 SECTION: ALAMAT PENGIRIMAN (Physical Only)
              Obx(() {
                // Defensive touch
                controller.checkoutItems.length; 
                return controller.isPhysical 
                  ? Column(
                      children: [
                        _buildAddressCard(controller),
                        const SizedBox(height: 16),
                        _buildShippingPicker(controller),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink();
              }),
  
              // 📅 SECTION: SERVICE DATE (Service/Rental Only)
              Obx(() {
                // Defensive touch
                controller.checkoutItems.length;
                return !controller.isPhysical 
                  ? Column(
                      children: [
                        _buildServiceDateCard(context, controller),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink();
              }),
  
              // 🎫 SECTION: VOUCHER
              Obx(() {
                // Defensive touch
                controller.appliedVoucherCode.value;
                return _buildVoucherCard(controller);
              }),
  
              const SizedBox(height: 16),
  
              // 🛒 SECTION: RINGKASAN PESANAN
              _buildSectionTitle('Ringkasan Pesanan'),
              const SizedBox(height: 8),
              Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.checkoutItems.length,
                itemBuilder: (context, index) {
                  final item = controller.checkoutItems[index];
                  return _buildOrderItem(item, api);
                },
              )),
  
              const SizedBox(height: 16),
  
              // 🪙 SECTION: LOYALTY (LOCALPOINT)
              Obx(() => _buildLoyaltyCard(controller, api)),
  
              const SizedBox(height: 16),
  
              // 💳 SECTION: METODE PEMBAYARAN
              Obx(() => _buildPaymentPicker(controller, api)),
  
              const SizedBox(height: 16),
  
              // 💰 SECTION: RINCIAN PEMBAYARAN
              _buildPaymentDetails(controller, api),
              
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(controller, api),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildAddressCard(CheckoutController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                _buildSectionTitle('Alamat Pengiriman'),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Alamat Utama',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              controller.userAddress.value,
              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Read Only',
                style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDateCard(BuildContext context, CheckoutController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                _buildSectionTitle('Waktu Layanan'),
              ],
            ),
            const Divider(height: 24),
            InkWell(
              onTap: () => controller.pickDateTime(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.formattedDateTime,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: controller.selectedDateTime.value == null ? Colors.grey : AppColors.primary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(dynamic item, ApiService api) {
    final price = item.variant?.price ?? item.product?.price ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              api.getImageUrl(item.product?.imageUrl ?? ''),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Produk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${item.quantity} x ${api.formatCurrency(price)}',
                  style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            api.formatCurrency(price * item.quantity),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(CheckoutController controller, ApiService api) {
    return Obx(() => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal Pesanan', controller.subtotal.value, api, isLoading: controller.isCalculating.value),
            if (controller.isPhysical) ...[
              const SizedBox(height: 12),
              _buildPriceRow('Biaya Pengiriman', controller.shippingFee.value, api, isLoading: controller.isCalculating.value),
            ],
            if (controller.voucherDiscount.value > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow(
                'Potongan Voucher (${controller.appliedVoucherCode.value})', 
                -controller.voucherDiscount.value, 
                api, 
                color: Colors.red,
                isLoading: controller.isCalculating.value,
              ),
            ],
            if (controller.pointDiscount.value > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow(
                'Diskon LocalPoint', 
                -controller.pointDiscount.value, 
                api, 
                color: AppColors.primary,
                isLoading: controller.isCalculating.value,
              ),
            ],
            const Divider(height: 32),
            _buildPriceRow('Total Pembayaran', controller.totalAmount.value, api, isTotal: true, isLoading: controller.isCalculating.value),
          ],
        ),
      ),
    ));
  }

  Widget _buildVoucherCard(CheckoutController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                _buildSectionTitle('Punya Kode Voucher?'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.voucherController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode promo',
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => controller.applyVoucher(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: Text('Gunakan', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (controller.appliedVoucherCode.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Voucher ${controller.appliedVoucherCode.value} Terpasang!',
                      style: GoogleFonts.manrope(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingPicker(CheckoutController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: RadioGroup<String>(
        groupValue: controller.selectedShippingMethod.value,
        onChanged: (val) {
          if (val != null) {
            controller.selectedShippingMethod.value = val;
            controller.calculateTotals();
          }
        },
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text('Kirim via LocalSend', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Flat Rp 10.000', style: GoogleFonts.manrope(fontSize: 12)),
              secondary: const Icon(Icons.motorcycle, color: AppColors.primary),
              value: 'LOCALSEND',
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: Text('Ambil Sendiri', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Gratis - Langsung ke Toko', style: GoogleFonts.manrope(fontSize: 12)),
              secondary: const Icon(Icons.storefront, color: Colors.orange),
              value: 'SELF_PICKUP',
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(CheckoutController controller, ApiService api) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gunakan LocalPoint',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    'Tukarkan ${api.formatCurrency(controller.userPoints.value)} untuk diskon',
                    style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Obx(() => Switch(
              value: controller.usePoints.value,
              onChanged: (val) => controller.usePoints.value = val,
              activeThumbColor: AppColors.primary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPicker(CheckoutController controller, ApiService api) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Metode Pembayaran'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: RadioGroup<String>(
            groupValue: controller.selectedPaymentMethod.value,
            onChanged: (val) {
              if (val != null) {
                controller.selectedPaymentMethod.value = val;
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Transfer Bank', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Manual Verifikasi', style: GoogleFonts.manrope(fontSize: 12)),
                  secondary: const Icon(Icons.payments, color: AppColors.primary),
                  value: 'TRANSFER',
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: Text('Bayar di Tempat (COD)', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Khusus Kirim via LocalSend', style: GoogleFonts.manrope(fontSize: 12)),
                  secondary: const Icon(Icons.handshake, color: Colors.grey),
                  value: 'COD',
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, ApiService api, {bool isTotal = false, Color? color, bool isLoading = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[600],
          ),
        ),
        if (isLoading)
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? (isTotal ? AppColors.primary : Colors.black)),
            ),
          )
        else
          Text(
            (label == 'Biaya Pengiriman' && amount == 0) ? 'Gratis' : api.formatCurrency(amount),
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              color: (label == 'Biaya Pengiriman' && amount == 0) ? Colors.green : (color ?? (isTotal ? AppColors.primary : Colors.black)),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(CheckoutController controller, ApiService api) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600])),
                  Obx(() => controller.isCalculating.value 
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : Text(
                        api.formatCurrency(controller.totalAmount.value),
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.createOrder(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Buat Pesanan',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
