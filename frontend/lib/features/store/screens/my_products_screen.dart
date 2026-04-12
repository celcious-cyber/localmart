import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = [
      {
        'name': 'Kopi Tepal Original 250g',
        'price': 'Rp 45.000',
        'stock': 15,
        'sold': 42,
        'image': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=200&auto=format&fit=crop',
        'status': 'Aktif',
      },
      {
        'name': 'Madu Hutan KSB 500ml',
        'price': 'Rp 120.000',
        'stock': 5,
        'sold': 10,
        'image': 'https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?q=80&w=200&auto=format&fit=crop',
        'status': 'Stok Rendah',
      },
      {
        'name': 'Kripik Pisang Manis',
        'price': 'Rp 15.000',
        'stock': 50,
        'sold': 120,
        'image': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?q=80&w=200&auto=format&fit=crop',
        'status': 'Aktif',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Produk Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    bool isLowStock = product['stock'] <= 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              product['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product['price'],
                  style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge('Stok: ${product['stock']}', isLowStock ? Colors.red : Colors.grey[600]!),
                    const SizedBox(width: 8),
                    _buildBadge('Terjual: ${product['sold']}', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
