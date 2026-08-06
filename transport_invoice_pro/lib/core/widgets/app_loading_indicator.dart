import 'package:flutter/material.dart';

/// Reusable adaptive loading indicator widget.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator.adaptive(
        strokeWidth: strokeWidth,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
      ),
    );
  }
}
