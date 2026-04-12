import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreRegistrationForm extends StatefulWidget {
  final Function(String storeName, String category) onRegister;

  const StoreRegistrationForm({super.key, required this.onRegister});

  @override
  State<StoreRegistrationForm> createState() => _StoreRegistrationFormState();
}

class _StoreRegistrationFormState extends State<StoreRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  String _storeName = '';
  String? _selectedCategory;
  final List<String> _categories = ['Kuliner', 'Fashion', 'Sembako', 'Elektronik', 'Jasa', 'Lainnya'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 64, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Buka Toko UMKM Baru',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Mulailah berbisnis di LocalMart KSB',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
            _buildLabel('Nama Toko'),
            TextFormField(
              decoration: _inputDecoration('Contoh: Bakso Taliwang Berkah'),
              validator: (v) => v == null || v.isEmpty ? 'Nama toko wajib diisi' : null,
              onSaved: (v) => _storeName = v ?? '',
            ),
            const SizedBox(height: 20),
            _buildLabel('Kategori Bisnis'),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Pilih kategori'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Pilih satu kategori' : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('Alamat Lengkap Toko'),
            TextFormField(
              maxLines: 2,
              decoration: _inputDecoration('Contoh: Jl. Raya KM 01, Taliwang'),
              validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Buka Toko Sekarang',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 120), // Tambahkan ruang agar tidak tertutup nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onRegister(_storeName, _selectedCategory!);
    }
  }
}
