import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';

class DriverRegistrationForm extends StatefulWidget {
  final Function(String driverName, String plateNumber, String vehicleType) onRegister;

  const DriverRegistrationForm({super.key, required this.onRegister});

  @override
  State<DriverRegistrationForm> createState() => _DriverRegistrationFormState();
}

class _DriverRegistrationFormState extends State<DriverRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _plateNumber = '';
  String _waNumber = '';
  String? _selectedVehicleType;
  final List<String> _vehicleTypes = ['Sepeda Motor (Standard)', 'Motor Listrik', 'Mobil (4 Kursi)', 'Mobil (6 Kursi)'];

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
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining_rounded, size: 64, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Daftar Mitra Driver',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Bergabunglah dengan armada LocalMart KSB',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
            _buildLabel('Nama Lengkap Sesuai KTP'),
            TextFormField(
              decoration: _inputDecoration('Contoh: Ahmad Maulana'),
              validator: (v) => v == null || v.isEmpty ? 'Nama lengkap wajib diisi' : null,
              onSaved: (v) => _fullName = v ?? '',
            ),
            const SizedBox(height: 20),
            _buildLabel('Jenis Kendaraan'),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Pilih jenis kendaraan'),
              items: _vehicleTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _selectedVehicleType = v),
              validator: (v) => v == null ? 'Pilih jenis kendaraan' : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('Nomor Plat Kendaraan (Nopol)'),
            TextFormField(
              decoration: _inputDecoration('Contoh: EA 1234 XY'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v == null || v.isEmpty ? 'Nomor plat wajib diisi' : null,
              onSaved: (v) => _plateNumber = v ?? '',
            ),
            const SizedBox(height: 20),
            _buildLabel('Nomor WhatsApp Aktif'),
            TextFormField(
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Contoh: 081234567XXX'),
              validator: (v) => v == null || v.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
              onSaved: (v) => _waNumber = v ?? '',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Daftar Jadi Mitra Sekarang',
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
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );

      final result = await ApiService().registerDriver(
        vehicleType: _selectedVehicleType!,
        plateNumber: _plateNumber,
        phoneNumber: _waNumber,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup loading

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
          );
          widget.onRegister(_fullName, _plateNumber, _selectedVehicleType!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
