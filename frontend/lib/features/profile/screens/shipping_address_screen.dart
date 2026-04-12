import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ShippingAddressScreen extends StatelessWidget {
  const ShippingAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> addresses = [
      {
        'label': 'Rumah Utama',
        'receiver': 'Muhammad Akmal',
        'phone': '081234567890',
        'address': 'Jl. Bung Karno Komplek KTC Taliwang, Kab. Sumbawa Barat, Nusa Tenggara Barat',
        'isDefault': true,
      },
      {
        'label': 'Kost Taliwang',
        'receiver': 'Akmal',
        'phone': '081234567890',
        'address': 'Jl. Udara No. 12, Kelurahan Menala, Taliwang, KSB',
        'isDefault': false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Alamat Pengiriman',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final addr = addresses[index];
          return _buildAddressCard(addr);
        },
      ),
      bottomNavigationBar: _buildAddAddressButton(context),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: addr['isDefault'] 
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                addr['label'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: addr['isDefault'] ? AppColors.primary : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              if (addr['isDefault'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Utama',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            addr['receiver'],
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            addr['phone'],
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            addr['address'],
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur Tambah Alamat segera hadir!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: Text(
            'Tambah Alamat Baru',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
