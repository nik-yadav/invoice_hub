import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/list_skeleton_widget.dart';
import '../../domain/models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(customerSearchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Search customer name, phone, or GSTIN...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
                  suffixIcon: ref.watch(customerSearchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            ref.read(customerSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.addCustomer),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
      body: customersState.when(
        data: (customers) {
          if (customers.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'No customers found',
              description: 'It looks like you haven\'t added any customers yet or your search didn\'t match any results.',
              actionLabel: 'Add Customer',
              onActionPressed: () => context.pushNamed(RouteNames.addCustomer),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return _CustomerCard(customer: customer);
            },
          );
        },
        loading: () => const ListSkeletonWidget(),
        error: (err, st) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.read(customersProvider.notifier).loadCustomers(),
        ),
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final CustomerModel customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          context.pushNamed(RouteNames.editCustomer, extra: customer);
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
                  color: AppColors.secondaryCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.customerName.isNotEmpty ? customer.customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.surfaceLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${customer.city}, ${customer.state}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.surfaceLight,
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
                  if (value == 'edit') {
                    context.pushNamed(RouteNames.editCustomer, extra: customer);
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
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(customersProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
