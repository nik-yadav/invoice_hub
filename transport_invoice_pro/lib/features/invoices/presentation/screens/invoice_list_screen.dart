import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/list_skeleton_widget.dart';
import '../../domain/models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import 'package:printing/printing.dart';
import '../../../customers/domain/models/customer_model.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../firms/presentation/providers/firm_provider.dart';
import '../../../vehicles/domain/models/vehicle_model.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../utils/invoice_pdf_generator.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesState = ref.watch(filteredInvoicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, ref),
          ),
        ],
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
                  final currentFilters = ref.read(invoiceFiltersProvider);
                  ref.read(invoiceFiltersProvider.notifier).state = currentFilters.copyWith(searchQuery: value);
                },
                decoration: InputDecoration(
                  hintText: 'Search invoice no., customer name, or material...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
                  suffixIcon: ref.watch(invoiceFiltersProvider).searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            final currentFilters = ref.read(invoiceFiltersProvider);
                            ref.read(invoiceFiltersProvider.notifier).state = currentFilters.copyWith(searchQuery: '');
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
        onPressed: () => context.pushNamed(RouteNames.addInvoice),
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
      ),
      body: invoicesState.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No invoices found',
              description: 'You haven\'t created any invoices yet, or your search yielded no results.',
              actionLabel: 'Create Invoice',
              onActionPressed: () => context.pushNamed(RouteNames.addInvoice),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _InvoiceCard(invoice: invoices[index]);
            },
          );
        },
        loading: () => const ListSkeletonWidget(),
        error: (err, st) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.read(invoicesProvider.notifier).loadInvoices(),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _InvoiceFilterSheet(),
    );
  }
}

class _InvoiceFilterSheet extends ConsumerWidget {
  const _InvoiceFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(invoiceFiltersProvider);
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Invoices', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  ref.read(invoiceFiltersProvider.notifier).state = InvoiceFilters(
                    searchQuery: filters.searchQuery,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('Payment Status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PaymentStatus.values.map((status) {
              final isSelected = filters.status == status;
              return ChoiceChip(
                label: Text(status.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  ref.read(invoiceFiltersProvider.notifier).state = filters.copyWith(
                    status: selected ? status : null,
                    clearStatus: !selected,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customersState = ref.watch(customersProvider);
    
    String customerName = 'Unknown Customer';
    if (customersState is AsyncData) {
      final customer = customersState.value?.where((c) => c.id == invoice.customerId).firstOrNull;
      if (customer != null) customerName = customer.customerName;
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.editInvoice, extra: invoice),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.paymentStatus.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      invoice.paymentStatus.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: invoice.paymentStatus.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(invoice.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${invoice.weight ?? 'N/A'} Tons',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${invoice.sourceCity} → ${invoice.destCity}',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryLight),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('View Details')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      const PopupMenuItem(value: 'share', child: Text('Share Invoice')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          context.pushNamed(RouteNames.editInvoice, extra: invoice);
                          break;
                        case 'duplicate':
                          final duplicatedInvoice = invoice.copyWith(
                            id: '',
                            invoiceNumber: '${invoice.invoiceNumber}-COPY',
                            paymentStatus: PaymentStatus.pending,
                            invoiceDate: DateTime.now(),
                          );
                          context.pushNamed(RouteNames.addInvoice, extra: duplicatedInvoice);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, ref);
                          break;
                        case 'view':
                          {
                            final firms = ref.read(firmsProvider).value ?? [];
                            final customers = ref.read(customersProvider).value ?? [];
                            final vehicles = ref.read(vehiclesProvider).value ?? [];
                            final profile = ref.read(profileControllerProvider);

                            final firm = firms.where((f) => f.id == invoice.firmId).firstOrNull ??
                                firms.where((f) => f.isDefault).firstOrNull ??
                                firms.firstOrNull ??
                                FirmModel(
                                  id: 'default',
                                  businessName: profile.companyName.isNotEmpty ? profile.companyName : 'Sharma Freight & Logistics',
                                  ownerName: profile.fullName,
                                  phone: profile.phone,
                                  email: profile.email,
                                  gstin: profile.gstin,
                                  pan: profile.gstin.length >= 10 ? profile.gstin.substring(2, 12) : 'ABCDE1234F',
                                  address: profile.address,
                                  city: '',
                                  state: '',
                                  pin: '',
                                );

                            final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull ??
                                CustomerModel(id: invoice.customerId, customerName: 'Customer', phone: '', gstin: '', address: '', city: '', state: '', pin: '');

                            final vehicle = vehicles.where((v) => v.id == invoice.vehicleId).firstOrNull ??
                                VehicleModel(id: invoice.vehicleId, vehicleNumber: 'Vehicle', type: 'Truck', capacity: 10, driverName: '', driverPhone: '', insuranceNumber: '', status: VehicleStatus.available);

                            context.pushNamed(
                              RouteNames.previewInvoice,
                              extra: {
                                'invoice': invoice,
                                'firm': firm,
                                'customer': customer,
                                'vehicle': vehicle,
                              },
                            );
                          }
                          break;
                        case 'share':
                          {
                            final firms = ref.read(firmsProvider).value ?? [];
                            final customers = ref.read(customersProvider).value ?? [];
                            final vehicles = ref.read(vehiclesProvider).value ?? [];
                            final profile = ref.read(profileControllerProvider);

                            final firm = firms.where((f) => f.id == invoice.firmId).firstOrNull ??
                                firms.where((f) => f.isDefault).firstOrNull ??
                                firms.firstOrNull ??
                                FirmModel(
                                  id: 'default',
                                  businessName: profile.companyName.isNotEmpty ? profile.companyName : 'Sharma Freight & Logistics',
                                  ownerName: profile.fullName,
                                  phone: profile.phone,
                                  email: profile.email,
                                  gstin: profile.gstin,
                                  pan: profile.gstin.length >= 10 ? profile.gstin.substring(2, 12) : 'ABCDE1234F',
                                  address: profile.address,
                                  city: '',
                                  state: '',
                                  pin: '',
                                );

                            final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull ??
                                CustomerModel(id: invoice.customerId, customerName: 'Customer', phone: '', gstin: '', address: '', city: '', state: '', pin: '');

                            final vehicle = vehicles.where((v) => v.id == invoice.vehicleId).firstOrNull ??
                                VehicleModel(id: invoice.vehicleId, vehicleNumber: 'Vehicle', type: 'Truck', capacity: 10, driverName: '', driverPhone: '', insuranceNumber: '', status: VehicleStatus.available);

                            InvoicePdfGenerator.generate(
                              invoice: invoice,
                              firm: firm,
                              customer: customer,
                              vehicle: vehicle,
                            ).then((pdfBytes) {
                              Printing.sharePdf(
                                bytes: pdfBytes,
                                filename: '${invoice.invoiceNumber}.pdf',
                              );
                            });
                          }
                          break;
                      }
                    },
                  ),
                ],
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
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(invoicesProvider.notifier).deleteInvoice(invoice.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
