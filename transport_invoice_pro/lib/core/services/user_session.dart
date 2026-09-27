import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/hive_service.dart';
import '../../features/authentication/domain/models/user_model.dart';
import 'api_service.dart';

/// Centralized Session Manager for managing user authentication state and JWT tokens.
class UserSession {
  static const String _userSessionKey = 'current_user_session';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static UserModel? _currentUser;
  static String? _token;
  static String? _refreshToken;

  /// Initialize user session on application bootstrap.
  static Future<void> init() async {
    try {
      final savedToken = HiveService.sessionBox.get(_authTokenKey) as String?;
      final savedRefreshToken = HiveService.sessionBox.get(_refreshTokenKey) as String?;
      final savedUserJson = HiveService.sessionBox.get(_userSessionKey) as String?;

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        ApiService.setAuthToken(_token);
      }

      if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
        _refreshToken = savedRefreshToken;
      }

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(savedUserJson);
        _currentUser = UserModel.fromJson(userMap);
      }
    } catch (e) {
      if (kDebugMode) print('[UserSession Init Error] $e');
    }
  }

  /// Active User model.
  static UserModel? get currentUser => _currentUser;

  /// Active JWT token string.
  static String? get token => _token;

  /// Active refresh token string.
  static String? get refreshToken => _refreshToken;

  /// Whether user is currently authenticated.
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;

  /// Update tokens in storage (used on dynamic recreate-session).
  static Future<void> updateTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    ApiService.setAuthToken(token);
    await HiveService.sessionBox.put(_authTokenKey, token);
    await HiveService.sessionBox.put(_refreshTokenKey, refreshToken);
  }

  /// Save session data after login or registration.
  static Future<void> saveSession(UserModel user, String token, String refreshToken) async {
    // Clear any cached data from previous sessions before starting new user session
    await HiveService.clearAllBoxes();

    _currentUser = user;
    _token = token;
    _refreshToken = refreshToken;

    ApiService.setAuthToken(token);

    await HiveService.sessionBox.put(_authTokenKey, token);
    await HiveService.sessionBox.put(_refreshTokenKey, refreshToken);
    await HiveService.sessionBox.put(_userSessionKey, jsonEncode(user.toJson()));
  }

  /// Clear session data on sign out.
  static Future<void> clearSession() async {
    _currentUser = null;
    _token = null;
    _refreshToken = null;

    ApiService.setAuthToken(null);

    await HiveService.clearAllBoxes();
  }
}
