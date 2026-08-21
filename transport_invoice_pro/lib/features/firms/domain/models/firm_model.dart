import 'package:uuid/uuid.dart';

class FirmModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String gstin;
  final String pan;
  final String address;
  final String city;
  final String state;
  final String pin;
  final String? logoPath;
  final String? signaturePath;
  final bool isDefault;

  FirmModel({
    String? id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.pan,
    required this.address,
    required this.city,
    required this.state,
    required this.pin,
    this.logoPath,
    this.signaturePath,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  factory FirmModel.fromJson(Map<String, dynamic> json) {
    return FirmModel(
      id: json['id'] as String?,
      businessName: (json['businessName'] ?? json['business_name'] ?? '') as String,
      ownerName: (json['ownerName'] ?? json['owner_name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      gstin: (json['gstin'] ?? '') as String,
      pan: (json['pan'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      pin: (json['pin'] ?? '') as String,
      logoPath: json['logoPath'] as String? ?? json['logo_path'] as String?,
      signaturePath: json['signaturePath'] as String? ?? json['signature_path'] as String?,
      isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'business_name': businessName,
      'ownerName': ownerName,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'pan': pan,
      'address': address,
      'city': city,
      'state': state,
      'pin': pin,
      'logoPath': logoPath,
      'logo_path': logoPath,
      'signaturePath': signaturePath,
      'signature_path': signaturePath,
      'isDefault': isDefault,
      'is_default': isDefault,
    };
  }

  FirmModel copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? email,
    String? gstin,
    String? pan,
    String? address,
    String? city,
    String? state,
    String? pin,
    String? logoPath,
    String? signaturePath,
    bool? isDefault,
  }) {
    return FirmModel(
      id: id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pin: pin ?? this.pin,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
