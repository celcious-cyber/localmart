import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../features/store/screens/store_detail_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/home/widgets/modular_banner_carousel.dart';
import '../../shared/widgets/reactive_cart_icon.dart';
import '../controllers/modular_discovery_controller.dart';

class ModularDiscoveryScreen extends StatelessWidget {
  final String title;
  final String moduleCode;
  final String serviceType;
  final String searchPlaceholder;

  const ModularDiscoveryScreen({
    super.key,
    required this.title,
    required this.moduleCode,
    required this.serviceType,
    this.searchPlaceholder = 'Cari apa saja di sini...',
  });

  @override
  Widget build(BuildContext context) {
    // Unique tag for each module to avoid controller collision
    final controller = Get.put(
      ModularDiscoveryController(moduleCode: moduleCode, serviceType: serviceType),
      tag: moduleCode,
    );
    final apiService = ApiService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // 1. Unified Header with Search
            _buildSliverAppBar(context),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Categories
                    _buildSectionHeader(
                      'Pilihan Kategori',
                      onSeeAll: () => _showAllCategoriesBottomSheet(context, controller),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return _buildCategoryShimmer();
                      }
                      return _buildHorizontalCategories(controller);
                    }),
                    const SizedBox(height: 40),

                    // 3. Modular Banners
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ModularBannerCarousel(module: moduleCode),
                    ),
                    const SizedBox(height: 48),

                    // 4. Featured Products (Recommendations)
                    Obx(() {
                      if (controller.isLoading.value) {
                        return Column(
                          children: [
                            _buildSectionHeader('Rekomendasi Terpopuler'),
                            const SizedBox(height: 16),
                            _buildProductShimmer(),
                            const SizedBox(height: 48),
                          ],
                        );
                      }
                      if (controller.featuredProducts.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildSectionHeader('Rekomendasi Terpopuler'),
                          const SizedBox(height: 16),
                          _buildProductList(context, controller, apiService),
                          const SizedBox(height: 48),
                        ],
                      );
                    }),

                    // 5. Featured Stores (Merchants)
                    _buildSectionHeader('Pilihan Merchant'),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return _buildStoreShimmer();
                      }
                      if (controller.featuredStores.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildStoreGrid(context, controller, apiService);
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 155,
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Text(
                'Taliwang, KSB',
                style: GoogleFonts.manrope(fontSize: 10, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        const ReactiveCartIcon(iconColor: Colors.white),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: _buildSearchBar(context),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const SearchScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(searchPlaceholder, style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text('Lihat Semua', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCategories(ModularDiscoveryController controller) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getCategoryIcon(cat.iconName), color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 8),
                Text(cat.name, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, ModularDiscoveryController controller, ApiService apiService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: controller.featuredProducts.map((product) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => Get.to(() => ProductDetailScreen(product: product)),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        apiService.getImageUrl(product.imageUrl),
                        height: 130,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 130, width: 160, color: Colors.grey[100],
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(apiService.formatCurrency(product.price), style: GoogleFonts.epilogue(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreGrid(BuildContext context, ModularDiscoveryController controller, ApiService apiService) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: controller.featuredStores.length,
      itemBuilder: (context, index) {
        final store = controller.featuredStores[index];
        return GestureDetector(
          onTap: () => Get.to(() => StoreDetailScreen(storeId: store.id)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    apiService.getImageUrl(store.imageUrl),
                    height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180, width: double.infinity, color: Colors.grey[100],
                      child: const Icon(Icons.storefront_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(store.village, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(store.rating.toStringAsFixed(1), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helpers (Shimmers, Empty State, Icons) ---

  Widget _buildCategoryShimmer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: List.generate(5, (_) => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
          child: Column(children: [
            Container(width: 65, height: 65, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 8), Container(width: 40, height: 10, color: Colors.white),
          ]),
        ),
      ))),
    );
  }

  Widget _buildProductShimmer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
          child: Container(width: 160, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
        ),
      ))),
    );
  }

  Widget _buildStoreShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada data tersedia.', style: GoogleFonts.manrope(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'home_work': return Icons.home_work;
      case 'house': return Icons.house;
      case 'two_wheeler': return Icons.two_wheeler;
      case 'directions_car': return Icons.directions_car;
      case 'brush': return Icons.brush;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'agriculture': return Icons.agriculture_rounded;
      case 'explore': return Icons.explore_rounded;
      case 'devices': return Icons.devices;
      case 'checkroom': return Icons.checkroom;
      default: return Icons.category_outlined;
    }
  }

  void _showAllCategoriesBottomSheet(BuildContext context, ModularDiscoveryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pilihan Kategori', style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 0.8),
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = controller.categories[index];
                  return Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                          child: Icon(_getCategoryIcon(cat.iconName), color: AppColors.primary, size: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(cat.name, textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
