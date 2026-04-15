import 'home_data.dart';
import 'user_model.dart';

class StoreDashboardModel {
  final double balance;
  final int totalOrders;
  final double totalSales;
  final int pendingOrders;
  final List<ProductModel> topProducts;
  final StoreModel store;

  StoreDashboardModel({
    required this.balance,
    required this.totalOrders,
    required this.totalSales,
    required this.pendingOrders,
    required this.topProducts,
    required this.store,
  });

  factory StoreDashboardModel.fromJson(Map<String, dynamic> json) {
    return StoreDashboardModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      pendingOrders: json['pending_orders'] ?? 0,
      topProducts: (json['top_products'] as List?)
              ?.map((p) => ProductModel.fromJson(p))
              .toList() ??
          [],
      store: StoreModel.fromJson(json['store'] ?? {}),
    );
  }
}

class StoreModel {
  final int id;
  final int userId;
  final String name;
  final String category;
  final String description;
  final String address;
  final String imageUrl;
  final double balance;
  final String status;
  final String level;
  final double latitude;
  final double longitude;
  final String village;
  final String district;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int productCount;
  final bool isActive;

  StoreModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.imageUrl,
    required this.balance,
    required this.status,
    required this.level,
    required this.latitude,
    required this.longitude,
    this.village = '',
    this.district = '',
    this.isVerified = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.productCount = 0,
    required this.isActive,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['image_url'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      level: json['level'] ?? 'regular',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      isVerified: json['is_verified'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      productCount: json['product_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class OrderModel {
  final int id;
  final int userId;
  final int storeId;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String address;
  final DateTime createdAt;
  final UserModel? user;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.address,
    required this.createdAt,
    this.user,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      address: json['address'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      items: (json['items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class OrderItemModel {
  final int id;
  final int productId;
  final int quantity;
  final double price;
  final ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
    );
  }
}
