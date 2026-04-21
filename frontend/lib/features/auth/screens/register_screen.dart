import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Design Tokens (Matching login_screen.dart)
  final Color _primaryTeal = const Color(0xFF00796B);
  final Color _tealText = const Color(0xFF006765);
  final Color _lightGreyField = const Color(0xFFE5E5E5);

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await ApiService().register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          AppAlert.success('Berhasil', 'Pendaftaran berhasil! Silakan masuk.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          AppAlert.error('Gagal Daftar', result['message'] ?? 'Periksa kembali data Anda');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Stack(
        children: [
          // 1. Two-Tone Background
          _buildBackground(),

          // 2. Adaptive Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40), // Shifted down to match login aesthetic
                            _buildHeaderLogo(),
                            const SizedBox(height: 24),
                            _buildRegisterCard(),
                            const Spacer(),
                            _buildFooter(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Floating Back Button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Column(
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF009688), // Slightly lighter teal
                Color(0xFF00796B), // Primary teal
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(60),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Expanded(child: Container(color: const Color(0xFFE5E5E5))),
      ],
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 20,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo/localmart1.png',
          height: 80,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.shopping_cart_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Buat Akun Baru',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _tealText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lengkapi data untuk mulai belanja',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _tealText.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama Depan'),
                      _buildFormTextField(
                        controller: _firstNameController,
                        hint: 'Budi',
                        icon: Icons.person_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama Belakang'),
                      _buildFormTextField(
                        controller: _lastNameController,
                        hint: 'Santoso',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Email'),
            _buildFormTextField(
              controller: _emailController,
              hint: 'Email aktif anda',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),

            _buildLabel('Nomor Handphone'),
            _buildFormTextField(
              controller: _phoneController,
              hint: '0812xxxxxxxx (opsional)',
              icon: Icons.phone_android_outlined,
            ),
            const SizedBox(height: 16),

            _buildLabel('Kata Sandi'),
            _buildFormTextField(
              controller: _passwordController,
              hint: '*************',
              icon: Icons.vpn_key_outlined,
              isPassword: true,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00796B), Color(0xFF004D40)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Daftar Sekarang',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Added divider and socials

            Row(
              children: [
                Expanded(child: Divider(color: _primaryTeal.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('atau', style: GoogleFonts.poppins(color: _tealText, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(child: Divider(color: _primaryTeal.withValues(alpha: 0.2))),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  child: const Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _buildSocialIcon(
                  child: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 32),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Daftar dengan akun google atau facebook anda',
                style: GoogleFonts.poppins(fontSize: 12, color: _tealText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Sudah punya akun? ',
              style: GoogleFonts.poppins(fontSize: 14, color: _tealText.withValues(alpha: 0.7)),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Masuk Sekarang',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryTeal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '© 2026 LocalMart KSB. All Rights Reserved',
          style: GoogleFonts.poppins(fontSize: 12, color: _tealText.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: _tealText),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.black38, size: 20) : null,
        filled: true,
        fillColor: _lightGreyField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.black38, size: 20),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
    );
  }

  Widget _buildSocialIcon({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
