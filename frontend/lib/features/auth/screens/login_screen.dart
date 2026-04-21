import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/api_service.dart';
import '../widgets/auth_utils.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = true;

  // Exact Colors from reference
  final Color _primaryTeal = const Color(0xFF00796B);
  final Color _tealText = const Color(0xFF006765);
  final Color _lightGreyField = const Color(0xFFE5E5E5);

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          AuthUtils.isLoggedIn = true;
          AppAlert.success(
            'Berhasil',
            'Selamat datang kembali, ${result['user'].fullName}',
          );
          Navigator.pop(context, true);
        } else {
          AppAlert.error(
            'Gagal Masuk',
            result['message'] ?? 'Periksa data Anda',
          );
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
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center all content
                          children: [
                            const SizedBox(
                              height: 80,
                            ), // Added 20px shift as requested
                            // Logo Section
                            _buildHeaderLogo(),
                            const SizedBox(height: 24), // Condensed
                            // The "Rising Card"
                            _buildLoginCard(),

                            // Bottom Link & Copyright
                            const Spacer(), // Pushes footer to bottom or balances it
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
          height: 320, // Slightly more compact header height
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
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo/localmart1.png',
          height: 85, // Compacted
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.shopping_cart_rounded,
            size: 85,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ), // Condensed vertical
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
                    'Selamat datang di Localmart,',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _tealText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Silakan login untuk melanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _tealText.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), // Condensed

            _buildLabel('Email'),
            _buildFormTextField(
              controller: _emailController,
              hint: 'Masukkan email anda',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16), // Condensed

            _buildLabel('Kata Sandi'),
            _buildFormTextField(
              controller: _passwordController,
              hint: '*************',
              icon: Icons.vpn_key_outlined,
              isPassword: true,
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v!),
                        activeColor: _primaryTeal,
                        side: BorderSide(color: _primaryTeal, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ingat saya',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _tealText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Lupa Sandi?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                            'Masuk Sekarang',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Condensed

            Row(
              children: [
                Expanded(
                  child: Divider(color: _primaryTeal.withValues(alpha: 0.2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'atau',
                    style: GoogleFonts.poppins(
                      color: _tealText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: _primaryTeal.withValues(alpha: 0.2)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _buildSocialIcon(
                  child: const Icon(
                    Icons.facebook,
                    color: Color(0xFF1877F2),
                    size: 32,
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Login dengan akun google atau facebook anda',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _tealText,
                  fontWeight: FontWeight.w600,
                ),
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
              'Belum punya akun? ',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _tealText.withValues(alpha: 0.7),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
              child: Text(
                'Daftar Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20), // Condensed footer space
        Text(
          '© 2026 LocalMart KSB. All Rights Reserved',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _tealText.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black38, size: 22),
        filled: true,
        fillColor: _lightGreyField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Wajib diisi' : null,
    );
  }

  Widget _buildSocialIcon({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48, // Compacted
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
