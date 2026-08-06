import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/list_skeleton_widget.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../domain/models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(filteredVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
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
                  ref.read(vehicleSearchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Search vehicle number, driver name, or type...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
                  suffixIcon: ref.watch(vehicleSearchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            ref.read(vehicleSearchQueryProvider.notifier).state = '';
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
        onPressed: () => context.pushNamed(RouteNames.addVehicle),
        icon: const Icon(Icons.fire_truck),
        label: const Text('Add Vehicle'),
      ),
      body: vehiclesState.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.local_shipping_outlined,
              title: 'No vehicles found',
              description: 'You haven\'t added any vehicles to your fleet yet, or your search yielded no results.',
              actionLabel: 'Add Vehicle',
              onActionPressed: () => context.pushNamed(RouteNames.addVehicle),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _VehicleCard(vehicle: vehicle);
            },
          );
        },
        loading: () => AppSkeleton.list(itemCount: 4),
        error: (err, st) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.read(vehiclesProvider.notifier).loadVehicles(),
        ),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          context.pushNamed(RouteNames.editVehicle, extra: vehicle);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Text(
                      vehicle.vehicleNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicle.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: vehicle.status.color),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.status.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: vehicle.status.color,
                            fontWeight: FontWeight.bold,
                          ),
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
                        context.pushNamed(RouteNames.editVehicle, extra: vehicle);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, ref);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(context, Icons.local_shipping_outlined, '${vehicle.type} • ${vehicle.capacity} Tons'),
                  ),
                  Expanded(
                    child: _buildInfoRow(context, Icons.person_outline, vehicle.driverName.isNotEmpty ? vehicle.driverName : 'No Driver'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(context, Icons.phone_outlined, vehicle.driverPhone.isNotEmpty ? vehicle.driverPhone : 'N/A'),
                  ),
                  Expanded(
                    child: _buildInfoRow(context, Icons.verified_user_outlined, vehicle.insuranceNumber.isNotEmpty ? 'Insured' : 'No Insurance',
                      color: vehicle.insuranceNumber.isNotEmpty ? AppColors.success : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondaryLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
