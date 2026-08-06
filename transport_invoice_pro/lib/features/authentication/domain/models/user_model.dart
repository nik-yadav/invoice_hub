import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Domain model representing an authenticated user in Transport Invoice Pro.
class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? companyName;
  final String? phone;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.companyName,
    this.phone,
    this.createdAt,
  });

  /// Factory constructor to map from Supabase User object and user_metadata.
  factory UserModel.fromSupabaseUser(supabase.User user) {
    final metadata = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata['full_name'] as String?,
      companyName: metadata['company_name'] as String?,
      phone: user.phone ?? (metadata['phone'] as String?),
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  /// Factory constructor to map from JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      companyName: json['company_name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  /// Converts UserModel to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'company_name': companyName,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Creates a copy of UserModel with modified fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? companyName,
    String? phone,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
