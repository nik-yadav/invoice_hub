import 'package:intl/intl.dart';

/// Formatting utility methods for Transport Invoice Pro.
class Formatters {
  Formatters._();

  static String formatCurrency(
    double amount, {
    String symbol = '₹',
    String locale = 'en_IN',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Formats DateTime into readable string format (e.g. 15 Aug 2026).
  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Formats DateTime with time (e.g. 15 Aug 2026, 10:30 AM).
  static String formatDateTime(DateTime date, {String format = 'dd MMM yyyy, hh:mm a'}) {
    return DateFormat(format).format(date);
  }

  /// Formats weight value with unit (e.g. 15.50 Tonnes or 1,500 Kg).
  static String formatWeight(double weightInKg, {bool inTonnes = false}) {
    if (inTonnes) {
      final double tonnes = weightInKg / 1000.0;
      return '${tonnes.toStringAsFixed(2)} Tonnes';
    }
    final formatter = NumberFormat('#,##0.##', 'en_IN');
    return '${formatter.format(weightInKg)} Kg';
  }

  /// Formats raw invoice counter into padded string (e.g. INV-2026-0042).
  static String formatInvoiceNumber(int number, {String prefix = 'INV', int padding = 4}) {
    final year = DateTime.now().year;
    final paddedNumber = number.toString().padLeft(padding, '0');
    return '$prefix-$year-$paddedNumber';
  }
}
