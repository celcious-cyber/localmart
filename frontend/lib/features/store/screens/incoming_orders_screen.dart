import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/store_models.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Baru', 'Diproses', 'Dikirim', 'Selesai'];
  
  Map<String, List<OrderModel>> _ordersByStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    setState(() => _isLoading = true);
    final Map<String, List<OrderModel>> tempMap = {};
    
    for (var tab in _tabs) {
      tempMap[tab] = await ApiService().getStoreOrders(tab);
    }

    if (mounted) {
      setState(() {
        _ordersByStatus = tempMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(OrderModel order, String newBackendStatus) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    final result = await ApiService().updateOrderStatus(order.id, newBackendStatus);
    
    if (mounted) {
      Navigator.pop(context); // Tutup loading
      if (result['success']) {
        AppAlert.success('Update Status', result['message'] ?? 'Status pesanan berhasil diperbarui');
        _loadAllOrders(); // Refresh
      } else {
        AppAlert.error('Update Gagal', result['message'] ?? 'Terjadi kesalahan saat memperbarui status');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Pesanan Masuk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((status) => _buildOrderList(status)).toList(),
            ),
    );
  }

  Widget _buildOrderList(String status) {
    final orders = _ordersByStatus[status] ?? [];
    
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Tidak ada pesanan $status', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], status);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String displayStatus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderNumber}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.user?.firstName ?? 'Customer'} ${order.user?.lastName ?? ''}', 
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    Text(
                      order.items.map((i) => '${i.product?.name ?? 'Item'} x${i.quantity}').join(', '), 
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Pesanan', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                  Text(
                    'Rp ${order.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)
                  ),
                ],
              ),
              if (displayStatus == 'Baru')
                ElevatedButton(
                  onPressed: () => _updateStatus(order, 'processed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Terima', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else if (displayStatus == 'Diproses')
                ElevatedButton(
                  onPressed: () => _updateStatus(order, 'shipping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Kirim', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else if (displayStatus == 'Dikirim')
                ElevatedButton(
                  onPressed: () => _updateStatus(order, 'completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Selesai', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Detail', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
