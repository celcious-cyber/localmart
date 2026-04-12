import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

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
                _buildMapPreview(),
                _buildAddressCard(),
                _buildSectionHeader('Pilih Kendaraan'),
                _buildVehicleSelector(),
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
            'LocalTransport',
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
          icon: const Icon(Icons.history_rounded, color: Colors.white),
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

  Widget _buildMapPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?q=80&w=600'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 40),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text('Ketuk untuk melihat peta besar', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildAddressRow(Icons.radio_button_checked_rounded, Colors.blue, 'Lokasi Penjemputan', 'Posisi Anda sekarang'),
            const Padding(
              padding: EdgeInsets.only(left: 36),
              child: Divider(height: 32),
            ),
            _buildAddressRow(Icons.location_on_rounded, Colors.orange, 'Tujuan', 'Mau pergi ke mana?'),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, Color iconColor, String label, String hint) {
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
        const Icon(Icons.search, color: Colors.grey, size: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(title, style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVehicleSelector() {
    final vehicles = [
      {'label': 'Ojek Motor', 'price': 'Rp 8.000', 'image': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&q=80&w=400', 'desc': 'Cepat & Gesit', 'isSelected': true},
      {'label': 'Mobil (4 Kursi)', 'price': 'Rp 25.000', 'image': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&q=80&w=400', 'desc': 'Nyaman Ber-AC', 'isSelected': false},
      {'label': 'Mobil (6 Kursi)', 'price': 'Rp 45.000', 'image': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=400', 'desc': 'Keluarga / Rombongan', 'isSelected': false},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final v = vehicles[index];
        final isSelected = v['isSelected'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isSelected ? AppColors.primary : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    v['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.directions_car,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['label'] as String, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(v['desc'] as String, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(v['price'] as String, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }
}
