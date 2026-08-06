import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';

/// Reusable Placeholder Tab for unimplemented features in the Dashboard
class PlaceholderTabScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback? onAction;
  final String? actionText;

  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onAction != null && actionText != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(actionText!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
