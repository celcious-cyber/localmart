import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreStatsScreen extends StatelessWidget {
  const StoreStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Statistik Toko',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueCard(),
            const SizedBox(height: 32),
            _buildGridStats(),
            const SizedBox(height: 32),
            Text(
              'Produk Terlaris Anda',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildTopProduct('Kopi Tepal Original', '142 Terjual', 'Rp 6.3M', Colors.orange),
            _buildTopProduct('Madu Hutan KSB', '89 Terjual', 'Rp 10.6M', Colors.amber),
            _buildTopProduct('Kripik Pisang', '76 Terjual', 'Rp 1.1M', Colors.yellow[700]!),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pendapatan (Bulan Ini)',
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp 12.450.000',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '+15% dari bulan lalu',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridStats() {
    return Row(
      children: [
        _statBox('Pengunjung', '1.2K', Icons.visibility_outlined, Colors.blue),
        const SizedBox(width: 16),
        _statBox('Pesanan', '245', Icons.shopping_bag_outlined, Colors.green),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProduct(String name, String sold, String revenue, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.star, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sold, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            revenue,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }
}
