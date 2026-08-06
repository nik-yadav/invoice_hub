import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/widgets/app_card.dart';

/// Responsive card container for authentication form bodies.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing20,
          vertical: UIConstants.spacing24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppCard(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: child,
          ),
        ),
      ),
    );
  }
}
