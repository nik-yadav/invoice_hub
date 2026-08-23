import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/list_skeleton_widget.dart';
import '../../domain/models/firm_model.dart';
import '../providers/firm_provider.dart';

class FirmListScreen extends ConsumerWidget {
  const FirmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firmsState = ref.watch(filteredFirmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firms'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SearchBar(
              hintText: 'Search firms...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                ref.read(firmSearchQueryProvider.notifier).state = value;
              },
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(AppColors.surfaceLight),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.addFirm),
        icon: const Icon(Icons.business),
        label: const Text('Add Firm'),
      ),
      body: firmsState.when(
        data: (firms) {
          if (firms.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.business_outlined,
              title: 'No firms found',
              description: 'You haven\'t added any firm profiles yet, or your search yielded no results.',
              actionLabel: 'Add Firm',
              onActionPressed: () => context.pushNamed(RouteNames.addFirm),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: firms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final firm = firms[index];
              return _FirmCard(firm: firm);
            },
          );
        },
        loading: () => const ListSkeletonWidget(),
        error: (err, st) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.read(firmsProvider.notifier).loadFirms(),
        ),
      ),
    );
  }
}

class _FirmCard extends ConsumerWidget {
  final FirmModel firm;

  const _FirmCard({required this.firm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // Open firm details or edit
          context.pushNamed(RouteNames.editFirm, extra: firm);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            firm.businessName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (firm.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryCyan,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GSTIN: ${firm.gstin}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${firm.city}, ${firm.state}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryLight,
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
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondaryLight),
                itemBuilder: (context) => [
                  if (!firm.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'default') {
                    ref.read(firmsProvider.notifier).updateFirm(firm.copyWith(isDefault: true));
                  } else if (value == 'edit') {
                    context.pushNamed(RouteNames.editFirm, extra: firm);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, ref);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Firm'),
        content: const Text('Are you sure you want to delete this firm? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(firmsProvider.notifier).deleteFirm(firm.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
