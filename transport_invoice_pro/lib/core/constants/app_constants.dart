import '../../app/app_env.dart';

/// Global application constants.
class AppConstants {
  AppConstants._();

  static String get appName => AppEnv.appName;
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  /// Dynamic copyright notice updating automatically per calendar year
  static String get copyrightNotice => '© ${DateTime.now().year} $appName. All rights reserved.';
  
  // Support & Company Details Defaults
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';
  static const String supportEmail = 'support@transportinvoicepro.com';
  
  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String logoDarkPath = 'assets/images/logo_dark.png';
  static const String placeholderImagePath = 'assets/images/placeholder.png';
  
  // Local Storage Box Names
  static const String appSettingsBox = 'app_settings';
  static const String userSessionBox = 'user_session';
  static const String offlineInvoicesBox = 'offline_invoices';
  static const String vehicleCacheBox = 'vehicle_cache';
  static const String firmsBox = 'firms_cache';
  static const String customersBox = 'customers_cache';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);
}
