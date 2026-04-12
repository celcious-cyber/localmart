import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_patterns.dart';
import '../scan/scan_screen.dart';
import '../chat/chat_screen.dart';
import '../localfood/localfood_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../localsend/localsend_screen.dart';
import '../bills/bills_screen.dart';
import '../localpay/localpay_screen.dart';
import '../kost/kost_screen.dart';
import '../rental/rental_screen.dart';
import '../transport/transport_screen.dart';
import '../service/service_screen.dart';
import '../tourism/tourism_screen.dart';
import '../second_hand/second_hand_screen.dart';
import '../umkm/umkm_screen.dart';
import '../agri/agri_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    _animation = Tween<double>(
      begin: _selectedIndex.toDouble(),
      end: index.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.reset();
    _controller.forward();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // Updated to Teal Horizon background
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeBody(context),
          const ChatScreen(),
          const ScanScreen(),
          const OrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildFloatingNavbar(),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return CustomScrollView(
      clipBehavior: Clip.none,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _HomeHeaderDelegate(
            onSettingsTap: () {},
            onNotificationsTap: () {},
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50), // Balance card overlap space
              _buildSearchBar(context),
              const SizedBox(height: 24),
              _buildServiceCategory('KEBUTUHAN HARIAN', [
                {
                  'label': 'LocalFood',
                  'icon': Icons.restaurant,
                  'color': Colors.orange,
                },
                {
                  'label': 'LocalSend',
                  'icon': Icons.delivery_dining,
                  'color': Colors.blue,
                },
                {
                  'label': 'Tagihan',
                  'icon': Icons.receipt_long,
                  'color': Colors.purple,
                },
                {
                  'label': 'LocalPay',
                  'icon': Icons.payments,
                  'color': Colors.redAccent,
                },
              ]),
              const SizedBox(height: 24),
              _buildServiceCategory('AKOMODASI & MOBILITAS', [
                {
                  'label': 'Kost',
                  'icon': Icons.home_work,
                  'color': Colors.teal,
                },
                {
                  'label': 'Rental',
                  'icon': Icons.directions_car,
                  'color': Colors.green,
                },
                {
                  'label': 'Transport',
                  'icon': Icons.directions_bus,
                  'color': Colors.blueAccent,
                },
                {
                  'label': 'Jasa',
                  'icon': Icons.handyman_rounded,
                  'color': Colors.indigo,
                },
              ]),
              const SizedBox(height: 24),
              _buildServiceCategory('EKONOMI LOKAL', [
                {
                  'label': 'UMKM',
                  'icon': Icons.storefront_rounded,
                  'color': Colors.orangeAccent,
                },
                {
                  'label': 'Hasil Bumi',
                  'icon': Icons.agriculture_rounded,
                  'color': Colors.greenAccent,
                },
                {
                  'label': 'Wisata',
                  'icon': Icons.explore_rounded,
                  'color': Colors.teal,
                },
                {
                  'label': 'Second',
                  'icon': Icons.sell_outlined,
                  'color': Colors.brown,
                },
              ]),
              const SizedBox(height: 24),
              _buildPromoBanner(),
              const SizedBox(height: 24),
              _buildSectionHeader('Favorit Terdekat'),
              _buildProductGrid(),
              const SizedBox(height: 120), // Reduced slightly to avoid overflow
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNavbar() {
    final double width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: Size(width, 80),
              painter: BNBCustomPainter(
                notchX: (_animation.value + 0.5) * (width / 5),
              ),
            ),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.chat_bubble_rounded, 'Chat'),
                  _buildNavItem(2, Icons.qr_code_scanner_rounded, 'Scan'),
                  _buildNavItem(3, Icons.assignment_rounded, 'Pesanan'),
                  _buildNavItem(4, Icons.person_rounded, 'Profil'),
                ],
              ),
            ),
            // Floating Active Icon - Raised slightly to prevent peeking at the bottom
            Positioned(
              left: (_animation.value + 0.5) * (width / 5) - 30,
              bottom: 38,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForIndex(_selectedIndex),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.chat_bubble_rounded;
      case 2:
        return Icons.qr_code_scanner_rounded;
      case 3:
        return Icons.assignment_rounded;
      case 4:
        return Icons.person_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: isActive ? 0 : 1,
              child: Icon(icon, color: Colors.grey[400], size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF5F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cari makanan, jasa, atau tempat...',
                style: GoogleFonts.manrope(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategory(
    String title,
    List<Map<String, dynamic>> services,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.epilogue(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: (MediaQuery.of(context).size.width - 40 - (65 * 4)) / 3,
            runSpacing: 20,
            children: services.map((s) => _buildSimpleServiceIcon(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleServiceIcon(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () {
        final label = service['label'];
        Widget screen;

        switch (label) {
          case 'LocalFood':
            screen = const LocalFoodScreen();
            break;
          case 'LocalSend':
            screen = const LocalSendScreen();
            break;
          case 'Tagihan':
            screen = const BillsScreen();
            break;
          case 'LocalPay':
            screen = const LocalPayScreen();
            break;
          case 'Kost':
            screen = const KostScreen();
            break;
          case 'Rental':
            screen = const RentalScreen();
            break;
          case 'Transport':
            screen = const TransportScreen();
            break;
          case 'Jasa':
            screen = const ServiceScreen();
            break;
          case 'Wisata':
            screen = const TourismScreen();
            break;
          case 'Second':
            screen = const SecondHandScreen();
            break;
          case 'UMKM':
            screen = const UMKMScreen();
            break;
          case 'Hasil Bumi':
            screen = const AgriScreen();
            break;
          default:
            return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: SizedBox(
        width: 65,
        child: Column(
          children: [
            Icon(
              service['icon'] as IconData,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              service['label'] as String,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF006766), Color(0xFF35B7B2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CASHBACK 50%',
                  style: GoogleFonts.epilogue(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Belanja kebutuhan harian pertamamu',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Klaim Voucher >',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Lihat Semua',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final List<Map<String, String>> products = [
      {
        'name': 'Madu KSB Murni',
        'price': 'Rp 120.000',
        'distance': '1.2 km',
        'rating': '4.9',
        'image':
            'https://images.unsplash.com/photo-1663963603322-d51827492f69?auto=format&fit=crop&q=80&w=400',
      },
      {
        'name': 'Kopi Tepal Original',
        'price': 'Rp 85.000',
        'distance': '0.8 km',
        'rating': '4.8',
        'image':
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?auto=format&fit=crop&q=80&w=400',
      },
      {
        'name': 'Susu Kuda Liar',
        'price': 'Rp 55.000',
        'distance': '2.5 km',
        'rating': '4.7',
        'image':
            'https://plus.unsplash.com/premium_photo-1695166779538-2adb55dc5e29?auto=format&fit=crop&q=80&w=400',
      },
      {
        'name': 'Keripik Jagung',
        'price': 'Rp 15.000',
        'distance': '0.5 km',
        'rating': '4.9',
        'image':
            'https://images.unsplash.com/photo-1699666397768-0126340e880a?q=80&w=688&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              // Navigation to detail disabled for cleanup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detail produk akan segera hadir!')),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006A67).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        product['image']!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name']!,
                          style: GoogleFonts.epilogue(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product['distance']!,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product['rating']!,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['price']!,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSettingsTap;
  final VoidCallback onNotificationsTap;

  _HomeHeaderDelegate({
    required this.onSettingsTap,
    required this.onNotificationsTap,
  });

  @override
  double get minExtent => 100.0; // Height when collapsed

  @override
  double get maxExtent => 260.0; // Height when expanded

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress = shrinkOffset / (maxExtent - minExtent);
    final double currentOpacity = 1.0 - (progress.clamp(0.0, 1.0));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Teal Gradient Background
        Container(
          height: maxExtent - shrinkOffset,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: WavyPatternPainter(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Opacity(
                opacity: currentOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1654110455429-cf322b40a906?q=80&w=880&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELAMAT PAGI',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Muhammad Akmal',
                              style: GoogleFonts.epilogue(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onNotificationsTap,
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: onSettingsTap,
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Saldo Tersedia',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp 1.250.000',
                    style: GoogleFonts.epilogue(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),

        // 2. Sticky Minimal Header (shown when collapsed)
        if (progress > 0.5)
          Opacity(
            opacity: ((progress - 0.5) * 2).clamp(0.0, 1.0),
            child: Container(
              height: minExtent,
              color: AppColors.primary,
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Row(
                children: [
                  Text(
                    'LocalMart',
                    style: GoogleFonts.epilogue(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rp 1.250k',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. The Overlapping Card (The Star of the show)
        // Fixed at the junction of the header and body
        Positioned(
          bottom: -35,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: currentOpacity,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006A67).withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernAction(Icons.add_circle_outline, 'Top Up'),
                  _buildModernAction(Icons.send_rounded, 'Kirim'),
                  _buildModernAction(Icons.qr_code_scanner_rounded, 'Scan'),
                  _buildModernAction(Icons.history_rounded, 'Riwayat'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) => true;
}

class BNBCustomPainter extends CustomPainter {
  final double notchX;

  BNBCustomPainter({required this.notchX});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);

    // Smooth Concave Notch - Refined curve for better wrapping
    path.lineTo(notchX - 85, 0);
    path.cubicTo(notchX - 45, 0, notchX - 50, 42, notchX, 42);
    path.cubicTo(notchX + 50, 42, notchX + 45, 0, notchX + 85, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Premium Shadow - Optimized elevation for performance
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.2), 8, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BNBCustomPainter oldDelegate) {
    return oldDelegate.notchX != notchX;
  }
}
