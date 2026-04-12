import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingSection('Akun Saya', [
              _buildSettingItem(Icons.person_outline, 'Edit Profil', 'Nama, foto, dan bio'),
              _buildSettingItem(Icons.phone_android, 'No. Handphone', '+62 812 *** *** 90'),
              _buildSettingItem(Icons.mail_outline, 'Email', 'muhammad.akmal@example.com'),
            ]),
            _buildSettingSection('Keamanan', [
              _buildSettingItem(Icons.lock_outline, 'Ubah Password', 'Update keamanan akun'),
              _buildSettingItem(Icons.fingerprint, 'Biometrik / PIN', 'Keamanan akses aplikasi'),
            ]),
            _buildSettingSection('Aplikasi', [
              _buildSettingItem(Icons.language, 'Bahasa', 'Indonesia'),
              _buildSettingItem(Icons.notifications_none, 'Notifikasi', 'Pengaturan pesan masuk'),
              _buildSettingItem(Icons.dark_mode_outlined, 'Mode Gelap', 'Sistem Default'),
            ]),
            _buildSettingSection('Informasi', [
              _buildSettingItem(Icons.info_outline, 'Tentang LocalMart', 'Versi 1.0.2'),
              _buildSettingItem(Icons.description_outlined, 'Syarat & Ketentuan', 'Kepatuhan pengguna'),
              _buildSettingItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi', 'Keamanan data Anda'),
            ]),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildDangerButton('Hapus Akun', Icons.delete_forever_outlined),
                  const SizedBox(height: 12),
                  _buildLogoutButton(context),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildDangerButton(String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          label,
          style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.black87),
        title: Text(
          'Keluar',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
