import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';
import '../../../shared/models/review_model.dart';
import '../../profile/controllers/favorites_controller.dart';
import '../../store/controllers/store_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../../../shared/widgets/reactive_cart_icon.dart';
import '../../store/screens/store_detail_screen.dart';
import '../../auth/widgets/auth_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.product, this.heroTag});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  late final ProductDetailController _controller;
  late final StoreController _storeController;
  Map<String, dynamic> _metadata = {};
  bool _isDescriptionExpanded = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  FavoritesController get _favController => Get.isRegistered<FavoritesController>() 
      ? Get.find<FavoritesController>() 
      : Get.put(FavoritesController());

  @override
  void initState() {
    super.initState();
    // Initialize Product Controller
    _controller = Get.put(
      ProductDetailController(product: widget.product),
      tag: 'product_${widget.product.id}'
    );
    // Initialize Store Controller (for follow logic)
    _storeController = Get.put(
      StoreController(storeId: widget.product.storeId), 
      tag: 'store_${widget.product.storeId}'
    );
    _parseMetadata();
  }

  void _parseMetadata() {
    if (widget.product.metadata.isNotEmpty && widget.product.metadata != '{}') {
      try {
        setState(() {
          _metadata = jsonDecode(widget.product.metadata);
        });
      } catch (e) {
        debugPrint('Error parsing metadata: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 400,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageCarousel(),

                  // BOTTOM ROUNDED CORNERS OVERLAY
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  // PAGE INDICATOR (PILL STYLE)
                  _buildPageIndicator(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                _buildDivider(),
                _buildDetailsAndDescription(),
                _buildDivider(),
                _buildStoreInfo(),
                _buildDivider(),
                _buildReviewSection(),
                _buildDivider(),
                _buildRecommendationSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color.fromARGB(255, 1, 114, 112),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Container(
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Cari jasa atau produk...',
            hintStyle: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[400],
            ),
            prefixIcon: null,
            suffixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
        const ReactiveCartIcon(iconColor: Colors.white),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.product.images;
    final totalImages = images.length;

    if (totalImages == 0) {
      return Hero(
        tag: widget.heroTag ?? 'product_image_${widget.product.id}',
        child: Image.network(
          _api.getImageUrl(widget.product.imageUrl),
          fit: BoxFit.cover,
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      itemCount: totalImages,
      itemBuilder: (context, index) {
        final imageUrl = _api.getImageUrl(images[index].imageUrl);
        return Hero(
          tag: index == 0
              ? (widget.heroTag ?? 'product_image_${widget.product.id}')
              : 'carousel_${widget.product.id}_$index',
          child: Image.network(imageUrl, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    final totalImages = widget.product.images.isNotEmpty
        ? widget.product.images.length
        : 1;
    if (totalImages <= 1) return const SizedBox.shrink();

    return Positioned(
      bottom: 40,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          '${_currentImageIndex + 1} / $totalImages',
          style: GoogleFonts.manrope(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final isFav = _favController.isFavorited(widget.product.id);
                return GestureDetector(
                  onTap: () => _favController.toggleFavorite(widget.product),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : Colors.grey[400],
                    size: 28,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.product.condition == 'Baru' ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.product.condition == 'Baru' ? Colors.green[100]! : Colors.orange[100]!),
            ),
            child: Text(
              widget.product.condition.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: widget.product.condition == 'Baru' ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            _api.formatCurrency(_controller.selectedVariant.value?.price ?? widget.product.price),
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          )),
          const SizedBox(height: 16),
          Obx(() {
            final p = _controller.productDetail.value ?? widget.product;
            return Row(
              children: [
                _buildStatItem('${p.rating}', isRating: true, rating: p.rating),
                _buildVerticalDivider(),
                _buildStatItem(
                  p.reviewCount > 0 
                    ? '${p.reviewCount} Penilaian' 
                    : 'Belum ada ulasan'
                ),
                _buildVerticalDivider(),
                _buildStatItem('Terjual ${_formatSold(p.sold)}'),
              ],
            );
          }),
          if (widget.product.variants.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Pilih Varian',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildVariantSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, {bool isRating = false, double rating = 0.0}) {
    return Row(
      children: [
        if (isRating) ...[
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(
              Icons.star_rounded,
              color: Colors.orange,
            ),
            itemCount: 5,
            itemSize: 18.0,
            direction: Axis.horizontal,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[300],
    );
  }

  Widget _buildVariantSelector() {
    return Obx(() {
      return SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.product.variants.length,
          itemBuilder: (context, index) {
            final variant = widget.product.variants[index];
            bool isSelected = _controller.selectedVariant.value?.id == variant.id;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(
                  variant.name,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey[200]!,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    _controller.selectVariant(variant);
                  } else {
                    _controller.selectedVariant.value = null;
                  }
                },
                showCheckmark: false,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      width: double.infinity,
      color: Colors.grey[100],
    );
  }

  String _getLocalizedConditionLabel() {
    final val = widget.product.condition;
    if (['Panen Baru', 'Kering', 'Bibit'].contains(val)) return 'Status Panen';
    if (['Siap Saji', 'Frozen', 'Kering'].contains(val)) return 'Kesegaran';
    return 'Kondisi';
  }

  Widget _buildDetailsAndDescription() {
    final p = widget.product;
    final type = p.productType;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spesifikasi ${type == 'BARANG' ? 'Produk' : type == 'JASA' ? 'Layanan' : type == 'RENTAL' ? 'Sewa' : 'Wisata'}',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Shared Specs
          _buildSpecRow(_getLocalizedConditionLabel(), p.condition),
          if (p.brand.isNotEmpty && type == 'BARANG') _buildSpecRow('Merek', p.brand),
          if (p.sku.isNotEmpty && type == 'BARANG') _buildSpecRow('SKU', p.sku),
          _buildSpecRow('Min. Pesanan', '${p.minOrder} Unit'),

          // Modular Specs
          if (type == 'BARANG') ...[
            _buildSpecRow('Berat', '${p.weight.toInt()} gram'),
            if (p.length > 0) _buildSpecRow('Dimensi', '${p.length}x${p.width}x${p.height} cm'),
          ],
          
          // Dynamic Metadata Specs
          ..._metadata.entries.map((entry) {
            String label = entry.key.replaceAll('_', ' ').capitalizeFirst ?? entry.key;
            
            // Custom label mapping for better UI
            final labelMap = {
              'cook_time': 'Estimasi Masak',
              'spicy_level': 'Level Pedas',
              'luas_area': 'Luas Kamar',
              'fasilitas': 'Fasilitas',
              'fasum': 'Fasilitas Umum',
              'meeting_point': 'Titik Kumpul',
              'ada_kedai': 'Kedai Makan',
              'durasi_sewa': 'Durasi Sewa',
              'uang_jaminan': 'Uang Jaminan',
              'area_layanan': 'Area Layanan',
              'jam_operasional': 'Jam Operasional',
            };
            
            if (labelMap.containsKey(entry.key)) {
              label = labelMap[entry.key]!;
            }

            String value = entry.value.toString();
            if (entry.value is bool) {
              value = (entry.value as bool) ? 'Tersedia' : 'Tidak Ada';
            } else if (entry.key.contains('price') || entry.key.contains('jaminan') || entry.key.contains('deposit')) {
              value = _api.formatCurrency((entry.value as num).toDouble());
            } else if (entry.value is List) {
              value = (entry.value as List).join(', ');
            } else if (entry.key == 'cook_time') {
              value = '$value Menit';
            }

            return _buildSpecRow(label, value);
          }),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          Text(
            'Deskripsi Produk',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isDescriptionExpanded || widget.product.description.length <= 200
                ? widget.product.description
                : '${widget.product.description.substring(0, 200)}...',
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
          if (widget.product.description.length > 200)
            GestureDetector(
              onTap: () => setState(
                () => _isDescriptionExpanded = !_isDescriptionExpanded,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _isDescriptionExpanded ? 'Tutup Deskripsi' : 'Baca Selengkapnya',
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    final store = widget.product.store;
    if (store == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage: store.imageUrl.isNotEmpty
                    ? NetworkImage(_api.getImageUrl(store.imageUrl))
                    : null,
                child: store.imageUrl.isEmpty
                    ? const Icon(Icons.store_rounded, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.to(() => StoreDetailScreen(storeId: store.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            store.name.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (store.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.address.isNotEmpty
                                ? store.address
                                : 'Kota Taliwang',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Obx(() => ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _storeController.toggleFollow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _storeController.isFollowing.value ? Colors.grey[100] : AppColors.primary,
                  foregroundColor: _storeController.isFollowing.value ? Colors.grey[700] : Colors.white,
                  elevation: 0,
                  minimumSize: const Size(90, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _storeController.isFollowing.value ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
                  ),
                ),
                child: Text(
                  _storeController.isFollowing.value ? 'Mengikuti' : 'Ikuti',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Obx(() {
                final s = _storeController.storeDetail.value?.store ?? store;
                return _buildStoreStat(
                  Icons.star_rounded, 
                  s.rating.toStringAsFixed(1), 
                  '0.0'
                );
              }),
              _buildVerticalDivider(),
              Obx(() => _buildStoreStat(
                Icons.person_add_alt_1_outlined,
                '${_storeController.storeDetail.value?.followerCount ?? 0} Pengikut',
                '0 Pengikut',
              )),
              _buildVerticalDivider(),
              Obx(() {
                final s = _storeController.storeDetail.value?.store ?? store;
                return _buildStoreStat(
                  Icons.shopping_bag_outlined,
                  '${s.productCount} Produk',
                  '0 Produk',
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStat(IconData icon, String value, String fallback) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 18),
        const SizedBox(width: 6),
        Text(
          value != "0.0" && value != "0 Produk" ? value : fallback,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lainnya di toko ini',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Lihat semua',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              _api.getImageUrl(widget.product.imageUrl),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _api.formatCurrency(widget.product.price),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 10,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Kota Taliwang',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penilaian Produk',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.product.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                        ),
                        itemCount: 5,
                        itemSize: 18.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.rating.toStringAsFixed(1)} / 5.0',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Obx(() {
                if (_controller.canReview.value) {
                  return TextButton.icon(
                    onPressed: _showReviewDialog,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Tulis Ulasan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          Obx(() {
            if (_controller.isLoadingReviews.value) {
              return _buildReviewShimmer();
            }
            
            if (_controller.reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.reviews_outlined, color: Colors.grey[300], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada ulasan untuk produk ini',
                        style: GoogleFonts.manrope(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: _controller.reviews.map((r) => _buildReviewItem(r)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewShimmer() {
    return Column(
      children: List.generate(2, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: double.infinity, height: 12, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 150, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    final user = review.user;
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[100],
            backgroundImage: hasAvatar
                ? NetworkImage(_api.getImageUrl(avatarUrl))
                : null,
            child: !hasAvatar
                ? const Icon(Icons.person_rounded, size: 20, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${user?.firstName ?? 'Warga'} ${user?.lastName ?? 'KSB'}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(review.createdAt),
                      style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RatingBarIndicator(
                  rating: review.rating.toDouble(),
                  itemBuilder: (context, index) => const Icon(
                    Icons.star_rounded,
                    color: Colors.orange,
                  ),
                  itemCount: 5,
                  itemSize: 14.0,
                  direction: Axis.horizontal,
                ),
                const SizedBox(height: 8),
                Text(
                  review.comment,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    int currentRating = 5;
    final commentController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagaimana produk ini menurut Anda?',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Colors.orange,
                ),
                onRatingUpdate: (val) {
                  HapticFeedback.lightImpact();
                  currentRating = val.toInt();
                },
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: commentController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tuliskan ulasan jujur Anda di sini (kualitas produk, packing, dll)...',
                hintStyle: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (commentController.text.trim().isEmpty) {
                    AppAlert.info('Komentar Kosong', 'Berikan sedikit komentar untuk warga KSB lainnya.');
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  Get.back(); // Close bottom sheet
                  await _controller.submitReview(currentRating, commentController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Kirim Ulasan',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatSold(int sold) {
    if (sold >= 1000) {
      return '${(sold / 1000).toStringAsFixed(1)}k';
    }
    return '$sold';
  }

  void _handleChat() async {
    if (!AuthUtils.isLoggedIn) {
      AppAlert.info('Login Diperlukan', 'Silakan login untuk memulai percakapan dengan penjual');
      return;
    }

    final store = widget.product.store;
    if (store == null) return;

    // Show loading indicator
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final convData = await _api.startConversation(store.userId);
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


  Widget _buildBottomAction() {
    final type = widget.product.productType;
    
    String mainBtnLabel = 'Beli Sekarang';
    if (type == 'JASA') mainBtnLabel = 'Pesan Sekarang';
    if (type == 'RENTAL') mainBtnLabel = 'Sewa Sekarang';
    if (type == 'WISATA') mainBtnLabel = 'Booking Sekarang';

    return Obx(() {
      // Accessing observables to satisfy GetX dependency tracking
      _controller.selectedVariant.value;
      _controller.quantity.value;
      final needsVariant = widget.product.variants.isNotEmpty && _controller.selectedVariant.value == null;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleChat,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (type == 'BARANG') ...[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _controller.addToCart,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: needsVariant ? Colors.grey[300]! : AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keranjang',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: needsVariant ? Colors.grey[400] : AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: type == 'BARANG' ? 1 : 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _controller.buyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: needsVariant && type == 'BARANG' ? Colors.grey[300] : AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      mainBtnLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
