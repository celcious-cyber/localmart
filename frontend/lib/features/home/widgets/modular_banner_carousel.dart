import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/home_data.dart';

class ModularBannerCarousel extends StatefulWidget {
  final String module;
  final double height;
  final double viewportFraction;

  const ModularBannerCarousel({
    super.key,
    required this.module,
    this.height = 150,
    this.viewportFraction = 0.92,
  });

  @override
  State<ModularBannerCarousel> createState() => _ModularBannerCarouselState();
}

class _ModularBannerCarouselState extends State<ModularBannerCarousel> {
  final ApiService _api = ApiService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final banners = await _api.getBanners(position: widget.module);
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: widget.viewportFraction,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          items: _banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _api.getImageUrl(banner.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.broken_image, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == entry.key ? 20.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
