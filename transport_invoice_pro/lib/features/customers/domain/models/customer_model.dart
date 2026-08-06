import 'package:uuid/uuid.dart';

class CustomerModel {
  final String id;
  final String customerName;
  final String phone;
  final String gstin;
  final String address;
  final String city;
  final String state;
  final String pin;

  CustomerModel({
    String? id,
    required this.customerName,
    required this.phone,
    required this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.pin,
  }) : id = id ?? const Uuid().v4();

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String?,
      customerName: json['customer_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pin: json['pin'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'phone': phone,
      'gstin': gstin,
      'address': address,
      'city': city,
      'state': state,
      'pin': pin,
    };
  }

  CustomerModel copyWith({
    String? customerName,
    String? phone,
    String? gstin,
    String? address,
    String? city,
    String? state,
    String? pin,
  }) {
    return CustomerModel(
      id: id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pin: pin ?? this.pin,
    );
  }
}
