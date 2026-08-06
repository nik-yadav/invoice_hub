import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';
import 'app_button.dart';

/// Reusable error presentation widget with optional retry action.
class AppErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  const AppErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: UIConstants.iconSizeLarge * 1.5,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacing8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UIConstants.spacing24),
              AppButton(
                text: retryText,
                onPressed: onRetry,
                variant: AppButtonVariant.outlined,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
