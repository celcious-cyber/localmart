class DriverModel {
  final int id;
  final int userId;
  final String vehicleType;
  final String plateNumber;
  final String phoneNumber;
  final bool isOnline;
  final double balance;
  final String status;
  final bool isActive;

  DriverModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.plateNumber,
    required this.phoneNumber,
    required this.isOnline,
    required this.balance,
    required this.status,
    required this.isActive,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      userId: json['user_id'],
      vehicleType: json['vehicle_type'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isOnline: json['is_online'] ?? false,
      balance: (json['balance'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'plate_number': plateNumber,
      'phone_number': phoneNumber,
      'is_online': isOnline,
      'balance': balance,
      'is_active': isActive,
    };
  }
}
