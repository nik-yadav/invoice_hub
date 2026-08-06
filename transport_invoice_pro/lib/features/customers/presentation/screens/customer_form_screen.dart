import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/pin_code_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _fetchPinDetails(String pin) async {
    if (pin.length == 6) {
      final details = await PinCodeService.fetchDetails(pin);
      if (details != null && mounted) {
        setState(() {
          _cityController.text = details.city;
          _stateController.text = details.state;
          if (_addressController.text.isEmpty) {
            _addressController.text = details.address;
          }
        });
      }
    }
  }

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _gstinController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.customerName);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _gstinController = TextEditingController(text: widget.customer?.gstin);
    _addressController = TextEditingController(text: widget.customer?.address);
    _cityController = TextEditingController(text: widget.customer?.city);
    _stateController = TextEditingController(text: widget.customer?.state);
    _pinController = TextEditingController(text: widget.customer?.pin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newCustomer = CustomerModel(
      id: widget.customer?.id,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gstin: _gstinController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pin: _pinController.text.trim(),
    );

    if (widget.customer == null) {
      await ref.read(customersProvider.notifier).addCustomer(newCustomer);
    } else {
      await ref.read(customersProvider.notifier).updateCustomer(newCustomer);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
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
              const Text('Basic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Customer Name',
                prefixIcon: const Icon(Icons.person),
                validator: (val) => Validators.validatePersonName(val, fieldName: 'Customer Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _gstinController,
                label: 'GSTIN (Optional)',
                prefixIcon: const Icon(Icons.receipt_long),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Street Address',
                prefixIcon: const Icon(Icons.location_on),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City',
                      readOnly: true,
                      hint: 'Auto-fetched from PIN',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      label: 'State',
                      readOnly: true,
                      hint: 'Auto-fetched from PIN',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _pinController,
                label: 'PIN Code (6 Digits)',
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _fetchPinDetails,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Customer',
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
