import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SellingGuideScreen extends StatelessWidget {
  const SellingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Panduan Berjualan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildIntroduction(),
            const SizedBox(height: 32),
            Text(
              'Langkah-Langkah Sukses',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuideStep(
              1, 
              'Buka Toko UMKM', 
              'Masuk ke halaman Profil, klik tab "Toko", dan tekan tombol "Daftar Sekarang". Isi nama toko, deskripsi menarik, dan tentukan lokasi peta jualan Anda.',
              Icons.storefront_rounded,
              Colors.orange,
            ),
            _buildGuideStep(
              2, 
              'Upload Produk Pertama', 
              'Setelah toko aktif, pilih "Produk Saya" -> "Tambah Produk". Siapkan foto produk yang jernih, tulis nama produk yang jelas, dan tentukan harga yang kompetitif.',
              Icons.add_shopping_cart_rounded,
              Colors.blue,
            ),
            _buildGuideStep(
              3, 
              'Atur Etalase Produk', 
              'Gunakan fitur "Kelola Etalase" untuk mengelompokkan produk Anda (contoh: Makanan, Minuman, Kerajinan) agar pembeli lebih mudah mencari.',
              Icons.category_rounded,
              Colors.purple,
            ),
            _buildGuideStep(
              4, 
              'Tarik Saldo Penjualan', 
              'Hasil jualan Anda akan masuk ke Saldo Toko. Masuk ke "Statistik Performa" -> "Tarik Dana" untuk mengirimkan penghasilan Anda ke rekening bank terdaftar.',
              Icons.payments_rounded,
              Colors.green,
            ),
            const SizedBox(height: 40),
            _buildProTip(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Mulai Jualan di LocalMart',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ubah hobi atau produk UMKM Anda menjadi penghasilan tambahan bersama komunitas LocalMart KSB.',
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(int step, String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LANGKAH $step',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'PRO TIP: Gunakan foto produk dengan pencahayaan terang untuk meningkatkan penjualan hingga 40%!',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
