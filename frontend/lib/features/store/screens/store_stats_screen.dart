import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/store_models.dart';

class StoreStatsScreen extends StatefulWidget {
  const StoreStatsScreen({super.key});

  @override
  State<StoreStatsScreen> createState() => _StoreStatsScreenState();
}

class _StoreStatsScreenState extends State<StoreStatsScreen> {
  StoreDashboardModel? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getStoreDashboard();
    if (mounted) {
      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _dashboard == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: Colors.orange,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRevenueCard(),
                        const SizedBox(height: 32),
                        _buildGridStats(),
                        if (_dashboard!.topProducts.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'Produk Terlaris Anda',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ..._dashboard!.topProducts.map((p) => _buildTopProduct(
                            p.name, 
                            '${p.sold} Terjual', 
                            _formatCurrency(p.price * p.sold), 
                            Colors.orange
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Gagal memuat data statistik', style: GoogleFonts.poppins(color: Colors.grey)),
          TextButton(onPressed: _loadDashboard, child: const Text('Coba Lagi', style: TextStyle(color: Colors.orange))),
        ],
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
          BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Toko (Bisa Ditarik)',
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_dashboard!.balance),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Penjualan: ${_formatCurrency(_dashboard!.totalSales)}',
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
        _statBox('Pesanan Diproses', _dashboard!.pendingOrders.toString(), Icons.pending_actions_outlined, Colors.blue),
        const SizedBox(width: 16),
        _statBox('Total Pesanan', _dashboard!.totalOrders.toString(), Icons.shopping_bag_outlined, Colors.green),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
