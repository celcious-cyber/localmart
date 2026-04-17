import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/app_alert.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/store_models.dart';
import '../admin/screens/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/controllers/auth_controller.dart';

class MyStoreScreen extends StatefulWidget {
  const MyStoreScreen({super.key});

  @override
  State<MyStoreScreen> createState() => _MyStoreScreenState();
}

class _MyStoreScreenState extends State<MyStoreScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  StoreModel? _store;
  double? _latitude;
  double? _longitude;
  
  final ImagePicker _picker = ImagePicker();
  Uint8List? _newLogoBytes;
  Uint8List? _newBannerBytes;
  String? _currentLogoUrl;
  String? _currentBannerUrl;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    final dashboard = await ApiService().getStoreDashboard();
    if (mounted && dashboard != null) {
      setState(() {
        _store = dashboard.store;
        _nameController.text = _store!.name;
        _descriptionController.text = _store!.description;
        _addressController.text = _store!.address;
        _latitude = _store!.latitude;
        _longitude = _store!.longitude;
        _currentLogoUrl = _store!.imageUrl;
        _currentBannerUrl = _store!.bannerUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: isLogo ? 512 : 1280,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isLogo) {
          _newLogoBytes = bytes;
        } else {
          _newBannerBytes = bytes;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      // 1. Upload images if changed
      String? logoUrl = _currentLogoUrl;
      String? bannerUrl = _currentBannerUrl;

      if (_newLogoBytes != null) {
        logoUrl = await ApiService().uploadImage(_newLogoBytes!, 'store_logo.jpg');
      }
      if (_newBannerBytes != null) {
        bannerUrl = await ApiService().uploadImage(_newBannerBytes!, 'store_banner.jpg');
      }

      // 2. Update Profile & Settings
      final result = await ApiService().updateStoreProfile(
        name: _nameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: logoUrl, // Basic profile still uses this
      );

      // Handle Banner via new settings endpoint if we want absolute sync
      if (bannerUrl != null && bannerUrl != _currentBannerUrl) {
         await ApiService().updateStoreSettings(bannerUrl: bannerUrl);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (result['success']) {
          // Trigger global sync for profile photo
          Get.find<AuthController>().refreshUser();
          
          AppAlert.success('Profil Diperbarui', 'Berhasil menyimpan perubahan identitas toko!');
          Navigator.pop(context, true);
        } else {
          AppAlert.error('Gagal Menyimpan', result['message'] ?? 'Terjadi kesalahan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppAlert.error('Error', 'Terjadi kesalahan sistem: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Pengaturan Toko',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStoreHeader(),
                  const SizedBox(height: 16),
                  _buildStoreForm(),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildSaveButton(),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Banner Area
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: _newBannerBytes != null
                    ? DecorationImage(image: MemoryImage(_newBannerBytes!), fit: BoxFit.cover)
                    : (_currentBannerUrl != null && _currentBannerUrl!.isNotEmpty
                        ? DecorationImage(image: CachedNetworkImageProvider(ApiService().getImageUrl(_currentBannerUrl!)), fit: BoxFit.cover)
                        : null),
              ),
              child: Stack(
                children: [
                  if (_newBannerBytes == null && (_currentBannerUrl == null || _currentBannerUrl!.isEmpty))
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey[400], size: 40),
                          const SizedBox(height: 8),
                          Text("Tambah Banner Toko", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Identity Area (Logo)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Center(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: _newLogoBytes != null
                          ? DecorationImage(image: MemoryImage(_newLogoBytes!), fit: BoxFit.cover)
                          : DecorationImage(
                              image: CachedNetworkImageProvider(_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty
                                ? ApiService().getImageUrl(_currentLogoUrl!)
                                : 'https://ui-avatars.com/api/?name=${_store?.name ?? "Store"}&background=random'),
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Verifikasi: ${_store?.status.toUpperCase()}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _store?.status == 'approved' ? Colors.green : Colors.orange,
            ),
          ),
          const Divider(height: 32),
          _buildTextField('Nama Toko', _nameController),
          _buildTextField('Deskripsi', _descriptionController, maxLines: 3),
          _buildTextField('Alamat Toko', _addressController, maxLines: 2),
          const SizedBox(height: 8),
          _buildCalibrationButton(),
          const SizedBox(height: 40),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous_outlined, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Zona Berbahaya',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hapus akun toko secara permanen. Tindakan ini tidak dapat dibatalkan.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[800]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showDeleteConfirmation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hapus Akun Toko', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    if (_store == null) return;
    
    final nameController = TextEditingController();
    final RxBool canDelete = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Akun Toko?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Semua data produk, pesanan, dan ulasan akan hilang permanen.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 20),
            Text('Ketik nama toko "${_store!.name}" untuk konfirmasi:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              onChanged: (val) => canDelete.value = val.trim() == _store!.name.trim(),
              decoration: InputDecoration(
                hintText: 'Nama Toko',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          Obx(() => ElevatedButton(
            onPressed: canDelete.value ? _handleDelete : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hapus Permanen'),
          )),
        ],
      ),
    );
  }

  void _handleDelete() async {
    Get.back();
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
    
    final result = await ApiService().deleteStore();
    Get.back();

    if (result['success']) {
      AppAlert.success('Toko Dihapus', result['message']);
      await AuthController.to.refreshUser();
      Get.offAllNamed('/main');
    } else {
      AppAlert.error('Gagal Menghapus', result['message'] ?? 'Terjadi kesalahan');
    }
  }

  Widget _buildCalibrationButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              initialLat: _latitude,
              initialLng: _longitude,
            ),
          ),
        );

        if (result != null) {
          setState(() {
            _latitude = result.latitude;
            _longitude = result.longitude;
          });
          if (mounted) {
            AppAlert.success('Kalibrasi', 'Lokasi peta berhasil diperbarui!');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalibrasi Alamat Map',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Text(
                    _latitude != null && _longitude != null
                        ? 'Koordinat: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                        : 'Titik peta belum ditentukan',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
