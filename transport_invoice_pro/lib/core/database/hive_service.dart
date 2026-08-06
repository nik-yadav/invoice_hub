import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Service managing Hive local database boxes and offline storage operations.
class HiveService {
  HiveService._();

  static bool _isInitialized = false;

  /// Initializes Hive for Flutter and opens default application boxes.
  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Open critical app storage boxes
    await Future.wait([
      Hive.openBox(AppConstants.appSettingsBox),
      Hive.openBox(AppConstants.userSessionBox),
      Hive.openBox(AppConstants.offlineInvoicesBox),
      Hive.openBox(AppConstants.vehicleCacheBox),
      Hive.openBox(AppConstants.firmsBox),
      Hive.openBox(AppConstants.customersBox),
    ]);

    _isInitialized = true;
  }

  /// Get reference to open Box.
  static Box<T> getBox<T>(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Hive Box "$boxName" is not opened yet. Call HiveService.init() first.');
    }
    return Hive.box<T>(boxName);
  }

  /// App Settings Box helper.
  static Box get settingsBox => getBox(AppConstants.appSettingsBox);

  /// User Session Box helper.
  static Box get sessionBox => getBox(AppConstants.userSessionBox);

  /// Offline Invoices Box helper.
  static Box get offlineInvoicesBox => getBox(AppConstants.offlineInvoicesBox);

  /// Firms Box helper.
  static Box get firmsBox => getBox(AppConstants.firmsBox);

  /// Customers Box helper.
  static Box get customersBox => getBox(AppConstants.customersBox);

  /// Clears all local box data (used on logout/reset).
  static Future<void> clearAllBoxes() async {
    await Future.wait([
      settingsBox.clear(),
      sessionBox.clear(),
      offlineInvoicesBox.clear(),
      getBox(AppConstants.vehicleCacheBox).clear(),
      firmsBox.clear(),
      customersBox.clear(),
    ]);
  }
}
