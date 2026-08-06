import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_env.dart';

/// Supabase client service wrapper for database, auth, and storage operations.
class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;

  /// Initializes Supabase Client with environment parameters.
  static Future<void> init() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      debug: AppEnv.enableLogging,
    );

    _isInitialized = true;
  }

  /// Get active Supabase Client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current User Auth state.
  static User? get currentUser => client.auth.currentUser;

  /// Stream listening for auth state changes.
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Check if user is currently authenticated.
  static bool get isAuthenticated => currentUser != null;
}
