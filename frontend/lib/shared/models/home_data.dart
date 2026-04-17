import 'store_models.dart';

class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final String position;
  final int sortOrder;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    required this.position,
    required this.sortOrder,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'] ?? '',
      position: json['position'] ?? 'top',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String iconName;
  final String type;
  final String serviceType;
  final int sortOrder;
  final bool isActive;
  final List<ProductModel> products;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconName,
    required this.type,
    required this.serviceType,
    required this.sortOrder,
    required this.isActive,
    required this.products,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconName: json['icon_name'] ?? '',
      type: json['type'] ?? 'BARANG',
      serviceType: json['service_type'] ?? 'mart',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      products: (json['products'] as List?)
              ?.map((p) => ProductModel.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class ProductImageModel {
  final int id;
  final String imageUrl;

  ProductImageModel({required this.id, required this.imageUrl});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'image_url': imageUrl};
}

class ProductModel {
  final int id;
  final int categoryId;
  final int storeId;
  final List<StoreCategoryModel> storeCategories;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final int sold;
  final double rating;
  final int reviewCount;
  final double weight;
  final int length;
  final int width;
  final int height;
  final String condition;
  final String brand;
  final String sku;
  final int minOrder;
  final String productType;
  final String metadata;
  final String serviceType;
  final bool isActive;
  final bool isFresh;
  final bool isFeatured;
  final bool isLocalGem;
  final List<ProductImageModel> images;
  final List<ProductVariantModel> variants;
  final StoreModel? store;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.storeId,
    this.storeCategories = const [],
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.stock = 0,
    this.sold = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.weight = 0,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.condition = 'Baru',
    this.brand = '',
    this.sku = '',
    this.minOrder = 1,
    this.productType = 'BARANG',
    this.serviceType = 'mart',
    this.metadata = '{}',
    this.isActive = true,
    this.isFresh = false,
    this.isFeatured = false,
    this.isLocalGem = false,
    this.images = const [],
    this.variants = const [],
    this.store,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      storeCategories: (json['store_categories'] as List?)
          ?.map((e) => StoreCategoryModel.fromJson(e))
          .toList() ??
          [],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] ?? 0,
      sold: json['sold'] ?? 0,
      isActive: json['is_active'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      length: json['length'] ?? 0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      condition: json['condition'] ?? 'Baru',
      brand: json['brand'] ?? '',
      sku: json['sku'] ?? '',
      minOrder: json['min_order'] ?? 1,
      productType: json['product_type'] ?? 'BARANG',
      serviceType: json['service_type'] ?? 'mart',
      metadata: json['metadata'] ?? '{}',
      isFresh: json['is_fresh'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isLocalGem: json['is_local_gem'] ?? false,
      images: (json['images'] as List?)
          ?.map((e) => ProductImageModel.fromJson(e))
          .toList() ??
          [],
      variants: (json['variants'] as List?)
          ?.map((e) => ProductVariantModel.fromJson(e))
          .toList() ??
          [],
      store: json['store'] != null ? StoreModel.fromJson(json['store']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'store_categories': storeCategories.map((e) => e.toJson()).toList(),
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'store_id': storeId,
      'stock': stock,
      'sold': sold,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'is_fresh': isFresh,
      'is_featured': isFeatured,
      'is_local_gem': isLocalGem,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'condition': condition,
      'brand': brand,
      'sku': sku,
      'min_order': minOrder,
      'product_type': productType,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'images': images.map((i) => i.toJson()).toList(),
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}

class ProductVariantModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int stock;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }
}

class SectionModel {
  final int id;
  final String key;
  final String title;
  final int sortOrder;
  final bool isActive;

  SectionModel({
    required this.id,
    required this.key,
    required this.title,
    required this.sortOrder,
    required this.isActive,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class DiscoveryTabModel {
  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;

  DiscoveryTabModel({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  factory DiscoveryTabModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryTabModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class ModuleDiscoveryModel {
  final String name;
  final String? discoveryTitle;
  final String slug;
  final List<CategoryModel> categories;
  final List<ProductModel> products;

  ModuleDiscoveryModel({
    required this.name,
    this.discoveryTitle,
    required this.slug,
    required this.categories,
    required this.products,
  });

  factory ModuleDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return ModuleDiscoveryModel(
      name: json['name'] ?? '',
      discoveryTitle: json['discovery_title'],
      slug: json['slug'] ?? '',
      categories: (json['categories'] as List?)
              ?.map((c) => CategoryModel.fromJson(c))
              .toList() ??
          [],
      products: (json['products'] as List?)
              ?.map((p) => ProductModel.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class HomeResponseModel {
  final List<BannerModel> banners;
  final List<BannerModel> bannerSliders;
  final List<CategoryModel> categories;
  final List<SectionModel> sections;
  final List<DiscoveryTabModel> discoveryTabs;
  final List<ModuleDiscoveryModel> modules;

  HomeResponseModel({
    required this.banners,
    required this.bannerSliders,
    required this.categories,
    required this.sections,
    required this.discoveryTabs,
    required this.modules,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) {
    return HomeResponseModel(
      banners: (json['banners'] as List?)
              ?.map((b) => BannerModel.fromJson(b))
              .toList() ??
          [],
      bannerSliders: (json['banner_sliders'] as List?)
              ?.map((b) => BannerModel.fromJson(b))
              .toList() ??
          [],
      categories: (json['categories'] as List?)
              ?.map((c) => CategoryModel.fromJson(c))
              .toList() ??
          [],
      sections: (json['sections'] as List?)
              ?.map((s) => SectionModel.fromJson(s))
              .toList() ??
          [],
      discoveryTabs: (json['discovery_tabs'] as List?)
              ?.map((t) => DiscoveryTabModel.fromJson(t))
              .toList() ??
          [],
      modules: (json['modules'] as List?)
              ?.map((m) => ModuleDiscoveryModel.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class CartItemModel {
  final int id;
  final int userId;
  final int productId;
  final int? variantId;
  final int quantity;
  final DateTime createdAt;
  final ProductModel? product;
  final ProductVariantModel? variant;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.createdAt,
    this.product,
    this.variant,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      variantId: json['variant_id'],
      quantity: json['quantity'] ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      variant: json['variant'] != null ? ProductVariantModel.fromJson(json['variant']) : null,
    );
  }
}
