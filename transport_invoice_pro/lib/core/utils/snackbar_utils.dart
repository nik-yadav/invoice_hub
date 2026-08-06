import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      icon: Icons.check_circle_rounded,
      backgroundColor: Colors.green.shade800,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context,
      message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.primaryBlue,
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 4,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
