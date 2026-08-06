import '../models/user_model.dart';

/// Abstract contract for Authentication repository operations.
abstract class AuthRepository {
  /// Authenticate user using email and password.
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Register new user with email, password, and profile metadata.
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? companyName,
    String? phone,
  });

  /// Send password reset link to specified email address.
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Sign out currently authenticated user.
  Future<void> logout();

  /// Retrieve currently signed-in user or null.
  UserModel? get currentUser;

  /// Stream of authentication state changes.
  Stream<UserModel?> get authStateChanges;
}
