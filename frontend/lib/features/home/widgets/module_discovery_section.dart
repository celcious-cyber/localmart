import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/home_data.dart';
import '../controllers/home_data_controller.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../../core/services/api_service.dart';

class ModuleDiscoverySection extends GetView<HomeDataController> {
  final ModuleDiscoveryModel module;
  final ApiService _api = ApiService();

  ModuleDiscoverySection({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Module Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                module.discoveryTitle ?? module.name,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  final activeId = controller.getActiveCategoryId(module.slug);
                  
                  // Routing map for modular discovery
                  final Map<String, String> routeMap = {
                    'food': '/localfood',
                    'kost': '/kost',
                    'rental': '/rental',
                    'transport': '/transport',
                    'jasa': '/service',
                    'umkm': '/umkm',
                    'bumi': '/agri',
                    'wisata': '/tourism',
                    'second': '/second-hand',
                  };

                  final targetRoute = routeMap[module.slug] ?? '/home';
                  
                  Get.toNamed(
                    targetRoute,
                    arguments: {'category_id': activeId},
                  );
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
        ),

        // 2. Category Pills (Horizontal Scroll)
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: module.categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final cat = module.categories[index];
              return Obx(() {
                final isSelected = controller.getActiveCategoryId(module.slug) == cat.id;
                return GestureDetector(
                  onTap: () => controller.switchCategory(module.slug, cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Text(
                      cat.name,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // 3. Product Carousel with Fixed Height & Shimmer
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 280),
          child: Obx(() {
            final products = controller.getProductsForModule(module.slug);
            final isLoading = controller.isModuleRefreshing(module.slug);

            if (isLoading) {
              return _buildPremiumShimmer();
            }

            if (products.isEmpty) {
              return _buildEmptyState();
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 4, bottom: 20),
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildDiscoveryProductCard(context, product),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiscoveryProductCard(BuildContext context, ProductModel product) {
    const String heroTagPrefix = 'module_disc_';
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailScreen(
              product: product,
              heroTag: '$heroTagPrefix${product.id}',
            ));
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  _api.getImageUrl(product.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[100]),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.store?.name ?? 'Official Store',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${product.price.toInt()}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
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
  }

  Widget _buildPremiumShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.white,
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.grey[300], size: 48),
            const SizedBox(height: 12),
            Text(
              'Produk belum tersedia',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
