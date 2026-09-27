import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/api_service.dart';
import '../../../../core/services/user_session.dart';
import '../../domain/models/user_model.dart';

/// Remote data source integrating with Node.js Express backend and UserSession manager.
class AuthRemoteDataSource {
  final supabase.SupabaseClient _supabaseClient;
  final StreamController<UserModel?> _userStreamController = StreamController<UserModel?>.broadcast();

  AuthRemoteDataSource({required supabase.SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  /// Authenticate user via Node.js backend (`/auth/login`) or Supabase.
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      if (response['success'] == true) {
        final token = response['token'] as String? ?? '';
        final refreshToken = response['refreshToken'] as String? ?? '';
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        await UserSession.saveSession(user, token, refreshToken);
        _userStreamController.add(user);
        return user;
      }
      throw ApiException(response['message'] ?? 'Login failed', 400);
    } catch (e) {
      try {
        final sbResponse = await _supabaseClient.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (sbResponse.user != null) {
          final user = UserModel.fromSupabaseUser(sbResponse.user!);
          final sessionToken = sbResponse.session?.accessToken ?? '';
          final sbRefreshToken = sbResponse.session?.refreshToken ?? '';
          await UserSession.saveSession(user, sessionToken, sbRefreshToken);
          _userStreamController.add(user);
          return user;
        }
      } catch (_) {}
      throw supabase.AuthException(e.toString());
    }
  }

  /// Register new user via Node.js backend (`/auth/register`) or Supabase.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? companyName,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        if (companyName != null) 'companyName': companyName.trim(),
        if (phone != null) 'phone': phone.trim(),
      });

      if (response['success'] == true) {
        final token = response['token'] as String? ?? '';
        final refreshToken = response['refreshToken'] as String? ?? '';
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        if (token.isNotEmpty) {
          await UserSession.saveSession(user, token, refreshToken);
          _userStreamController.add(user);
        }
        return user;
      }
      throw ApiException(response['message'] ?? 'Registration failed', 400);
    } catch (e) {
      try {
        final sbResponse = await _supabaseClient.auth.signUp(
          email: email.trim(),
          password: password,
          data: {
            'full_name': fullName.trim(),
            if (companyName != null) 'company_name': companyName.trim(),
            if (phone != null) 'phone': phone.trim(),
          },
        );
        if (sbResponse.user != null) {
          final user = UserModel.fromSupabaseUser(sbResponse.user!);
          final sessionToken = sbResponse.session?.accessToken ?? '';
          final sbRefreshToken = sbResponse.session?.refreshToken ?? '';
          await UserSession.saveSession(user, sessionToken, sbRefreshToken);
          _userStreamController.add(user);
          return user;
        }
      } catch (_) {}
      throw supabase.AuthException(e.toString());
    }
  }

  /// Request password reset link.
  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await ApiService.post('/auth/forgot-password', {'email': email.trim()});
    } catch (e) {
      await _supabaseClient.auth.resetPasswordForEmail(email.trim());
    }
  }

  /// Request resending email verification link.
  Future<void> resendVerificationEmail({required String email}) async {
    await ApiService.post('/auth/resend-verification', {'email': email.trim()});
  }

  /// Sign out current user session.
  Future<void> signOut() async {
    try {
      await ApiService.post('/auth/logout', {
        'refreshToken': UserSession.refreshToken ?? '',
      });
    } catch (_) {}
    await UserSession.clearSession();
    _userStreamController.add(null);
    try {
      await _supabaseClient.auth.signOut();
    } catch (_) {}
  }

  /// Stream of current auth user state changes.
  Stream<UserModel?> get authUserChanges => _userStreamController.stream;

  /// Current authenticated user.
  UserModel? get currentSupabaseUser {
    if (UserSession.currentUser != null) return UserSession.currentUser;
    final sbUser = _supabaseClient.auth.currentUser;
    if (sbUser != null) return UserModel.fromSupabaseUser(sbUser);
    return null;
  }
}
