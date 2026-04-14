import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class RentalScreen extends StatelessWidget {
  const RentalScreen({super.key});

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
                _buildSearchBar(),
                _buildVehicleFilters(),
                _buildSectionHeader('Kendaraan Tersedia'),
                _buildRentalList(),
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
      expandedHeight: 130,
      toolbarHeight: 70,
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
            'LocalRental',
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
                  color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cari mobil, motor, atau bus...',
            hintStyle: GoogleFonts.manrope(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleFilters() {
    final filters = [
      {'label': 'Semua', 'icon': Icons.grid_view},
      {'label': 'Mobil', 'icon': Icons.directions_car},
      {'label': 'Motor', 'icon': Icons.directions_bike},
      {'label': 'Truck', 'icon': Icons.local_shipping},
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(filters[index]['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    filters[index]['label'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Text(
        title,
        style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRentalList() {
    final rentals = [
      {'name': 'Avanza Veloz 2023', 'type': 'Mobil', 'price': 'Rp 350.000', 'specs': '7 Seat • Manual', 'distance': '1.5 km', 'rating': '4.9', 'img': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=500'},
      {'name': 'Honda Vario 160', 'type': 'Motor', 'price': 'Rp 80.000', 'specs': 'Matic • 2022', 'distance': '0.5 km', 'rating': '4.8', 'img': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=500'},
      {'name': 'Innova Reborn', 'type': 'Mobil', 'price': 'Rp 600.000', 'specs': '7 Seat • Matic', 'distance': '2.1 km', 'rating': '5.0', 'img': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?q=80&w=500'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final r = rentals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(r['img']!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['name']!, style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(r['rating']!, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(r['distance']!, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(width: 8),
                            Text(r['specs']!, style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: r['price']!, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              TextSpan(text: ' / hari', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Sewa Sekarang', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
