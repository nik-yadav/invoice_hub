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
    AppEnvironment? environment,
    String? customSupabaseUrl,
    String? customSupabaseAnonKey,
    String? customApiBaseUrl,
  }) {
    // 1. Read environment name from command line
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    
    if (environment == null) {
      switch (envString) {
        case 'prod':
          environment = AppEnvironment.prod;
          break;
        case 'staging':
          environment = AppEnvironment.staging;
          break;
        case 'dev':
        default:
          environment = AppEnvironment.dev;
      }
    }

    currentEnvironment = environment;
    appName = 'Transport Invoice Pro';
    enableLogging = kDebugMode;

    // Detect appropriate host for backend API
    final defaultHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

    // 2. Read optional config variables from command line defines
    const defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const defineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');

    switch (environment) {
      case AppEnvironment.dev:
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://vbgcwfjcomux.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'dev-anon-key-placeholder');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'http://$defaultHost:3001/api/v1');
        break;
      case AppEnvironment.staging:
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://staging.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'staging-anon-key-placeholder');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'https://staging-api.transportinvoicepro.com/api/v1');
        break;
      case AppEnvironment.prod:
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://prod.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'prod-anon-key-placeholder');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'https://api.transportinvoicepro.com/api/v1');
        break;
    }
  }

  static bool get isProduction => currentEnvironment == AppEnvironment.prod;
  static bool get isDevelopment => currentEnvironment == AppEnvironment.dev;
}
