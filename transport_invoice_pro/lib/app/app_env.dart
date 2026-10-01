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
  static String appName = 'Transport Invoice Pro';
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
    enableLogging = kDebugMode;

    // Detect appropriate host for backend API
    final defaultHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

    // 2. Read optional config variables from command line defines
    const defineAppName = String.fromEnvironment('APP_NAME');
    const defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const defineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');

    switch (environment) {
      case AppEnvironment.dev:
        appName = defineAppName.isNotEmpty ? defineAppName : 'Transport Invoice Pro (Dev)';
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://vbgcwfjcomux.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'dev-anon-key-placeholder');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'http://$defaultHost:3001/api/v1');
        break;
      case AppEnvironment.staging:
        appName = defineAppName.isNotEmpty ? defineAppName : 'Transport Invoice Pro (Staging)';
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://staging.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'staging-anon-key-placeholder');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'https://staging-api.transportinvoicepro.com/api/v1');
        break;
      case AppEnvironment.prod:
        appName = defineAppName.isNotEmpty ? defineAppName : 'Transport Invoice Pro';
        supabaseUrl = customSupabaseUrl ?? 
            (defineSupabaseUrl.isNotEmpty ? defineSupabaseUrl : 'https://vbprsmfretgcwfjcomux.storage.supabase.co');
        supabaseAnonKey = customSupabaseAnonKey ?? 
            (defineSupabaseAnonKey.isNotEmpty ? defineSupabaseAnonKey : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZicHJzbWZyZXRnY3dmamNvbXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU3MjU4OTMsImV4cCI6MjEwMTMwMTg5M30.sWp5N2eUN_K9xx4XWopFcX2sEp7Frt6GKpb9SxBTDKw');
        apiBaseUrl = customApiBaseUrl ?? 
            (defineApiBaseUrl.isNotEmpty ? defineApiBaseUrl : 'https://transportinvoice-api.iamnikhilyadav.sbs/api/v1');
        break;
    }
  }

  static bool get isProduction => currentEnvironment == AppEnvironment.prod;
  static bool get isStaging => currentEnvironment == AppEnvironment.staging;
  static bool get isDevelopment => currentEnvironment == AppEnvironment.dev;

  static String get environmentName {
    switch (currentEnvironment) {
      case AppEnvironment.prod:
        return 'Production';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.dev:
        return 'Development';
    }
  }

  static String get environmentBadge {
    switch (currentEnvironment) {
      case AppEnvironment.prod:
        return '';
      case AppEnvironment.staging:
        return 'STAGING';
      case AppEnvironment.dev:
        return 'DEV';
    }
  }
}
