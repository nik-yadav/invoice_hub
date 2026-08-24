import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Service managing Hive local database boxes and offline storage operations.
class HiveService {
  HiveService._();

  static bool _isInitialized = false;

  /// Retrieves or generates a secure 256-bit encryption key stored in Keystore/Keychain.
  static Future<List<int>> _getOrCreateEncryptionKey() async {
    const secureStorage = FlutterSecureStorage();
    const keyName = 'hive_encryption_key';
    
    final containsKey = await secureStorage.containsKey(key: keyName);
    if (!containsKey) {
      final newKey = Hive.generateSecureKey();
      await secureStorage.write(
        key: keyName,
        value: base64UrlEncode(newKey),
      );
    }
    
    final base64Key = await secureStorage.read(key: keyName);
    return base64Url.decode(base64Key!);
  }

  /// Initializes Hive for Flutter and opens default application boxes.
  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    final encryptionKey = await _getOrCreateEncryptionKey();
    final encryptionCipher = HiveAesCipher(encryptionKey);

    // Helper to open a box securely, resetting it if decryption fails (e.g. on key mismatch or corruption)
    Future<Box<T>> openSecureBox<T>(String boxName, HiveAesCipher cipher) async {
      try {
        return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      } catch (e) {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      }
    }

    // Open critical app storage boxes (encrypting sensitive user session and data)
    await Future.wait([
      Hive.openBox(AppConstants.appSettingsBox), // settings don't need encryption
      openSecureBox(AppConstants.userSessionBox, encryptionCipher),
      openSecureBox(AppConstants.offlineInvoicesBox, encryptionCipher),
      openSecureBox(AppConstants.vehicleCacheBox, encryptionCipher),
      openSecureBox(AppConstants.firmsBox, encryptionCipher),
      openSecureBox(AppConstants.customersBox, encryptionCipher),
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
