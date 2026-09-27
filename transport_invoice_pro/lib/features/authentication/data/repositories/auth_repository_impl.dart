import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Concrete implementation of AuthRepository.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    return _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? companyName,
    String? phone,
  }) async {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
      companyName: companyName,
      phone: phone,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _remoteDataSource.resetPasswordForEmail(email: email);
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    await _remoteDataSource.resendVerificationEmail(email: email);
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.signOut();
  }

  @override
  UserModel? get currentUser {
    return _remoteDataSource.currentSupabaseUser;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _remoteDataSource.authUserChanges;
  }
}
