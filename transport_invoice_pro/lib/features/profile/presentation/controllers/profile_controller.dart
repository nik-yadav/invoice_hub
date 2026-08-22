import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../data/datasources/profile_local_data_source.dart';
import '../../domain/models/user_profile_model.dart';

/// Provider for ProfileLocalDataSource.
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

/// Controller managing user profile state, API sync, and local storage.
class ProfileController extends StateNotifier<UserProfileModel> {
  final ProfileLocalDataSource _localDataSource;

  ProfileController({required ProfileLocalDataSource localDataSource})
      : _localDataSource = localDataSource,
        super(localDataSource.getProfile()) {
    _loadProfileFromApi();
  }

  Future<void> _loadProfileFromApi() async {
    try {
      final response = await ApiService.get('/profile');
      if (response['success'] == true && response['data'] != null) {
        final profile = UserProfileModel.fromJson(Map<String, dynamic>.from(response['data']));
        state = profile;
        await _localDataSource.saveProfile(profile);
      }
    } catch (_) {}
  }

  /// Update profile details in API memory and Hive local storage.
  Future<void> updateProfile({
    required String fullName,
    required String companyName,
    required String email,
    required String phone,
    required String gstin,
    required String address,
    required String transportLicense,
    bool? enablePostOfficeSelection,
  }) async {
    final updated = state.copyWith(
      fullName: fullName,
      companyName: companyName,
      email: email,
      phone: phone,
      gstin: gstin,
      address: address,
      transportLicense: transportLicense,
      enablePostOfficeSelection: enablePostOfficeSelection ?? state.enablePostOfficeSelection,
    );
    state = updated;
    await _localDataSource.saveProfile(updated);

    try {
      await ApiService.put('/profile', updated.toJson());
    } catch (_) {}
  }

  /// Toggle post office selection preference.
  Future<void> togglePostOfficeSelection(bool enabled) async {
    final updated = state.copyWith(enablePostOfficeSelection: enabled);
    state = updated;
    await _localDataSource.saveProfile(updated);

    try {
      await ApiService.put('/profile', updated.toJson());
    } catch (_) {}
  }
}

/// Riverpod provider delivering active UserProfileModel.
final profileControllerProvider =
    StateNotifierProvider<ProfileController, UserProfileModel>((ref) {
  final dataSource = ref.watch(profileLocalDataSourceProvider);
  return ProfileController(localDataSource: dataSource);
});
