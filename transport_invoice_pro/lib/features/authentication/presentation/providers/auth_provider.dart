import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/database/supabase_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider for AuthRemoteDataSource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(supabaseClient: SupabaseService.client);
});

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// StreamProvider listening for Supabase auth state changes.
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Provider returning current authenticated UserModel or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

/// Controller managing Authentication state, loading, and exception handling.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(null));

  /// Perform User Sign In.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e is supabase.AuthException ? e.message : e.toString(), st);
      return false;
    }
  }

  /// Perform User Registration.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? companyName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        companyName: companyName,
        phone: phone,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e is supabase.AuthException ? e.message : e.toString(), st);
      return false;
    }
  }

  /// Request Password Reset Email.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e is supabase.AuthException ? e.message : e.toString(), st);
      return false;
    }
  }

  /// Request Resending Verification Email.
  Future<bool> resendVerificationEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resendVerificationEmail(email: email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e is supabase.AuthException ? e.message : e.toString(), st);
      return false;
    }
  }

  /// Perform User Sign Out.
  Future<bool> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e is supabase.AuthException ? e.message : e.toString(), st);
      return false;
    }
  }
}

/// Provider for AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository);
});
