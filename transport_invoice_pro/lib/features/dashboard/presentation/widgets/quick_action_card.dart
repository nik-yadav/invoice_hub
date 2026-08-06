import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/widgets/app_card.dart';

/// Quick Action interactive card widget for fast dashboard navigation.
class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing12),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: UIConstants.borderRadiusMedium,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: UIConstants.spacing14 ?? 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
