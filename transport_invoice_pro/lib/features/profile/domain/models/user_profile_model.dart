import '../../../../core/services/user_session.dart';

/// Model representing the user's profile and company business details.
class UserProfileModel {
  final String fullName;
  final String companyName;
  final String email;
  final String phone;
  final String gstin;
  final String address;
  final String transportLicense;
  final String subscriptionPlan;

  const UserProfileModel({
    required this.fullName,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.address,
    required this.transportLicense,
    this.subscriptionPlan = 'Standard Plan',
  });

  /// Dynamic initial profile data derived from current user session.
  factory UserProfileModel.defaultProfile() {
    final user = UserSession.currentUser;
    return UserProfileModel(
      fullName: user?.fullName ?? '',
      companyName: user?.companyName ?? '',
      email: user?.email ?? '',
      phone: user?.phone ?? '',
      gstin: '',
      address: '',
      transportLicense: '',
      subscriptionPlan: 'Standard Plan',
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['full_name'] as String? ?? UserSession.currentUser?.fullName ?? '',
      companyName: json['company_name'] as String? ?? UserSession.currentUser?.companyName ?? '',
      email: json['email'] as String? ?? UserSession.currentUser?.email ?? '',
      phone: json['phone'] as String? ?? UserSession.currentUser?.phone ?? '',
      gstin: json['gstin'] as String? ?? '',
      address: json['address'] as String? ?? '',
      transportLicense: json['transport_license'] as String? ?? '',
      subscriptionPlan: json['subscription_plan'] as String? ?? 'Standard Plan',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'address': address,
      'transport_license': transportLicense,
      'subscription_plan': subscriptionPlan,
    };
  }

  UserProfileModel copyWith({
    String? fullName,
    String? companyName,
    String? email,
    String? phone,
    String? gstin,
    String? address,
    String? transportLicense,
    String? subscriptionPlan,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      transportLicense: transportLicense ?? this.transportLicense,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }
}
