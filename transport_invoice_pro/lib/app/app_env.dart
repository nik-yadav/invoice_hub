import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Environment configuration for Transport Invoice Pro.
/// Holds runtime credentials, API endpoints, and feature flags.
enum AppEnvironment { dev, staging, prod }

class AppEnv {
  static late AppEnvironment currentEnvironment;
  static late String supabaseUrl;
  static late String supabaseAnonKey;
  static late String apiBaseUrl;
  static late String appName;
  static late bool enableLogging;

  /// Initializes the application environment variables.
  static void initialize({
    AppEnvironment environment = AppEnvironment.dev,
    String? customSupabaseUrl,
    String? customSupabaseAnonKey,
    String? customApiBaseUrl,
  }) {
    currentEnvironment = environment;
    appName = 'Transport Invoice Pro';
    enableLogging = kDebugMode;

    // Detect appropriate host for backend API
    final defaultHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

    switch (environment) {
      case AppEnvironment.dev:
        supabaseUrl = customSupabaseUrl ?? 'https://vbprsmfretgcwfjcomux.supabase.co';
        supabaseAnonKey = customSupabaseAnonKey ?? 'dev-anon-key-placeholder';
        apiBaseUrl = customApiBaseUrl ?? 'http://$defaultHost:3001/api/v1';
        break;
      case AppEnvironment.staging:
        supabaseUrl = customSupabaseUrl ?? 'https://staging.supabase.co';
        supabaseAnonKey = customSupabaseAnonKey ?? 'staging-anon-key-placeholder';
        apiBaseUrl = customApiBaseUrl ?? 'https://staging-api.transportinvoicepro.com/api/v1';
        break;
      case AppEnvironment.prod:
        supabaseUrl = customSupabaseUrl ?? 'https://prod.supabase.co';
        supabaseAnonKey = customSupabaseAnonKey ?? 'prod-anon-key-placeholder';
        apiBaseUrl = customApiBaseUrl ?? 'https://api.transportinvoicepro.com/api/v1';
        break;
    }
  }

  static bool get isProduction => currentEnvironment == AppEnvironment.prod;
  static bool get isDevelopment => currentEnvironment == AppEnvironment.dev;
}
