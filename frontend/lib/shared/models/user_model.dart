import 'store_models.dart';
import 'driver_model.dart';

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? gender;
  final String? birthDate;
  final StoreModel? store;
  final DriverModel? driver;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.gender,
    this.birthDate,
    this.store,
    this.driver,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      gender: json['gender'],
      birthDate: json['birth_date'],
      store: json['store'] != null ? StoreModel.fromJson(json['store']) : null,
      driver: json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'gender': gender,
      'birth_date': birthDate,
    };
  }
}
