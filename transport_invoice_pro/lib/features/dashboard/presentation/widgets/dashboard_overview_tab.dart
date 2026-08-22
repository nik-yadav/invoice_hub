import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../invoices/presentation/providers/invoice_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../firms/presentation/providers/firm_provider.dart';
import '../../../invoices/domain/models/invoice_model.dart';
import '../../../vehicles/domain/models/vehicle_model.dart';
import '../../../customers/domain/models/customer_model.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../invoices/presentation/utils/invoice_pdf_generator.dart';
import 'metric_card.dart';
import 'quick_action_card.dart';
import 'recent_invoices_card.dart';

/// Presentation tab rendering the main Dashboard Overview.
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final customersAsync = ref.watch(customersProvider);
    
    final theme = Theme.of(context);

    // Compute Metrics reactively
    final invoices = invoicesAsync.value ?? [];
    final vehicles = vehiclesAsync.value ?? [];
    final customers = customersAsync.value ?? [];

    final now = DateTime.now();
    final todayInvoices = invoices.where((i) => 
      i.invoiceDate.year == now.year && 
      i.invoiceDate.month == now.month && 
      i.invoiceDate.day == now.day
    ).toList();

    final todayRevenue = todayInvoices.fold<double>(0, (sum, i) => sum + i.totalAmount);
    final todayInvoicesCount = todayInvoices.length;
    
    final pendingPaymentsAmount = invoices
        .where((i) => i.paymentStatus == PaymentStatus.pending || i.paymentStatus == PaymentStatus.partial)
        .fold<double>(0, (sum, i) => sum + i.totalAmount);

    final activeVehiclesCount = vehicles.where((v) => v.status == VehicleStatus.busy).length;
    final totalVehiclesCount = vehicles.length;
    final totalCustomersCount = customers.length;

    final firms = ref.watch(firmsProvider).value ?? [];

    final recentInvoices = invoices.take(5).map((i) {
      final customer = customers.where((c) => c.id == i.customerId).firstOrNull;
      final vehicle = vehicles.where((v) => v.id == i.vehicleId).firstOrNull;
      final firm = firms.where((f) => f.id == i.firmId).firstOrNull ??
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

      final custObj = customer ?? CustomerModel(id: i.customerId, customerName: 'Customer', phone: '', gstin: '', address: '', city: '', state: '', pin: '');
      final vehObj = vehicle ?? VehicleModel(id: i.vehicleId, vehicleNumber: 'Vehicle', type: 'Truck', capacity: 10, driverName: '', driverPhone: '', insuranceNumber: '', status: VehicleStatus.available);

      return RecentInvoiceItem(
        id: i.invoiceNumber,
        clientName: custObj.customerName,
        route: '${i.sourceCity} → ${i.destCity}',
        vehicleNumber: vehObj.vehicleNumber,
        amount: i.totalAmount,
        date: i.invoiceDate,
        status: i.paymentStatus.displayName,
        onTap: () {
          context.pushNamed(
            RouteNames.previewInvoice,
            extra: {
              'invoice': i,
              'firm': firm,
              'customer': custObj,
              'vehicle': vehObj,
            },
          );
        },
        onEdit: () {
          context.pushNamed(
            RouteNames.editInvoice,
            extra: i,
          );
        },
        onShare: () async {
          final pdfBytes = await InvoicePdfGenerator.generate(
            invoice: i,
            firm: firm,
            customer: custObj,
            vehicle: vehObj,
          );
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: '${i.invoiceNumber}.pdf',
          );
        },
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.companyName.isNotEmpty ? profile.companyName : AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => context.goNamed(RouteNames.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title: Key Metrics
            Text(
              "Today's Overview",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),

            // Metrics Grid (Responsive Layout)
            ResponsiveLayout(
              mobile: _buildMetricsGrid(
                crossAxisCount: 2,
                todayRevenue: todayRevenue,
                todayInvoicesCount: todayInvoicesCount,
                pendingPaymentsAmount: pendingPaymentsAmount,
                activeVehiclesCount: activeVehiclesCount,
                totalVehiclesCount: totalVehiclesCount,
                totalCustomersCount: totalCustomersCount,
              ),
              tablet: _buildMetricsGrid(
                crossAxisCount: 3,
                todayRevenue: todayRevenue,
                todayInvoicesCount: todayInvoicesCount,
                pendingPaymentsAmount: pendingPaymentsAmount,
                activeVehiclesCount: activeVehiclesCount,
                totalVehiclesCount: totalVehiclesCount,
                totalCustomersCount: totalCustomersCount,
              ),
              desktop: _buildMetricsGrid(
                crossAxisCount: 5,
                todayRevenue: todayRevenue,
                todayInvoicesCount: todayInvoicesCount,
                pendingPaymentsAmount: pendingPaymentsAmount,
                activeVehiclesCount: activeVehiclesCount,
                totalVehiclesCount: totalVehiclesCount,
                totalCustomersCount: totalCustomersCount,
              ),
            ),
            const SizedBox(height: UIConstants.spacing24),

            // Section Title: Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),

            // Quick Actions Grid
            ResponsiveLayout(
              mobile: _buildQuickActionsGrid(context, crossAxisCount: 1, aspectRatio: 4.8),
              tablet: _buildQuickActionsGrid(context, crossAxisCount: 3, aspectRatio: 4.2),
              desktop: _buildQuickActionsGrid(context, crossAxisCount: 3, aspectRatio: 5.0),
            ),
            const SizedBox(height: UIConstants.spacing24),

            // Recent Invoices Section
            RecentInvoicesCard(
              invoices: recentInvoices,
              isLoading: invoicesAsync.isLoading,
              onViewAll: () => context.goNamed(RouteNames.invoices),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int crossAxisCount,
    required double todayRevenue,
    required int todayInvoicesCount,
    required double pendingPaymentsAmount,
    required int activeVehiclesCount,
    required int totalVehiclesCount,
    required int totalCustomersCount,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: UIConstants.spacing16,
      mainAxisSpacing: UIConstants.spacing16,
      childAspectRatio: 1.25,
      children: [
        MetricCard(
          title: "Today's Revenue",
          value: Formatters.formatCurrency(todayRevenue),
          subtitle: '+14% vs yesterday',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Colors.blue.shade700,
          gradientStart: Colors.blue,
          gradientEnd: Colors.indigo,
          isTrendPositive: true,
        ),
        MetricCard(
          title: 'Invoices Today',
          value: '$todayInvoicesCount',
          subtitle: 'Generated Today',
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.teal.shade700,
          gradientStart: Colors.teal,
          gradientEnd: Colors.teal.shade400,
          isTrendPositive: true,
        ),
        MetricCard(
          title: 'Pending Payments',
          value: Formatters.formatCurrency(pendingPaymentsAmount),
          subtitle: 'Unpaid/Partial',
          icon: Icons.pending_actions_rounded,
          iconColor: Colors.amber.shade800,
          gradientStart: Colors.amber,
          gradientEnd: Colors.orange,
          isTrendPositive: false,
        ),
        MetricCard(
          title: 'Fleet Vehicles',
          value: '$activeVehiclesCount / $totalVehiclesCount',
          subtitle: 'Currently Active',
          icon: Icons.local_shipping_rounded,
          iconColor: Colors.purple.shade700,
          gradientStart: Colors.purple,
          gradientEnd: Colors.deepPurple,
          isTrendPositive: true,
        ),
        MetricCard(
          title: 'Total Customers',
          value: '$totalCustomersCount',
          subtitle: 'Registered',
          icon: Icons.groups_rounded,
          iconColor: Colors.indigo.shade700,
          gradientStart: Colors.indigo,
          gradientEnd: Colors.blue,
          isTrendPositive: true,
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, {required int crossAxisCount, required double aspectRatio}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: UIConstants.spacing16,
      mainAxisSpacing: UIConstants.spacing16,
      childAspectRatio: aspectRatio,
      children: [
        QuickActionCard(
          title: '+ New Invoice',
          description: 'Create Transport Bill',
          icon: Icons.add_circle_outline_rounded,
          iconBackgroundColor: Colors.blue.shade50,
          iconColor: Colors.blue.shade700,
          onTap: () => context.pushNamed(RouteNames.addInvoice),
        ),
        QuickActionCard(
          title: 'Customers',
          description: 'Directory & Accounts',
          icon: Icons.person_search_rounded,
          iconBackgroundColor: Colors.teal.shade50,
          iconColor: Colors.teal.shade700,
          onTap: () => context.goNamed(RouteNames.customers),
        ),
        QuickActionCard(
          title: 'Vehicles',
          description: 'Trucks & Fleet Log',
          icon: Icons.fire_truck_rounded,
          iconBackgroundColor: Colors.amber.shade50,
          iconColor: Colors.amber.shade800,
          onTap: () => context.goNamed(RouteNames.vehicles),
        ),
      ],
    );
  }
}
