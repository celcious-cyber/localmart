import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_alert.dart';
import '../home/home_screen.dart';
import '../auth/widgets/auth_utils.dart';
import '../auth/screens/login_screen.dart';
import '../../core/theme/app_colors.dart';
import '../store/my_store_screen.dart';
import '../store/screens/manage_etalase_screen.dart';
import '../store/screens/my_products_screen.dart';
import '../store/screens/incoming_orders_screen.dart';
import '../store/screens/store_stats_screen.dart';
import '../store/screens/store_registration_form.dart';
import '../driver/screens/driver_registration_form.dart';
import 'screens/favorites_screen.dart';
import 'screens/shipping_address_screen.dart';
import 'screens/points_screen.dart';
import 'screens/vouchers_screen.dart';
import 'screens/user_settings_screen.dart';
import '../driver/screens/driver_wallet_screen.dart';
import '../driver/screens/vehicle_settings_screen.dart';
import '../driver/screens/find_orders_screen.dart';
import '../orders/orders_screen.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/store_models.dart';
import '../../core/services/api_service.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/controllers/auth_controller.dart';

enum ProfileMode { buyer, seller, driver }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mode UI: Menggunakan Enum untuk 3 Peran
  ProfileMode currentMode = ProfileMode.buyer;
  bool isDriverOnline = false;

  // UI State for showing forms (CTA vs Form)
  bool _showSellerForm = false;
  bool _showDriverForm = false;

  // Real data for dashboard
  StoreDashboardModel? _sellerDashboard;
  bool _isDashboardLoading = false;

  // Dummy Data for Registered Profiles (Now primarily driven by _user associations)
  String registeredStoreName = '';
  String registeredDriverPlate = '';

  final authController = Get.find<AuthController>();

  UserModel? get _user => authController.user.value;
  bool get _isProfileLoading => authController.isLoading.value;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    // AuthController handles initial loading
  }

  Future<void> _loadStoreDashboard() async {
    if (_user?.store == null) return;
    
    setState(() => _isDashboardLoading = true);
    final dashboard = await ApiService().getStoreDashboard();
    if (mounted) {
      setState(() {
        _sellerDashboard = dashboard;
        _isDashboardLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    await authController.refreshUser();
    if (_user?.store != null) {
      _loadStoreDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            currentMode == ProfileMode.buyer
                ? 'Profil Saya'
                : currentMode == ProfileMode.seller
                    ? 'Toko Saya'
                    : 'Driver Dashboard',
            key: ValueKey<ProfileMode>(currentMode),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (currentMode == ProfileMode.buyer)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserSettingsScreen()));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation), child: child));
              },
              child: Column(
                key: ValueKey<String>('${currentMode.name}_${currentMode == ProfileMode.seller ? (_user?.store != null) : (_user?.driver != null)}'),
                children: [
                  if (currentMode == ProfileMode.seller && _user?.store == null) ...[
                    _showSellerForm 
                      ? StoreRegistrationForm(
                          onRegister: (name, cat) {
                            _loadUserData(); // Reload to get the new store object
                          },
                        )
                      : _buildSellerCTA()
                  ] else if (currentMode == ProfileMode.driver && _user?.driver == null) ...[
                    _showDriverForm
                      ? DriverRegistrationForm(
                          onRegister: (name, plate, type) {
                            _loadUserData(); // Reload to get the new driver object
                          },
                        )
                      : _buildDriverCTA()
                  ]
                  else if ((currentMode == ProfileMode.seller && _user?.store?.status != 'approved') || 
                           (currentMode == ProfileMode.driver && _user?.driver?.status != 'approved')) ...[
                     _buildVerificationStatus(
                       currentMode == ProfileMode.seller ? _user!.store!.status : _user!.driver!.status
                     ),
                     const SizedBox(height: 120),
                  ]
                  else ...[
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildMenuSection(),
                    const SizedBox(height: 120),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
            Obx(() => Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getModeColor().withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: _buildProfileImage(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isProfileLoading)
                        _buildLoadingPlaceholder(80, 18)
                      else
                        Row(
                          children: [
                            Text(
                              _getProfileName(),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (currentMode == ProfileMode.seller && _user?.store?.status == 'approved') ...[
                              const SizedBox(width: 8),
                              _buildTierBadge(_user!.store!.level),
                            ],
                          ],
                        ),
                      const SizedBox(height: 4),
                      if (_isProfileLoading)
                        _buildLoadingPlaceholder(120, 12)
                      else
                        Text(
                          _getProfileSubtitle(),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            )),
          if (AuthUtils.isLoggedIn) ...[
            const SizedBox(height: 24),
            // Toggle Switch Area (Triple Role)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildModeTab(ProfileMode.buyer, 'Pembeli', AppColors.primary),
                  _buildModeTab(ProfileMode.seller, 'Toko', Colors.orange),
                  _buildModeTab(ProfileMode.driver, 'Driver', Colors.indigo),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildModeTab(ProfileMode mode, String label, Color activeColor) {
    bool isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierBadge(String level) {
    if (level == 'regular') return const SizedBox.shrink();

    bool isMall = level == 'mall';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMall 
            ? [const Color(0xFF1A73E8), const Color(0xFF4285F4)] // Blue for Mall
            : [const Color(0xFFFF8C00), const Color(0xFFFFA500)], // Orange for Star
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: (isMall ? Colors.blue : Colors.orange).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMall ? Icons.verified_rounded : Icons.stars_rounded, 
            color: Colors.white, 
            size: 10
          ),
          const SizedBox(width: 4),
          Text(
            isMall ? 'Mall' : 'Star',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor() {
    switch (currentMode) {
      case ProfileMode.seller:
        return Colors.orange;
      case ProfileMode.driver:
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildLoadingPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildProfileImage() {
    String? imageUrl;
    if (currentMode == ProfileMode.seller) {
      imageUrl = _user?.store?.imageUrl;
    } else {
      imageUrl = _user?.avatarUrl;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(
        _getModeIcon(),
        size: 40,
        color: _getModeColor(),
      );
    }

    return CachedNetworkImage(
      imageUrl: ApiService().getImageUrl(imageUrl),
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Icon(
        _getModeIcon(),
        size: 40,
        color: _getModeColor(),
      ),
    );
  }

  IconData _getModeIcon() {
    switch (currentMode) {
      case ProfileMode.seller: return Icons.storefront;
      case ProfileMode.driver: return Icons.motorcycle;
      default: return Icons.person;
    }
  }

  String _getProfileName() {
    if (!AuthUtils.isLoggedIn) return 'Silakan Masuk';
    switch (currentMode) {
      case ProfileMode.seller:
        return _user?.store?.name ?? 'Mulai Berjualan';
      case ProfileMode.driver:
        return _user?.driver != null ? 'Mitra Driver LocalMart' : 'Gabung Mitra Driver';
      default:
        return _user?.fullName ?? 'Memuat...';
    }
  }

  String _getProfileSubtitle() {
    if (!AuthUtils.isLoggedIn) return 'Silakan masuk untuk akses penuh';
    switch (currentMode) {
      case ProfileMode.seller:
        if (_user?.store == null) return 'Belum Terdaftar';
        String statusText = _user!.store!.status == 'pending' ? ' (Menunggu Verifikasi)' : (_user!.store!.status == 'rejected' ? ' (Pendaftaran Ditolak)' : '');
        return '@${_user!.store!.name.toLowerCase().replaceAll(' ', '')}$statusText';
      case ProfileMode.driver:
        if (_user?.driver == null) return 'Belum Terdaftar';
        String statusText = _user!.driver!.status == 'pending' ? ' (Menunggu Verifikasi)' : (_user!.driver!.status == 'rejected' ? ' (Pendaftaran Ditolak)' : '');
        return '${_user!.driver!.plateNumber}$statusText';
      default:
        return _user?.phone ?? 'Belum ada nomor HP';
    }
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: currentMode == ProfileMode.driver
          ? Row(
              children: [
                _buildStatItem('Saldo Driver', 'Rp 750K', Icons.account_balance_wallet, Colors.indigo),
                const SizedBox(width: 15),
                _buildStatItem('Rating', '4.9', Icons.star, Colors.indigo),
              ],
            )
          : currentMode == ProfileMode.seller
              ? Row(
                  children: [
                    _buildStatItem(
                      'Saldo Toko', 
                      _isDashboardLoading 
                        ? '...' 
                        : _sellerDashboard != null 
                            ? 'Rp ${_sellerDashboard!.balance.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}'
                            : 'Rp 0', 
                      Icons.account_balance_wallet, 
                      Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreStatsScreen())).then((_) => _loadStoreDashboard()),
                    ),
                    const SizedBox(width: 15),
                    _buildStatItem(
                      'Total Terjual', 
                      _isDashboardLoading 
                        ? '...' 
                        : _sellerDashboard != null 
                            ? '${_sellerDashboard!.totalOrders} Item'
                            : '0 Item', 
                      Icons.trending_up_rounded, 
                      Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreStatsScreen())).then((_) => _loadStoreDashboard()),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildStatItem(
                      'Local Point',
                      _isProfileLoading 
                        ? '...' 
                        : (_user?.points.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.") ?? '0'),
                      Icons.stars_outlined,
                      AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointsScreen())).then((_) => _loadUserData()),
                    ),
                    const SizedBox(width: 15),
                    _buildStatItem(
                      'Voucher',
                      '8 Aktif',
                      Icons.confirmation_number_outlined,
                      AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VouchersScreen())),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keluar Aplikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar dari sesi ini?', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              
              await ApiService().logout();
              AuthUtils.isLoggedIn = false; // Reset state guest
              
              if (mounted) {
                navigator.pop(); // Tutup dialog
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()), // Kembali ke HomeScreen
                );
                AppAlert.success('Logout', 'Anda telah berhasil keluar dari aplikasi.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Keluar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        AppAlert.error('Gagal Membuka', 'Gagal membuka halaman: $urlString');
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: currentMode == ProfileMode.driver
              ? _buildDriverMenuList()
              : currentMode == ProfileMode.seller
                  ? _buildSellerMenuList()
                  : _buildBuyerMenuList(),
        ),
      ),
    );
  }

  List<Widget> _buildBuyerMenuList() {
    return [
      _buildSectionHeader('Aktivitas Saya'),
      _buildMenuItem(Icons.shopping_bag_outlined, 'Pesanan Saya', 'Status pesanan belanjaan Anda', AppColors.primary, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
      }),
      _buildMenuItem(Icons.favorite_border, 'Favorit', 'Produk UMKM tersimpan', Colors.pink, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
      }),
      _buildMenuItem(Icons.location_on_outlined, 'Alamat Pengiriman', 'Tempat tinggal atau kost Anda', Colors.green, isLast: true, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShippingAddressScreen()));
      }),

      _buildSectionHeader('Pusat Bantuan & Info'),
      _buildMenuItem(Icons.headset_mic_outlined, 'Bantuan Center', 'Pusat bantuan pelanggan', Colors.purple, onTapCallback: () {
        Get.toNamed('/help-center');
      }),
      _buildMenuItem(Icons.info_outline_rounded, 'Tentang LocalMart', 'Kenali lebih dekat platform kami', Colors.blue, onTapCallback: () => _launchUrl('https://localmart.id/tentang')),
      _buildMenuItem(Icons.description_outlined, 'Syarat & Ketentuan', 'Aturan penggunaan layanan', Colors.orange, onTapCallback: () => _launchUrl('https://localmart.id/snk')),
      _buildMenuItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi', 'Bagaimana kami menjaga data Anda', Colors.teal, onTapCallback: () => _launchUrl('https://localmart.id/privacy')),
      _buildMenuItem(Icons.share_outlined, 'Ajak Teman', 'Bagikan keseruan belanja LocalMart', Colors.indigo, isLast: true, onTapCallback: () {
        AppAlert.info('Segera Hadir', 'Fitur referral akan segera tersedia!');
      }),

      _buildSectionHeader('Pengaturan Akun'),
      _buildMenuItem(Icons.security_outlined, 'Keamanan Akun', 'Password, PIN & Verifikasi', Colors.blueGrey, onTapCallback: () {
        AppAlert.info('Segera Hadir', 'Menu keamanan akan segera tersedia!');
      }),
      if (AuthUtils.isLoggedIn)
        _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi belanja', Colors.red, isLast: true, onTapCallback: _handleLogout)
      else
        _buildMenuItem(Icons.login, 'Masuk / Daftar', 'Mulai nikmati fitur penuh', Colors.green, isLast: true, onTapCallback: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())).then((val) {
            if (val == true) {
              _loadUserData();
            }
          });
        }),
    ];
  }

  List<Widget> _buildSellerMenuList() {
    return [
      _buildSectionHeader('Kelola Toko'),
      _buildMenuItem(Icons.inventory_2_outlined, 'Produk Saya', 'Kelola barang jualan Anda', Colors.orange, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProductsScreen()));
      }),
      _buildMenuItem(Icons.category_outlined, 'Kelola Etalase', 'Atur kategori koleksi produk Anda', Colors.deepPurple, onTapCallback: () {
        final storeId = _user?.store?.id;
        if (storeId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageEtalaseScreen(storeId: storeId)));
        } else {
          AppAlert.error('Error', 'Toko tidak ditemukan');
        }
      }),
      _buildMenuItem(Icons.list_alt_rounded, 'Pesanan Masuk', 'Proses pesanan dari pembeli', Colors.blue, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const IncomingOrdersScreen()));
      }),
      _buildMenuItem(Icons.analytics_outlined, 'Statistik Performa', 'Pantau kemajuan penjualan', Colors.teal, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreStatsScreen()));
      }),
      _buildMenuItem(Icons.storefront_outlined, 'Pengaturan Toko', 'Ubah profil dan jam operasional', Colors.indigo, isLast: true, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyStoreScreen())).then((val) {
          if (val == true) {
            _loadStoreDashboard();
            _loadUserData();
          }
        });
      }),

      _buildSectionHeader('Pusat Bantuan & Info'),
      _buildMenuItem(Icons.headset_mic_outlined, 'Bantuan Center', 'Pusat bantuan penjual', Colors.purple, onTapCallback: () {
        Get.toNamed('/help-center');
      }),
      _buildMenuItem(Icons.info_outline_rounded, 'Panduan Berjualan', 'Tips jualan laris di LocalMart', Colors.blue, isLast: true, onTapCallback: () {
        Get.toNamed('/selling-guide');
      }),

      _buildSectionHeader('Pengaturan Akun'),
      _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi jualan', Colors.red, isLast: true, onTapCallback: _handleLogout),
    ];
  }

  List<Widget> _buildDriverMenuList() {
    return [
      _buildSectionHeader('Status & Order'),
      _buildMenuItem(
        Icons.power_settings_new,
        isDriverOnline ? 'Status: Online' : 'Status: Offline',
        isDriverOnline ? 'Siap menerima pesanan pengantaran' : 'Tutup sementara',
        isDriverOnline ? Colors.green : Colors.grey,
        onTapCallback: () => setState(() => isDriverOnline = !isDriverOnline),
        trailingWidget: Switch(
          value: isDriverOnline,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.green.withValues(alpha: 0.3),
          onChanged: (v) => setState(() => isDriverOnline = v),
        ),
      ),
      _buildMenuItem(Icons.directions_run_outlined, 'Pesanan Pengantaran', 'Daftar orderan kurir/ojek', Colors.indigo, isLast: true, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FindOrdersScreen()));
      }),

      _buildSectionHeader('Kelola Kendaraan'),
      _buildMenuItem(Icons.account_balance_wallet_outlined, 'Dompet Pendapatan', 'Cek dan tarik saldo penghasilan', Colors.blueGrey, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverWalletScreen()));
      }),
      _buildMenuItem(Icons.motorcycle_outlined, 'Info Kendaraan', 'Atur detail plat dan jenis motor', Colors.teal, isLast: true, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleSettingsScreen()));
      }),

      _buildSectionHeader('Pengaturan Akun'),
      _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi driver', Colors.red, isLast: true, onTapCallback: _handleLogout),
    ];
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color, {bool isLast = false, VoidCallback? onTapCallback, Widget? trailingWidget}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
          trailing: trailingWidget ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          onTap: onTapCallback ??
              () {
                AppAlert.info('Segera Hadir', 'Menu $title akan segera tersedia!');
              },
        ),
        if (!isLast) Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey[100]),
      ],
    );
  }

  Widget _buildSellerCTA() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 60, color: Colors.orange),
          ),
          const SizedBox(height: 24),
          Text(
            'Mulai Jualan di LocalMart',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ubah hobi atau produk UMKM Anda menjadi penghasilan tambahan. Jangkau ribuan pelanggan di Sumbawa Barat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showSellerForm = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Buka Toko Sekarang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCTA() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.motorcycle_rounded, size: 60, color: Colors.indigo),
          ),
          const SizedBox(height: 24),
          Text(
            'Gabung Jadi Driver LocalSend',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dapatkan penghasilan fleksibel dengan mengantar pesanan atau menjadi kurir paket di Kabupaten Sumbawa Barat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showDriverForm = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Daftar Driver Sekarang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '*Proses verifikasi 1-3 hari kerja',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(String status) {
    bool isPending = status == 'pending';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isPending ? Colors.orange : Colors.red).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isPending ? Colors.orange : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? Icons.hourglass_empty_rounded : Icons.gpp_bad_rounded, 
              size: 60, 
              color: isPending ? Colors.orange : Colors.red
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPending ? 'Sedang Diverifikasi' : 'Pendaftaran Ditolak',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPending 
              ? 'Terima kasih sudah mendaftar! Admin kami sedang meninjau profil Anda. Proses ini biasanya memakan waktu 1-3 hari kerja.'
              : 'Mohon maaf, pendaftaran Anda belum disetujui oleh tim kami. Silakan hubungi bantuan untuk informasi lebih lanjut.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          if (!isPending) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                    AppAlert.info('Hubungi CS', 'Silakan hubungi Customer Service untuk pendaftaran ulang.');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Hubungi Bantuan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

