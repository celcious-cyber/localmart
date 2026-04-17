import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/api_service.dart';
import 'package:get/get.dart';
import '../controllers/registration_controller.dart';

class StoreRegistrationForm extends StatefulWidget {
  final Function(String storeName, String category) onRegister;

  const StoreRegistrationForm({super.key, required this.onRegister});

  @override
  State<StoreRegistrationForm> createState() => _StoreRegistrationFormState();
}

class _StoreRegistrationFormState extends State<StoreRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final RegistrationController _regController = Get.put(RegistrationController(), permanent: true);
  
  List<Map<String, String>> _businessModules = [];
  bool _isLoadingModules = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    final modules = await ApiService().getStoreConstants();
    if (mounted) {
      setState(() {
        _businessModules = modules;
        _isLoadingModules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 64, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Buka Toko UMKM Baru',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Mulailah berbisnis di LocalMart KSB',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
            _buildLabel('Nama Toko'),
            TextFormField(
              initialValue: _regController.storeName.value,
              decoration: _inputDecoration('Contoh: Bakso Taliwang Berkah'),
              validator: (v) => v == null || v.isEmpty ? 'Nama toko wajib diisi' : null,
              onChanged: (v) => _regController.updateStoreName(v),
            ),
            const SizedBox(height: 20),
            _buildLabel('Kategori Bisnis (Pilih minimal satu)'),
            _isLoadingModules
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Obx(() => Column(
                      children: _businessModules.map((m) {
                        final code = m['code']!;
                        final name = m['name']!;
                        final isSelected = _regController.selectedModules.contains(code);
                        return CheckboxListTile(
                          title: Text(
                            name,
                            softWrap: true,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          activeColor: Colors.orange,
                          value: isSelected,
                          onChanged: (_) => _regController.toggleModule(code),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    )),
                  ),
            Obx(() => (!_isLoadingModules && _regController.selectedModules.isEmpty)
               ? Padding(
                 padding: const EdgeInsets.only(top: 8, left: 16),
                 child: Text('Pilih minimal 1 kategori bisnis', style: TextStyle(color: Colors.red[700], fontSize: 12)),
               )
               : const SizedBox.shrink()),
            const SizedBox(height: 20),
            _buildLabel('Alamat Lengkap Toko'),
            TextFormField(
              initialValue: _regController.address.value,
              maxLines: 2,
              decoration: _inputDecoration('Contoh: Jl. Raya KM 01, Taliwang'),
              validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
              onChanged: (v) => _regController.updateAddress(v),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Buka Toko Sekarang',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 120), // Tambahkan ruang agar tidak tertutup nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_regController.selectedModules.isEmpty) {
        AppAlert.info('Kategori Bisnis', 'Silakan pilih minimal 1 kategori bisnis untuk toko Anda');
        return;
      }

      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      final result = await ApiService().registerStore(
        name: _regController.storeName.value,
        category: _regController.selectedModules.isNotEmpty ? _businessModules.firstWhere((m) => m['code'] == _regController.selectedModules.first)['name']! : '',
        serviceTypes: _regController.selectedModules.toList(),
        address: _regController.address.value,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup loading

        if (result['success']) {
          AppAlert.success('Toko Berhasil Dibuka', result['message'] ?? 'Selamat mulai berbisnis!');
          final name = _regController.storeName.value;
          final categories = _regController.selectedModules.join(', ');
          
          // RESET LOGIC: Clear form only on success
          _regController.clearForm();
          
          widget.onRegister(name, categories);
        } else {
          AppAlert.error('Pendaftaran Gagal', result['message'] ?? 'Terjadi kesalahan saat membuka toko');
        }
      }
    }
  }
}
