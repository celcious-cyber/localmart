import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            'Pesanan Saya',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Dikirim'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(statusFilter: 'all'),
            _OrdersList(statusFilter: 'shipping'),
            _OrdersList(statusFilter: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String statusFilter;
  const _OrdersList({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyOrders = [
      {
        'id': 'LM-12001',
        'title': 'Kopi Tepal Original',
        'price': 'Rp 85.000',
        'status': 'Dikirim',
        'image':
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&q=80&w=400',
        'isCompleted': false,
      },
      {
        'id': 'LM-11985',
        'title': 'Madu Sumbawa Murni',
        'price': 'Rp 120.000',
        'status': 'Selesai',
        'image':
            'https://images.unsplash.com/photo-1663963603322-d51827492f69?auto=format&fit=crop&q=80&w=400',
        'isCompleted': true,
      },
      {
        'id': 'LM-11977',
        'title': 'Keripik Jagung KSB',
        'price': 'Rp 15.000',
        'status': 'Selesai',
        'image':
            'https://images.unsplash.com/photo-1699666397768-0126340e880a?q=80&w=688&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        'isCompleted': true,
      },
    ];

    final filteredOrders = statusFilter == 'all'
        ? dummyOrders
        : dummyOrders
              .where(
                (o) => statusFilter == 'shipping'
                    ? !o['isCompleted']
                    : o['isCompleted'],
              )
              .toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesanan',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      order['image'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['id'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          order['price'],
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order['isCompleted']
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order['status'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: order['isCompleted']
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!order['isCompleted'])
                    _buildActionButton('Lacak Paket', Colors.grey[700]!, false)
                  else
                    _buildActionButton('Beli Lagi', AppColors.primary, false),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    order['isCompleted'] ? 'Beri Nilai' : 'Hubungi Penjual',
                    AppColors.primary,
                    true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, Color color, bool isFilled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFilled ? color : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isFilled ? Colors.white : color,
        ),
      ),
    );
  }
}
