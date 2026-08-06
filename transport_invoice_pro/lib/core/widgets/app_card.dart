import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

/// Reusable Material 3 Card container widget.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Container containerWidget = Container(
      padding: padding ?? const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color,
        borderRadius: UIConstants.borderRadiusMedium,
        border: border ?? Border.all(color: theme.colorScheme.outline, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: UIConstants.borderRadiusMedium,
          child: InkWell(
            onTap: onTap,
            borderRadius: UIConstants.borderRadiusMedium,
            child: containerWidget,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: containerWidget,
    );
  }
}
