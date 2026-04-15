import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/home_data.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.product, this.heroTag});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  bool _isDescriptionExpanded = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  bool _isFollowing = false;
  ProductVariantModel? _selectedVariant;
  Map<String, dynamic> _metadata = {};

  @override
  void initState() {
    super.initState();
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
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {},
        ),
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
              GestureDetector(
                onTap: () {
                  setState(() => _isFavorited = !_isFavorited);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isFavorited ? 'Ditambahkan ke Favorit' : 'Dihapus dari Favorit'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Icon(
                  _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorited ? Colors.red : Colors.grey[400],
                  size: 28,
                ),
              ),
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
          Text(
            _api.formatCurrency(_selectedVariant?.price ?? widget.product.price),
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('${widget.product.rating}', isRating: true),
              _buildVerticalDivider(),
              _buildStatItem('${widget.product.reviewCount} Penilaian'),
              _buildVerticalDivider(),
              _buildStatItem('Terjual ${_formatSold(widget.product.sold)}'),
            ],
          ),
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

  Widget _buildStatItem(String label, {bool isRating = false}) {
    return Row(
      children: [
        if (isRating) ...[
          const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isRating ? AppColors.textPrimary : Colors.grey[600],
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.product.variants.length,
        itemBuilder: (context, index) {
          final variant = widget.product.variants[index];
          bool isSelected = _selectedVariant?.id == variant.id;

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
                setState(() {
                  _selectedVariant = selected ? variant : null;
                });
              },
              showCheckmark: false,
            ),
          );
        },
      ),
    );
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
          
          if (type == 'JASA') ...[
            if (_metadata['area_layanan'] != null) _buildSpecRow('Area Layanan', _metadata['area_layanan']),
            if (_metadata['jam_operasional'] != null) _buildSpecRow('Jam Operasional', _metadata['jam_operasional']),
          ],

          if (type == 'RENTAL') ...[
            if (_metadata['durasi_sewa'] != null) _buildSpecRow('Durasi Sewa', _metadata['durasi_sewa']),
            if (_metadata['uang_jaminan'] != null) _buildSpecRow('Uang Jaminan', _api.formatCurrency((_metadata['uang_jaminan'] as num).toDouble())),
          ],

          if (type == 'WISATA') ...[
            if (_metadata['meeting_point'] != null) _buildSpecRow('Titik Kumpul', _metadata['meeting_point']),
            if (_metadata['fasilitas'] != null) _buildSpecRow('Fasilitas', _metadata['fasilitas'] is List ? (_metadata['fasilitas'] as List).join(', ') : _metadata['fasilitas'].toString()),
          ],
          
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
              ElevatedButton(
                onPressed: () {
                  setState(() => _isFollowing = !_isFollowing);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[100] : AppColors.primary,
                  foregroundColor: _isFollowing ? Colors.grey[700] : Colors.white,
                  elevation: 0,
                  minimumSize: const Size(90, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _isFollowing ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
                  ),
                ),
                child: Text(
                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStoreStat(Icons.star_rounded, '${store.rating}', '4.0'),
              _buildVerticalDivider(),
              _buildStoreStat(
                Icons.shopping_bag_outlined,
                '${store.productCount} Produk',
                '38 Produk',
              ),
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

  String _formatSold(int sold) {
    if (sold >= 1000) {
      return '${(sold / 1000).toStringAsFixed(1)}k';
    }
    return '$sold';
  }

  void _handleChat() async {
    final store = widget.product.store;
    if (store == null) return;
    
    // Fallback phone if not provided in user object
    String phone = "6282340331000"; // Sample official LocalMart support
    
    final message = "Halo ${store.name}, saya tertarik dengan *${widget.product.name}* di LocalMart. Apakah masih tersedia?";
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
  }

  void _handleAddToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('${widget.product.name} dimasukkan ke keranjang'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            // Future: Navigate to Cart
          },
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final type = widget.product.productType;
    String mainBtnLabel = 'Beli Sekarang';
    if (type == 'JASA') mainBtnLabel = 'Pesan Jasa';
    if (type == 'RENTAL') mainBtnLabel = 'Sewa Sekarang';
    if (type == 'WISATA') mainBtnLabel = 'Booking Sekarang';

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
                    onPressed: _handleAddToCart,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
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
                        color: AppColors.primary,
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
                  onPressed: () {
                    if (type == 'BARANG') {
                      _handleAddToCart();
                    } else {
                      _handleChat(); // For Service/Rental, direct chat is better
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
  }
}
