import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final VehicleModel? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _numberController;
  late final TextEditingController _typeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _driverNameController;
  late final TextEditingController _driverPhoneController;
  late final TextEditingController _insuranceController;
  
  VehicleStatus _selectedStatus = VehicleStatus.available;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.vehicle?.vehicleNumber ?? '');
    _typeController = TextEditingController(text: widget.vehicle?.type ?? '');
    _capacityController = TextEditingController(text: widget.vehicle?.capacity.toString() ?? '');
    _driverNameController = TextEditingController(text: widget.vehicle?.driverName ?? '');
    _driverPhoneController = TextEditingController(text: widget.vehicle?.driverPhone ?? '');
    _insuranceController = TextEditingController(text: widget.vehicle?.insuranceNumber ?? '');
    _selectedStatus = widget.vehicle?.status ?? VehicleStatus.available;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _typeController.dispose();
    _capacityController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final capacity = double.tryParse(_capacityController.text.trim()) ?? 0.0;
      
      final vehicle = VehicleModel(
        id: widget.vehicle?.id ?? const Uuid().v4(),
        vehicleNumber: _numberController.text.trim(),
        type: _typeController.text.trim(),
        capacity: capacity,
        driverName: _driverNameController.text.trim(),
        driverPhone: _driverPhoneController.text.trim(),
        insuranceNumber: _insuranceController.text.trim(),
        status: _selectedStatus,
      );

      final notifier = ref.read(vehiclesProvider.notifier);
      if (widget.vehicle == null) {
        await notifier.addVehicle(vehicle);
      } else {
        await notifier.updateVehicle(vehicle);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle ${widget.vehicle == null ? 'added' : 'updated'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _numberController,
                    label: 'Vehicle Number',
                    prefixIcon: const Icon(Icons.pin),
                    textCapitalization: TextCapitalization.characters,
                    validator: Validators.validateVehicleNumber,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _typeController,
                          label: 'Vehicle Type',
                          hint: 'e.g. Open Truck, Trailer',
                          prefixIcon: const Icon(Icons.local_shipping),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _capacityController,
                          label: 'Capacity (Tons)',
                          prefixIcon: const Icon(Icons.scale),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Driver Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _driverNameController,
                    label: 'Driver Name (Optional)',
                    prefixIcon: const Icon(Icons.person),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        return Validators.validatePersonName(val, fieldName: 'Driver Name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _driverPhoneController,
                    label: 'Driver Phone (Optional)',
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        return Validators.validatePhone(val);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Text('Compliance & Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _insuranceController,
                    label: 'Insurance Number (Optional)',
                    prefixIcon: const Icon(Icons.verified_user),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Text('Current Status', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: VehicleStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = status);
                          }
                        },
                        selectedColor: status.color.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? status.color : AppColors.textSecondaryLight,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  AppButton(
                    text: widget.vehicle == null ? 'Save Vehicle' : 'Update Vehicle',
                    isLoading: _isLoading,
                    onPressed: _save,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
