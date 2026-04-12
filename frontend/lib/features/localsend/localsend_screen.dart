import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class LocalSendScreen extends StatelessWidget {
  const LocalSendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceSelector(),
                _buildAddressInputs(),
                _buildSectionHeader('Pesanan Baru-baru Ini'),
                _buildRecentDeliveries(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LocalSend',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Text(
                'Taliwang, KSB',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    final services = [
      {'label': 'Instan', 'desc': '1-2 Jam', 'icon': Icons.bolt, 'isSelected': true},
      {'label': 'Sameday', 'desc': '6-8 Jam', 'icon': Icons.access_time_rounded, 'isSelected': false},
      {'label': 'Cargo', 'icon': Icons.inventory_2_outlined, 'desc': 'Besar/Berat', 'isSelected': false},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: services.map((s) {
          final isSelected = s['isSelected'] as bool;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['desc'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressInputs() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            _buildAddressField(Icons.location_on_rounded, Colors.orange, 'Lokasi Penjemputan', 'Mau jemput di mana?'),
            const Padding(
              padding: EdgeInsets.only(left: 36),
              child: Divider(height: 32),
            ),
            _buildAddressField(Icons.radio_button_checked_rounded, AppColors.primary, 'Lokasi Tujuan', 'Kirim ke mana?'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text('Lanjut ke Detail Paket', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField(IconData icon, Color iconColor, String label, String hint) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(hint, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(title, style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRecentDeliveries() {
    final history = [
      {'title': 'Kiriman Dokumen', 'to': 'Kantor Bupati KSB', 'status': 'Dalam Pengiriman'},
      {'title': 'Paket Oleh-oleh', 'to': 'Terminal Poto Tano', 'status': 'Selesai'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_post_office_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Tujuan: ${item['to']!}', style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(item['status']!, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
    );
  }
}
