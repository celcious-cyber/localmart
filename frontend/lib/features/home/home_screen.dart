import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/modular_banner_carousel.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_patterns.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../search/screens/search_screen.dart';
import '../../shared/screens/modular_discovery_screen.dart';
import '../scan/scan_screen.dart';
import '../chat/chat_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../localsend/localsend_screen.dart';
import '../bills/bills_screen.dart';
import '../localpay/localpay_screen.dart';
import '../profile/screens/favorites_screen.dart';
import '../product/screens/product_detail_screen.dart';
import '../profile/controllers/favorites_controller.dart';
import './controllers/home_data_controller.dart';
import './widgets/module_discovery_section.dart';
import '../../shared/widgets/reactive_cart_icon.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _activeCategoryTab = 0;
  int _activeDiscoveryTab = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  final ScrollController _categoryScrollController = ScrollController();

  // API State
  final ApiService _api = ApiService();
  final FavoritesController _favController = Get.put(FavoritesController());

  // Note: Local discovery states kept for legacy 'discovery' section if needed,
  // but most logic moved to HomeDataController.
  List<ProductModel> _discoveryProducts = [];
  bool _isDiscoveryLoading = false;

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

    // Auto-fetch first discovery tab for legacy section
    _homeController.homeData.listen((data) {
      if (data != null &&
          data.discoveryTabs.isNotEmpty &&
          _discoveryProducts.isEmpty) {
        _fetchDiscoveryProducts(0);
      }
    });
  }

  Future<void> _fetchDiscoveryProducts(int index) async {
    final homeData = _homeController.homeData.value;
    if (homeData == null || homeData.discoveryTabs.isEmpty) return;

    setState(() {
      _activeDiscoveryTab = index;
      _isDiscoveryLoading = true;
    });

    final tabName = homeData.discoveryTabs[index].name;
    String tag = 'panen_hari_ini';
    if (tabName.toLowerCase().contains('umkm')) {
      tag = 'umkm_pilihan';
    } else if (tabName.toLowerCase().contains('ksb')) {
      tag = 'eksplore_ksb';
    } else if (tabName.toLowerCase().contains('local')) {
      tag = 'local_mart';
    }

    final products = await _api.getDiscoveryProducts(tag);

    if (mounted) {
      setState(() {
        _discoveryProducts = products;
        _isDiscoveryLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _categoryScrollController.dispose();
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
      backgroundColor: AppColors.background,
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

  final HomeDataController _homeController = Get.put(HomeDataController());

  // ════════════════════════════════════════════════════════════════
  // HOME BODY
  // ════════════════════════════════════════════════════════════════
  Widget _buildHomeBody(BuildContext context) {
    return Obx(() {
      if (_homeController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _homeController.fetchHomeData(),
        color: AppColors.primary,
        child: CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            // Pinned Header with Search Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDynamicSections(),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildDynamicSections() {
    final homeData = _homeController.homeData.value;
    if (homeData == null) {
      return [const Center(child: Text("Gagal memuat data"))];
    }

    List<Widget> sections = [const SizedBox(height: 12)];

    // Map module keys to ModuleDiscovery widgets
    final moduleMap = {for (var m in homeData.modules) m.slug: m};

    for (var section in homeData.sections) {
      if (!section.isActive) continue;

      switch (section.key) {
        case 'quick_actions':
          sections.add(_buildQuickActionRow());
          // Menghilangkan SizedBox height agar benar-benar rapat dengan seksi di bawahnya
          break;
        case 'banner_top':
          sections.add(_buildBannerCarousel());
          sections.add(const SizedBox(height: 20));
          break;
        case 'categories':
          sections.add(_buildCategoryTabs());
          sections.add(const SizedBox(height: 14));
          break;
        case 'products':
          sections.add(_buildProductGrid());
          sections.add(const SizedBox(height: 20));
          break;
        case 'banner_slider':
          // Banner slider sudah dikonsolidasi ke carousel atas
          break;
        case 'discovery':
          sections.add(_buildDiscoveryHeader());
          sections.add(const SizedBox(height: 12));
          sections.add(_buildDiscoveryPills());
          sections.add(const SizedBox(height: 16));
          sections.add(_buildDiscoveryProductGrid());
          sections.add(const SizedBox(height: 12));
          break;
        default:
          // Handle dynamic modular discovery sections (module_*)
          if (section.key.startsWith('module_')) {
            final moduleSlug = section.key.replaceFirst('module_', '');
            if (moduleMap.containsKey(moduleSlug)) {
              sections.add(
                ModuleDiscoverySection(module: moduleMap[moduleSlug]!),
              );
              sections.add(const SizedBox(height: 20));
            }
          }
          break;
      }
    }

    // Spacing for bottom nav
    sections.add(const SizedBox(height: 120));

    return sections;
  }

  // ════════════════════════════════════════════════════════════════
  // QUICK ACTION ROW (small circle icons)
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuickActionRow() {
    final actions = [
      {'icon': Icons.restaurant, 'label': 'LocalFood', 'screen': 'LocalFood'},
      {
        'icon': Icons.delivery_dining,
        'label': 'LocalSend',
        'screen': 'LocalSend',
      },
      {'icon': Icons.receipt_long, 'label': 'Tagihan', 'screen': 'Tagihan'},
      {
        'icon': Icons.account_balance_wallet,
        'label': 'LocalPay',
        'screen': 'LocalPay',
      },
      {'icon': Icons.home_work, 'label': 'Kost', 'screen': 'Kost'},
      {'icon': Icons.car_rental, 'label': 'Rental', 'screen': 'Rental'},
      {
        'icon': Icons.directions_bus,
        'label': 'Transport',
        'screen': 'Transport',
      },
      {'icon': Icons.handyman_rounded, 'label': 'Jasa', 'screen': 'Jasa'},
      {'icon': Icons.store, 'label': 'UMKM', 'screen': 'UMKM'},
      {
        'icon': Icons.agriculture_rounded,
        'label': 'Hasil Bumi',
        'screen': 'Hasil Bumi',
      },
      {'icon': Icons.explore_rounded, 'label': 'Wisata', 'screen': 'Wisata'},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Second', 'screen': 'Second'},
    ];

    if (actions.isEmpty) {
      return Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("Layanan tidak tersedia")),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero, // Menghilangkan padding default GridView
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 0, // Menghilangkan jarak antar baris grid
          crossAxisSpacing: 0,
          childAspectRatio: 1.25, // Membuat kotak lebih pendek
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToService(action['screen'] as String);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action['label'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BANNER CAROUSEL (Unified)
  // ════════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════
  // BANNER CAROUSEL (Updated to Modular)
  // ════════════════════════════════════════════════════════════════
  Widget _buildBannerCarousel() {
    return const ModularBannerCarousel(module: 'home');
  }

  // ════════════════════════════════════════════════════════════════
  // CATEGORY TABS
  // ════════════════════════════════════════════════════════════════
  Widget _buildCategoryTabs() {
    final categories = _homeController.homeData.value?.categories ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _activeCategoryTab == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _activeCategoryTab = index);

              // Scroll-to-center logic
              _categoryScrollController
                  .animateTo(
                    index * 100.0 -
                        (MediaQuery.of(context).size.width / 2) +
                        50.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  )
                  .catchError((_) {}); // Ignore if scroll is already at end
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                categories[index].name,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PRODUCT GRID (Category Section)
  // ════════════════════════════════════════════════════════════════
  Widget _buildProductGrid() {
    final categories = _homeController.homeData.value?.categories ?? [];
    if (categories.isEmpty || _activeCategoryTab >= categories.length) {
      return const SizedBox.shrink();
    }

    final products = categories[_activeCategoryTab].products;
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Belum ada produk di kategori ini"),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product, 'home_recom_${product.id}');
        },
      ),
    );
  }

  Widget _buildProductCard(
    ProductModel product,
    String heroTag, {
    double? width,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(product: product, heroTag: heroTag),
          ),
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Heart Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: Hero(
                      tag: heroTag,
                      child: Image.network(
                        _api.getImageUrl(product.imageUrl),
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
                ),
                // Heart Icon Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final isFav = _favController.isFavorited(product.id);
                    return GestureDetector(
                      onTap: () => _favController.toggleFavorite(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : Colors.grey[400],
                          size: 18,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp ${product.price.toInt()}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '|',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terjual ${product.sold}',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DISCOVERY HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildDiscoveryHeader() {
    final activeTabName =
        _homeController.homeData.value != null &&
            _homeController.homeData.value!.discoveryTabs.isNotEmpty
        ? _homeController
              .homeData
              .value!
              .discoveryTabs[_activeDiscoveryTab]
              .name
        : 'Discovery';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            activeTabName,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to discovery detail screen
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Lihat Semua'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DISCOVERY PILLS
  // ════════════════════════════════════════════════════════════════
  Widget _buildDiscoveryPills() {
    final tabs = _homeController.homeData.value?.discoveryTabs ?? [];
    if (tabs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _activeDiscoveryTab == index;
          return GestureDetector(
            onTap: () {
              if (_activeDiscoveryTab != index) {
                _fetchDiscoveryProducts(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Text(
                tabs[index].name,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DISCOVERY PRODUCT GRID
  // ════════════════════════════════════════════════════════════════
  Widget _buildDiscoveryProductGrid() {
    if (_isDiscoveryLoading) {
      return _buildDiscoveryShimmer();
    }

    final products = _discoveryProducts;

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada produk di kategori ini',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(left: 16, right: 4, bottom: 20),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildProductCard(
              product,
              'home_disc_${product.id}',
              width: 170,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.white,
              child: Container(
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SERVICE NAVIGATION HELPER
  // ════════════════════════════════════════════════════════════════
  void _navigateToService(String label) {
    Widget screen;
    switch (label) {
      case 'LocalFood':
        screen = const ModularDiscoveryScreen(
          title: 'LocalFood',
          moduleCode: 'food',
          serviceType: 'food',
          searchPlaceholder: 'Mau makan apa hari ini?',
        );
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
        screen = const ModularDiscoveryScreen(
          title: 'LocalKost',
          moduleCode: 'kost',
          serviceType: 'kost',
          searchPlaceholder: 'Cari kost di area Taliwang...',
        );
        break;
      case 'Rental':
        screen = const ModularDiscoveryScreen(
          title: 'LocalRental',
          moduleCode: 'rental',
          serviceType: 'rental',
          searchPlaceholder: 'Cari motor atau mobil...',
        );
        break;
      case 'Transport':
        screen = const ModularDiscoveryScreen(
          title: 'LocalTransport',
          moduleCode: 'transport',
          serviceType: 'transport',
          searchPlaceholder: 'Cari tiket bus atau travel...',
        );
        break;
      case 'Jasa':
        screen = const ModularDiscoveryScreen(
          title: 'LocalService',
          moduleCode: 'jasa',
          serviceType: 'jasa',
          searchPlaceholder: 'Cari layanan jasa AC, Las, dll...',
        );
        break;
      case 'Wisata':
        screen = const ModularDiscoveryScreen(
          title: 'LocalTourism',
          moduleCode: 'wisata',
          serviceType: 'wisata',
          searchPlaceholder: 'Eksplor tempat wisata seru...',
        );
        break;
      case 'Second':
        screen = const ModularDiscoveryScreen(
          title: 'LocalSecond',
          moduleCode: 'second',
          serviceType: 'second',
          searchPlaceholder: 'Cari barang bekas berkualitas...',
        );
        break;
      case 'UMKM':
        screen = const ModularDiscoveryScreen(
          title: 'LocalUMKM',
          moduleCode: 'umkm',
          serviceType: 'umkm',
          searchPlaceholder: 'Cari produk khas KSB...',
        );
        break;
      case 'Hasil Bumi':
        screen = const ModularDiscoveryScreen(
          title: 'LocalAgri',
          moduleCode: 'bumi',
          serviceType: 'bumi',
          searchPlaceholder: 'Cari beras, madu, hasil tani...',
        );
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // ════════════════════════════════════════════════════════════════
  // FLOATING NAVBAR (kept from original)
  // ════════════════════════════════════════════════════════════════
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
}

// ════════════════════════════════════════════════════════════════════════════
// SEARCH HEADER DELEGATE
// ════════════════════════════════════════════════════════════════════════════
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 100.0;

  @override
  double get maxExtent => 165.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: maxExtent,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.secondary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Wave pattern background
              Positioned.fill(
                child: CustomPaint(
                  painter: WavyPatternPainter(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              
              // Row 1 (Top): Logo & Action Icons
              Opacity(
                opacity: (1.0 - (shrinkOffset / (maxExtent - minExtent) * 2))
                    .clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo/localmart.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      // Action Icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderIcon(
                            Icons.favorite_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FavoritesScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(
                            count: 2,
                            child: const ReactiveCartIcon(),
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(
                            count: 5,
                            child: _buildHeaderIcon(
                              Icons.notifications_none_rounded,
                              onTap: () => _showNotificationPopup(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Row 2 (Bottom): Search Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cari di localmart',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 450),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifikasi Terbaru',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNotifItem(
                      icon: Icons.local_offer_rounded,
                      color: Colors.orange,
                      title: 'Promo Spesial Maluk!',
                      desc: 'Diskon 20% untuk semua menu di Lesehan Taliwang. Berlaku s/d hari ini.',
                      time: '12 Menit yang lalu',
                    ),
                    _buildNotifItem(
                      icon: Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      title: 'Pesanan Diproses',
                      desc: 'Driver sedang menuju Resto Maluk Beach untuk menjemput pesananmu.',
                      time: '45 Menit yang lalu',
                    ),
                    _buildNotifItem(
                      icon: Icons.system_update_rounded,
                      color: Colors.blue,
                      title: 'Aplikasi Diperbarui (v1.2.5)',
                      desc: 'Nikmati fitur Auto-Carousel Banner yang baru saja kami rilis!',
                      time: '2 Jam yang lalu',
                    ),
                  ],
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lihat Semua Notifikasi',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required int count, required Widget child}) {
    if (count == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// BOUNCY BUTTON COMPONENT
// ════════════════════════════════════════════════════════════════════════════
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncyButton({super.key, required this.child, this.onTap});

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOTTOM NAV BAR PAINTER (kept from original)
// ════════════════════════════════════════════════════════════════════════════
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

    // Smooth Concave Notch
    path.lineTo(notchX - 85, 0);
    path.cubicTo(notchX - 45, 0, notchX - 50, 42, notchX, 42);
    path.cubicTo(notchX + 50, 42, notchX + 45, 0, notchX + 85, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.2), 8, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BNBCustomPainter oldDelegate) {
    return oldDelegate.notchX != notchX;
  }
}
