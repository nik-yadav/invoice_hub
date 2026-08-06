import 'package:flutter/material.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/widgets/app_card.dart';

/// Premium metric card presenting key performance metrics.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.gradientStart,
    required this.gradientEnd,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        decoration: BoxDecoration(
          borderRadius: UIConstants.borderRadiusMedium,
          gradient: LinearGradient(
            colors: [
              gradientStart.withOpacity(0.12),
              gradientEnd.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: UIConstants.borderRadiusSmall,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacing12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: UIConstants.spacing6 ?? 6.0),
            Row(
              children: [
                Icon(
                  isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 16,
                  color: isTrendPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isTrendPositive ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
