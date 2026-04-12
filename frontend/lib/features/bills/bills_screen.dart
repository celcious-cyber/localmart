import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

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
                _buildPromoCard(),
                _buildServiceGrid(),
                _buildSectionHeader('Transaksi Terakhir'),
                _buildRecentOrders(),
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
            'LocalBills',
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

  Widget _buildPromoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bayar Tagihan Lebih Hemat!',
                    style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diskon hingga Rp 25.000 untuk pembayaran pertama PDAM.',
                    style: GoogleFonts.manrope(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      {'label': 'Listrik PLN', 'icon': Icons.bolt, 'color': Colors.amber},
      {'label': 'PDAM', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'label': 'Pulsa & Data', 'icon': Icons.phone_android, 'color': Colors.green},
      {'label': 'Internet', 'icon': Icons.wifi, 'color': Colors.purple},
      {'label': 'BPJS', 'icon': Icons.health_and_safety, 'color': Colors.red},
      {'label': 'TV Kabel', 'icon': Icons.tv, 'color': Colors.orange},
      {'label': 'PBB', 'icon': Icons.home, 'color': Colors.brown},
      {'label': 'Lainnya', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          return Column(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (s['color'] as Color).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(s['icon'] as IconData, color: s['color'] as Color),
              ),
              const SizedBox(height: 8),
              Text(
                s['label'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(
        title,
        style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final history = [
      {'title': 'Sedo Pulsa 50k', 'date': '10 Apr 2024', 'amount': 'Rp 51.500', 'status': 'Selesai'},
      {'title': 'PLN Token', 'date': '08 Apr 2024', 'amount': 'Rp 102.500', 'status': 'Selesai'},
      {'title': 'PDAM KSB', 'date': '05 Apr 2024', 'amount': 'Rp 45.000', 'status': 'Selesai'},
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(item['date']!, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['amount']!, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(item['status']!, style: GoogleFonts.manrope(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
