import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Toast Notification Utility providing clean feedback banners across the application.
class AppToast {
  AppToast._();

  /// Show Success Toast Notification.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: Colors.green.shade700,
    );
  }

  /// Show Error Toast Notification.
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.error,
    );
  }

  /// Show Info Toast Notification.
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.primaryBlue,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
