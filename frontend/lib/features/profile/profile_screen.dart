import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../store/my_store_screen.dart';
import '../store/screens/my_products_screen.dart';
import '../store/screens/incoming_orders_screen.dart';
import '../store/screens/store_stats_screen.dart';
import '../store/screens/store_registration_form.dart';
import '../driver/screens/driver_registration_form.dart';
import 'screens/favorites_screen.dart';
import 'screens/shipping_address_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/points_screen.dart';
import 'screens/vouchers_screen.dart';
import 'screens/user_settings_screen.dart';
import '../driver/screens/driver_wallet_screen.dart';
import '../driver/screens/vehicle_settings_screen.dart';
import '../driver/screens/find_orders_screen.dart';
import '../orders/orders_screen.dart';

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

  // Registration Flags
  bool isSellerRegistered = false;
  bool isDriverRegistered = false;

  // Dummy Data for Registered Profiles
  String registeredStoreName = 'Toko Berkah';
  String registeredDriverPlate = 'EA 1234 XY';

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
                key: ValueKey<String>('${currentMode.name}_${currentMode == ProfileMode.seller ? isSellerRegistered : isDriverRegistered}'),
                children: [
                  if (currentMode == ProfileMode.seller && !isSellerRegistered)
                    StoreRegistrationForm(
                      onRegister: (name, cat) {
                        setState(() {
                          registeredStoreName = name;
                          isSellerRegistered = true;
                        });
                      },
                    )
                  else if (currentMode == ProfileMode.driver && !isDriverRegistered)
                    DriverRegistrationForm(
                      onRegister: (name, plate, type) {
                        setState(() {
                          registeredDriverPlate = plate;
                          isDriverRegistered = true;
                        });
                      },
                    )
                  else ...[
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildMenuSection(),
                    const SizedBox(height: 120), // Tambahkan ruang agar tidak tertutup nav bar
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
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _getModeColor().withOpacity(0.1),
                child: Icon(
                  _getModeIcon(),
                  size: 40,
                  color: _getModeColor(),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getProfileName(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getProfileSubtitle(),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
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
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
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

  Color _getModeColor() {
    switch (currentMode) {
      case ProfileMode.seller: return Colors.orange;
      case ProfileMode.driver: return Colors.indigo;
      default: return AppColors.primary;
    }
  }

  IconData _getModeIcon() {
    switch (currentMode) {
      case ProfileMode.seller: return Icons.storefront;
      case ProfileMode.driver: return Icons.motorcycle;
      default: return Icons.person;
    }
  }

  String _getProfileName() {
    switch (currentMode) {
      case ProfileMode.seller: return 'Toko Berkah LocalMart';
      case ProfileMode.driver: return 'Driver LocalSend #142';
      default: return 'Muhammad Akmal';
    }
  }

  String _getProfileSubtitle() {
    switch (currentMode) {
      case ProfileMode.seller:
        return isSellerRegistered ? '@${registeredStoreName.toLowerCase().replaceAll(' ', '')}' : 'Belum Terdaftar';
      case ProfileMode.driver:
        return isDriverRegistered ? '$registeredDriverPlate • ${isDriverOnline ? 'Online' : 'Offline'}' : 'Belum Terdaftar';
      default:
        return '+62 812 3456 7890';
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
                    _buildStatItem('Saldo Toko', 'Rp 450K', Icons.account_balance_wallet, Colors.orange),
                    const SizedBox(width: 15),
                    _buildStatItem('Pesanan', '12 Baru', Icons.shopping_bag_outlined, Colors.orange),
                  ],
                )
              : Row(
                  children: [
                    _buildStatItem(
                      'Local Point',
                      '1.250',
                      Icons.stars_outlined,
                      AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointsScreen())),
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
                color: Colors.black.withOpacity(0.03),
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
      _buildMenuItem(Icons.shopping_bag_outlined, 'Pesanan Saya', 'Status pesanan belanjaan Anda', AppColors.primary, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
      }),
      _buildMenuItem(Icons.favorite_border, 'Favorit', 'Produk UMKM tersimpan', Colors.pink, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
      }),
      _buildMenuItem(Icons.location_on_outlined, 'Alamat Pengiriman', 'Tempat tinggal atau kost Anda', Colors.green, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShippingAddressScreen()));
      }),
      _buildMenuItem(Icons.headset_mic_outlined, 'Bantuan & Laporan', 'Pusat bantuan pelanggan', Colors.purple, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
      }),
      _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi belanja', Colors.red, isLast: true),
    ];
  }

  List<Widget> _buildSellerMenuList() {
    return [
      _buildMenuItem(Icons.inventory_2_outlined, 'Produk Saya', 'Kelola barang jualan Anda', Colors.orange, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProductsScreen()));
      }),
      _buildMenuItem(Icons.list_alt_rounded, 'Pesanan Masuk', 'Proses pesanan dari pembeli', Colors.blue, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const IncomingOrdersScreen()));
      }),
      _buildMenuItem(Icons.analytics_outlined, 'Statistik Performa', 'Pantau kemajuan penjualan', Colors.teal, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreStatsScreen()));
      }),
      _buildMenuItem(Icons.storefront_outlined, 'Pengaturan Toko', 'Ubah profil dan jam operasional', Colors.indigo, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyStoreScreen()));
      }),
      _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi jualan', Colors.red, isLast: true),
    ];
  }

  List<Widget> _buildDriverMenuList() {
    return [
      _buildMenuItem(
        Icons.power_settings_new,
        isDriverOnline ? 'Status: Online' : 'Status: Offline',
        isDriverOnline ? 'Siap menerima pesanan pengantaran' : 'Tutup sementara',
        isDriverOnline ? Colors.green : Colors.grey,
        onTapCallback: () => setState(() => isDriverOnline = !isDriverOnline),
        trailingWidget: Switch(
          value: isDriverOnline,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.green.withOpacity(0.3),
          onChanged: (v) => setState(() => isDriverOnline = v),
        ),
      ),
      _buildMenuItem(Icons.directions_run_outlined, 'Pesanan Pengantaran', 'Daftar orderan kurir/ojek', Colors.indigo, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FindOrdersScreen()));
      }),
      _buildMenuItem(Icons.account_balance_wallet_outlined, 'Dompet Pendapatan', 'Cek dan tarik saldo penghasilan', Colors.blueGrey, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverWalletScreen()));
      }),
      _buildMenuItem(Icons.motorcycle_outlined, 'Info Kendaraan', 'Atur detail plat dan jenis motor', Colors.teal, onTapCallback: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleSettingsScreen()));
      }),
      _buildMenuItem(Icons.logout, 'Keluar', 'Akhiri sesi driver', Colors.red, isLast: true),
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
              color: color.withOpacity(0.1),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Menu $title segera hadir!')),
                );
              },
        ),
        if (!isLast) Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey[100]),
      ],
    );
  }
}

