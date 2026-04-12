import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            isScrollable: true,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Pesanan Baru'),
              Tab(text: 'Diproses'),
              Tab(text: 'Dikirim'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList('Baru'),
            _buildOrderList('Diproses'),
            _buildOrderList('Dikirim'),
            _buildOrderList('Selesai'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    // Dummy Data Based on Status
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildOrderCard(status);
      },
    );
  }

  Widget _buildOrderCard(String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#LM-990$status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
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
                    Text('Muhammad Akmal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Kopi Tepal Original x2', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
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
                  Text('Rp 90.000', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                ],
              ),
              if (status == 'Baru')
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Terima', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
