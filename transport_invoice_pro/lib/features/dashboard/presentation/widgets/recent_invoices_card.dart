import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';

/// Dummy data model for recent invoices.
class RecentInvoiceItem {
  final String id;
  final String clientName;
  final String route;
  final String vehicleNumber;
  final double amount;
  final DateTime date;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const RecentInvoiceItem({
    required this.id,
    required this.clientName,
    required this.route,
    required this.vehicleNumber,
    required this.amount,
    required this.date,
    required this.status,
    this.onShare,
    this.onTap,
  });
}

/// Recent Invoices data table/list card.
class RecentInvoicesCard extends StatelessWidget {
  final List<RecentInvoiceItem> invoices;
  final VoidCallback? onViewAll;

  const RecentInvoicesCard({
    super.key,
    required this.invoices,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: UIConstants.spacing8),
                  Text(
                    'Recent Invoices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
          const Divider(height: UIConstants.spacing20),
          if (invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(UIConstants.spacing24),
              child: Center(
                child: Text(
                  'No recent invoices generated today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = invoices[index];
                return InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(UIConstants.spacing10 ?? 10.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: UIConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: UIConstants.spacing12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.clientName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.id} • ${item.vehicleNumber} (${item.route})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: UIConstants.spacing8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(item.amount),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusBadge(theme, item.status),
                          ],
                        ),
                        if (item.onShare != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primaryBlue),
                            tooltip: 'Share PDF',
                            onPressed: item.onShare,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'pending':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        break;
      case 'overdue':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: UIConstants.borderRadiusCircular,
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
