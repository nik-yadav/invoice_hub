import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

/// Production-ready customizable button widget.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final VoidCallback? effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          AppLoadingIndicator(
            size: 20,
            color: variant == AppButtonVariant.primary ? Colors.white : theme.colorScheme.primary,
          ),
          const SizedBox(width: UIConstants.spacing8),
        ] else if (icon != null) ...[
          Icon(icon, size: UIConstants.iconSizeSmall),
          const SizedBox(width: UIConstants.spacing8),
        ],
        Text(text),
      ],
    );

    Widget buttonWidget;

    switch (variant) {
      case AppButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(width ?? 64.0, height),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.secondary:
        buttonWidget = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(width ?? 64.0, height),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.outlined:
        buttonWidget = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(width ?? 64.0, height),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.text:
        buttonWidget = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(width ?? 64.0, height),
          ),
          child: child,
        );
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: buttonWidget,
    );
  }
}
