import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/store_models.dart';
import '../controllers/store_controller.dart';
import '../widgets/store_product_card.dart';
import '../my_store_screen.dart';
import '../../auth/widgets/auth_utils.dart';
import '../../../core/utils/app_alert.dart';
import '../../auth/controllers/auth_controller.dart';

class StoreDetailScreen extends StatefulWidget {
  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late StoreController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(StoreController(storeId: widget.storeId), tag: widget.storeId.toString());
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    Get.delete<StoreController>(tag: widget.storeId.toString());
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingShimmer();
        }

        final store = controller.storeDetail.value?.store;
        if (store == null) {
          return const Center(child: Text("Toko tidak ditemukan"));
        }

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(store, innerBoxIsScrolled),
              _buildStoreHeader(store),
              _buildTabBar(),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBerandaTab(),
              _buildProdukTab(),
              _buildEtalaseTab(),
              _buildTentangTab(store),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAppBar(StoreModel store, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          onPressed: _handleChat,
        ),
        IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'delete') _showDeleteStoreDialog(store);
          },
          itemBuilder: (context) => [
            if (controller.isOwner.value)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Akun Toko', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            const PopupMenuItem(value: 'report', child: Text('Laporkan Toko')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Image
            Image.network(
              store.bannerUrl.isNotEmpty 
                ? ApiService().getImageUrl(store.bannerUrl)
                : (store.imageUrl.isNotEmpty 
                    ? ApiService().getImageUrl(store.imageUrl) 
                    : 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&q=80&w=800'),
              fit: BoxFit.cover,
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(StoreModel store) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                // Store Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      store.imageUrl.isNotEmpty 
                        ? ApiService().getImageUrl(store.imageUrl)
                        : 'https://ui-avatars.com/api/?name=${store.name}&background=random',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            store.name,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (store.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final store = controller.storeDetail.value?.store;
                        if (store == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            RatingBarIndicator(
                              rating: store.rating,
                              itemBuilder: (context, index) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                              direction: Axis.horizontal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.reviewCount > 0 
                                ? '${store.rating} (${store.reviewCount} ulasan)' 
                                : 'Belum ada ulasan',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${store.district}, ${store.village}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Follow Button
                Obx(() => _buildFollowButton()),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Produk', store.productCount.toString()),
                _buildStatItem('Pengikut', (controller.storeDetail.value?.followerCount ?? 0).toString()),
                _buildStatItem('Transaksi', (controller.storeDetail.value?.transactionCount ?? 0).toString()),
                _buildStatItem('Rating', store.rating.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    final following = controller.isFollowing.value;
    final isOwner = controller.isOwner.value;

    if (isOwner) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Get.to(() => const MyStoreScreen());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary),
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
              Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Kelola Toko',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        controller.toggleFollow();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: following ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          following ? 'Mengikuti' : 'Ikuti',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: following ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Beranda"),
            Tab(text: "Produk"),
            Tab(text: "Etalase"),
            Tab(text: "Tentang"),
          ],
        ),
      ),
    );
  }

  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Produk Terlaris",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text("Lihat Semua"),
              ),
            ],
          ),
          Obx(() {
            if (controller.isLoadingProducts.value) {
              return _buildProductLoadingShimmer();
            }
            if (controller.featuredProducts.isEmpty) {
              return const Center(child: Text("Belum ada produk terlaris"));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.featuredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) => StoreProductCard(
                product: controller.featuredProducts[index],
                heroTag: 'store_featured_${controller.featuredProducts[index].id}',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProdukTab() {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return _buildProductLoadingShimmer();
      }
      if (controller.products.isEmpty) {
        return const Center(child: Text("Belum ada produk"));
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) => StoreProductCard(
          product: controller.products[index],
          heroTag: 'store_all_${controller.products[index].id}',
        ),
      );
    });
  }

  Widget _buildEtalaseTab() {
    return Obx(() {
      final categories = controller.storeDetail.value?.categories ?? [];
      
      if (categories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Belum ada etalase",
                style: GoogleFonts.manrope(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildEtalaseItem(cat.name, cat.id);
        },
      );
    });
  }

  Widget _buildEtalaseItem(String title, int categoryId) {
    return Obx(() {
      final isSelected = controller.selectedStoreCategoryId.value == categoryId;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.filterByStoreCategory(categoryId);
          _tabController.animateTo(1); // Jump to Produk tab
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: GoogleFonts.manrope(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Icon(
                Icons.chevron_right, 
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTentangTab(StoreModel store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Deskripsi Toko", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            store.description.isNotEmpty ? store.description : "Selamat datang di toko kami! Kami menyediakan berbagai produk berkualitas untuk memenuhi kebutuhan Anda.",
            style: GoogleFonts.manrope(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text("Informasi Toko", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_rounded, "Alamat", store.address),
          _buildInfoRow(Icons.calendar_today_rounded, "Bergabung", "Sejak Jan 2024"),
          _buildInfoRow(Icons.access_time_filled_rounded, "Jam Operasional", "08:00 - 20:00"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(height: 180, color: Colors.white),
          Container(height: 100, color: Colors.white, margin: const EdgeInsets.all(16)),
          Expanded(child: Container(color: Colors.white, margin: const EdgeInsets.symmetric(horizontal: 16))),
        ],
      ),
    );
  }

  Widget _buildProductLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _handleChat() async {
    final store = controller.storeDetail.value?.store;
    if (store == null) return;
    
    if (!AuthUtils.isLoggedIn) {
      AppAlert.info('Login Diperlukan', 'Silakan login untuk memulai percakapan dengan penjual');
      return;
    }

    if (store.userId == AuthController.to.user.value?.id) {
       AppAlert.info('Info', 'Ini adalah toko Anda sendiri');
       return;
    }

    // Show loading indicator
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final convData = await ApiService().startConversation(store.userId);
      Get.back(); // Close loading

      if (convData.isNotEmpty) {
        Get.toNamed(
          '/chat-room',
          arguments: store,
        );
      } else {
        AppAlert.error('Gagal', 'Tidak dapat memulai percakapan');
      }
    } catch (e) {
      Get.back(); // Close loading
      AppAlert.error('Error', 'Terjadi kesalahan saat memulai chat');
    }
  }

  void _showDeleteStoreDialog(StoreModel store) {
    final nameController = TextEditingController();
    final RxBool canDelete = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Akun Toko?', 
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tindakan ini permanen. Semua produk, ulasan, dan data bisnis Anda akan dihapus selamanya.',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Data tidak dapat dipulihkan!', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ketik nama toko "${store.name}" untuk konfirmasi:',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              onChanged: (val) => canDelete.value = val.trim() == store.name.trim(),
              decoration: InputDecoration(
                hintText: 'Nama Toko Anda',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Obx(() => ElevatedButton(
            onPressed: canDelete.value ? () => _handleDeleteStore() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  void _handleDeleteStore() async {
    Get.back(); // Close confirmation dialog
    
    // Show loading
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
    
    try {
      final result = await ApiService().deleteStore();
      Get.back(); // Close loading

      if (result['success']) {
        AppAlert.success('Toko Berhasil Dihapus', result['message']);
        
        // SESSION CLEANUP: Reset Auth state to reflect user has no store
        final auth = AuthController.to;
        if (auth.user.value != null) {
          // Force a profile refresh to update 'has_store' status or similar local flags
          await auth.refreshUser();
        }
        
        // Redirect to Home
        Get.offAllNamed('/main'); 
      } else {
        AppAlert.error('Gagal Menghapus', result['message'] ?? 'Terjadi kesalahan sistem');
      }
    } catch (e) {
      Get.back(); // Close loading
      AppAlert.error('Error', 'Kesalahan koneksi ke server');
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

