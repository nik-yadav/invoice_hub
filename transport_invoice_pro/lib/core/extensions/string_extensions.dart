import '../utils/validators.dart';

/// Extension methods on String for common text manipulation and validation.
extension StringExtensions on String {
  /// Capitalize first letter of string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert string to Title Case.
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid email.
  bool get isValidEmail => Validators.validateEmail(this) == null;

  /// Check if string is a valid phone number.
  bool get isValidPhone => Validators.validatePhone(this) == null;

  /// Check if string is a valid GSTIN.
  bool get isValidGSTIN => Validators.validateGSTIN(this) == null;

  /// Check if string is a valid vehicle number.
  bool get isValidVehicleNumber => Validators.validateVehicleNumber(this) == null;
}
