/// Form input validation methods for Transport Invoice Pro.
class Validators {
  Validators._();

  /// Validates required text fields.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email address format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates person/owner/driver name fields (strict: letters, spaces, dots, hyphens only).
  static String? validatePersonName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    final nameRegExp = RegExp(r'^[a-zA-Z\s\.-]+$');
    if (!nameRegExp.hasMatch(trimmed)) {
      return '$fieldName can only contain letters, spaces, dots, and hyphens (no numbers or special characters)';
    }
    return null;
  }

  /// Validates transport firm/business name (letters, numbers, spaces, dots, &, -, comma allowed).
  static String? validateBusinessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Business name must be at least 2 characters';
    }
    final businessRegExp = RegExp(r'^[a-zA-Z0-9\s\.\&\-\,\/]+$');
    if (!businessRegExp.hasMatch(trimmed)) {
      return 'Business name contains invalid symbols (only letters, numbers, &, -, . allowed)';
    }
    return null;
  }

  /// Validates Indian 10-digit phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    final phoneRegExp = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegExp.hasMatch(clean)) {
      return 'Enter a valid 10-digit mobile number starting with 6-9';
    }
    return null;
  }

  /// Validates Indian GSTIN format (e.g. 22AAAAA0000A1Z5).
  static String? validateGSTIN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional unless required
    }
    final gstinRegExp = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstinRegExp.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 15-character GSTIN number';
    }
    return null;
  }

  static final Set<String> _validStateCodes = {
    'AN', 'AP', 'AR', 'AS', 'BR', 'BH', 'CH', 'CG', 'DD', 'DN', 'DL', 
    'GA', 'GJ', 'HR', 'HP', 'JK', 'JH', 'KA', 'KL', 'LA', 'LD', 'MP', 
    'MH', 'MN', 'ML', 'MZ', 'NL', 'OD', 'PY', 'PB', 'RJ', 'SK', 'TN', 
    'TS', 'TR', 'UP', 'UK', 'UA', 'WB'
  };

  /// Validates Indian Commercial Vehicle Number (e.g. MH 12 AB 1234 or UP 14 1234).
  static String? validateVehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle number is required';
    }
    final cleanValue = value.replaceAll(RegExp(r'\s+|-'), '').toUpperCase();
    
    if (cleanValue.length < 8) {
      return 'Vehicle number too short (e.g. UP 14 AB 1234)';
    }

    final stateCode = cleanValue.substring(0, 2);
    if (!_validStateCodes.contains(stateCode)) {
      return 'Invalid state code "$stateCode" (e.g. UP, HR, DL, MH)';
    }

    // Format: State (2 letters) + RTO (2 digits) + Series (0-3 letters) + Number (4 digits)
    final vehicleRegExp = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{0,3}\d{4}$');
    if (!vehicleRegExp.hasMatch(cleanValue)) {
      return 'Invalid format. Use standard format like UP 14 AB 1234 or UP 14 1234';
    }
    return null;
  }

  /// Validates numeric monetary or freight weight values.
  static String? validatePositiveNumber(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number for $fieldName';
    }
    return null;
  }

  /// Validates freight weight against max vehicle capacity.
  static String? validateWeightAgainstCapacity(String? weightValue, double? maxCapacity) {
    if (weightValue == null || weightValue.trim().isEmpty) return null;
    final enteredWeight = double.tryParse(weightValue.trim());
    if (enteredWeight == null) return 'Enter a valid weight';
    if (enteredWeight <= 0) return 'Weight must be greater than 0';

    if (maxCapacity != null && maxCapacity > 0 && enteredWeight > maxCapacity) {
      return 'Weight (${enteredWeight} Tons) exceeds vehicle max capacity (${maxCapacity} Tons)';
    }
    return null;
  }

  /// Validates that a date is not in the future.
  static String? validateDateNotFuture(DateTime? date, {String label = 'Date'}) {
    if (date == null) return null;
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (date.isAfter(todayEnd)) {
      return '$label cannot be in the future';
    }
    return null;
  }
}
