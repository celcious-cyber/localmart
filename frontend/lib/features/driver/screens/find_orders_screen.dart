import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class FindOrdersScreen extends StatefulWidget {
  const FindOrdersScreen({super.key});

  @override
  State<FindOrdersScreen> createState() => _FindOrdersScreenState();
}

class _FindOrdersScreenState extends State<FindOrdersScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final List<Map<String, dynamic>> availableOrders = [
    {
      'type': 'LocalSend',
      'title': 'Antar Paket UMKM',
      'pickup': 'Toko Berkah, Taliwang',
      'drop': 'Jl. Sudirman No. 12',
      'price': 'Rp 15.000',
      'distance': '2.5 km',
      'icon': Icons.inventory_2_outlined,
      'color': Colors.orange,
    },
    {
      'type': 'LocalTransport',
      'title': 'Ojek Penumpang',
      'pickup': 'Pasar Taliwang',
      'drop': 'KTC (Kemutar Telu Center)',
      'price': 'Rp 10.000',
      'distance': '1.8 km',
      'icon': Icons.directions_bike,
      'color': Colors.indigo,
    },
    {
      'type': 'LocalSend',
      'title': 'Beli & Antar (Food)',
      'pickup': 'Kopi Tepal, KSB',
      'drop': 'Kantor Bupati KSB',
      'price': 'Rp 12.000',
      'distance': '3.2 km',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Cari Orderan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildRadarHeader(),
          _buildStatsSummary(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarHeader() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Animation
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildPulseCircle(100 * _radarController.value, 1.0 - _radarController.value),
                  _buildPulseCircle(200 * _radarController.value, 1.0 - _radarController.value),
                ],
              );
            },
          ),
          // Center Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.indigo.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 32),
          ),
          Positioned(
            bottom: 20,
            child: Text(
              'Mencari pesanan di sekitarmu...',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCircle(double radius, double opacity) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.indigo.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSmallStat('Rp 750K', 'Saldo'),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildSmallStat('4.9', 'Rating'),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildSmallStat('12', 'Selesai'),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: availableOrders.length,
      itemBuilder: (context, index) {
        final order = availableOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: order['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(order['icon'], color: order['color'], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['type'], style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: order['color'])),
                    Text(order['title'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(order['price'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dari: ${order['pickup']}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ke: ${order['drop']}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(order['distance'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(
                'Ambil Pesanan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
