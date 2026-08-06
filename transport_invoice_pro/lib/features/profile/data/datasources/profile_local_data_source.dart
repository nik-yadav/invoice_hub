import 'dart:convert';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/user_profile_model.dart';

/// Local data source persisting profile details in Hive storage.
class ProfileLocalDataSource {
  static const String _profileKey = 'user_profile';

  /// Loads profile from Hive sessionBox. Defaults to sample profile if empty.
  UserProfileModel getProfile() {
    final rawData = HiveService.sessionBox.get(_profileKey);
    if (rawData == null) {
      final defaultProfile = UserProfileModel.defaultProfile();
      saveProfile(defaultProfile);
      return defaultProfile;
    }

    try {
      if (rawData is Map) {
        return UserProfileModel.fromJson(Map<String, dynamic>.from(rawData));
      } else if (rawData is String) {
        return UserProfileModel.fromJson(jsonDecode(rawData) as Map<String, dynamic>);
      }
      return UserProfileModel.defaultProfile();
    } catch (_) {
      return UserProfileModel.defaultProfile();
    }
  }

  /// Saves updated profile to Hive sessionBox.
  Future<void> saveProfile(UserProfileModel profile) async {
    await HiveService.sessionBox.put(_profileKey, profile.toJson());
  }
}
