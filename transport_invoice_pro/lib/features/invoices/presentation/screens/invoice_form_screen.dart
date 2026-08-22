import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/services/pin_code_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/invoice_model.dart';
import '../providers/invoice_provider.dart';
import '../../../firms/presentation/providers/firm_provider.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/models/customer_model.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../vehicles/domain/models/vehicle_model.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _invoiceNumberCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _sourcePinCtrl = TextEditingController();
  final _sourceCityCtrl = TextEditingController();
  final _sourceDistrictCtrl = TextEditingController();
  final _sourceStateCtrl = TextEditingController();
  final _sourceAddressCtrl = TextEditingController();
  final _destPinCtrl = TextEditingController();
  final _destCityCtrl = TextEditingController();
  final _destDistrictCtrl = TextEditingController();
  final _destStateCtrl = TextEditingController();
  final _destAddressCtrl = TextEditingController();
  
  // Base Charge
  final _transChargeCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  // Autocomplete Text Controllers
  final _customerSearchCtrl = TextEditingController();
  final _vehicleSearchCtrl = TextEditingController();

  // Selections
  String? _selectedFirmId;
  String? _selectedCustomerId;
  String? _selectedVehicleId;
  DateTime _invoiceDate = DateTime.now();
  DateTime _tripDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  PaymentStatus _paymentStatus = PaymentStatus.pending;

  // Dynamic Custom Fields State
  final Map<String, String> _customPartiesFields = {};
  final Map<String, double> _customChargesFields = {};
  final Map<String, TextEditingController> _customPartiesCtrls = {};
  final Map<String, TextEditingController> _customChargesCtrls = {};

  // Live Total
  double _totalAmount = 0.0;

  // PIN Code Dropdown Options State
  List<PinCodeDetails> _sourcePinOptions = [];
  PinCodeDetails? _selectedSourcePinOption;
  bool _isLoadingSourcePin = false;

  List<PinCodeDetails> _destPinOptions = [];
  PinCodeDetails? _selectedDestPinOption;
  bool _isLoadingDestPin = false;

  void _onSelectSourceLocation(PinCodeDetails details) {
    final enablePostOffice = ref.read(profileControllerProvider).enablePostOfficeSelection;
    setState(() {
      _selectedSourcePinOption = details;
      _sourceCityCtrl.text = details.city;
      _sourceDistrictCtrl.text = details.district;
      _sourceStateCtrl.text = details.state;
      if (enablePostOffice) {
        _sourceAddressCtrl.text = details.address;
      }
    });
  }

  void _onSelectDestLocation(PinCodeDetails details) {
    final enablePostOffice = ref.read(profileControllerProvider).enablePostOfficeSelection;
    setState(() {
      _selectedDestPinOption = details;
      _destCityCtrl.text = details.city;
      _destDistrictCtrl.text = details.district;
      _destStateCtrl.text = details.state;
      if (enablePostOffice) {
        _destAddressCtrl.text = details.address;
      }
    });
  }

  Future<void> _fetchPinDetails(String pin, bool isSource) async {
    if (pin.length == 6) {
      if (isSource) {
        setState(() {
          _isLoadingSourcePin = true;
          _sourcePinOptions = [];
          _selectedSourcePinOption = null;
        });
        final options = await PinCodeService.fetchAllDetails(pin);
        if (mounted) {
          setState(() {
            _isLoadingSourcePin = false;
            _sourcePinOptions = options;
            if (options.isNotEmpty) {
              _onSelectSourceLocation(options.first);
            }
          });
        }
      } else {
        setState(() {
          _isLoadingDestPin = true;
          _destPinOptions = [];
          _selectedDestPinOption = null;
        });
        final options = await PinCodeService.fetchAllDetails(pin);
        if (mounted) {
          setState(() {
            _isLoadingDestPin = false;
            _destPinOptions = options;
            if (options.isNotEmpty) {
              _onSelectDestLocation(options.first);
            }
          });
        }
      }
    } else {
      if (isSource) {
        setState(() {
          _sourcePinOptions = [];
          _selectedSourcePinOption = null;
        });
      } else {
        setState(() {
          _destPinOptions = [];
          _selectedDestPinOption = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      final i = widget.invoice!;
      _invoiceNumberCtrl.text = i.invoiceNumber;
      _materialCtrl.text = i.materialDescription ?? '';
      _weightCtrl.text = i.weight != null ? i.weight.toString() : '';
      _sourcePinCtrl.text = i.sourcePin;
      _sourceCityCtrl.text = i.sourceCity;
      _sourceDistrictCtrl.text = i.sourceDistrict;
      _sourceStateCtrl.text = i.sourceState;
      _sourceAddressCtrl.text = i.sourceAddress;
      _destPinCtrl.text = i.destinationPin;
      _destCityCtrl.text = i.destCity;
      _destDistrictCtrl.text = i.destDistrict;
      _destStateCtrl.text = i.destState;
      _destAddressCtrl.text = i.destAddress;
      
      _transChargeCtrl.text = i.transportationCharge.toString();
      _remarksCtrl.text = i.remarks;

      _selectedFirmId = i.firmId;
      _selectedCustomerId = i.customerId;
      _selectedVehicleId = i.vehicleId;
      _invoiceDate = i.invoiceDate;
      _tripDate = i.tripDate;
      _paymentMethod = i.paymentMethod;
      _paymentStatus = i.paymentStatus;
      
      // Load custom fields
      i.customPartiesFields.forEach((key, val) {
        _customPartiesFields[key] = val;
        _customPartiesCtrls[key] = TextEditingController(text: val);
      });
      i.customChargesFields.forEach((key, val) {
        _customChargesFields[key] = val;
        _customChargesCtrls[key] = TextEditingController(text: val.toString());
        _customChargesCtrls[key]!.addListener(_calculateTotal);
      });

      _calculateTotal();
    } else {
      _invoiceNumberCtrl.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }

    _transChargeCtrl.addListener(_calculateTotal);
    
    // Listen to updates to set search texts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSearchTexts();
    });
  }

  void _initSearchTexts() {
    final customers = ref.read(customersProvider).value ?? [];
    final vehicles = ref.read(vehiclesProvider).value ?? [];
    
    final customer = customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
    final vehicle = vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;

    if (customer != null) {
      _customerSearchCtrl.text = customer.customerName;
    }
    if (vehicle != null) {
      _vehicleSearchCtrl.text = vehicle.vehicleNumber;
    }
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _materialCtrl.dispose();
    _weightCtrl.dispose();
    _sourcePinCtrl.dispose();
    _sourceCityCtrl.dispose();
    _sourceDistrictCtrl.dispose();
    _sourceStateCtrl.dispose();
    _sourceAddressCtrl.dispose();
    _destPinCtrl.dispose();
    _destCityCtrl.dispose();
    _destDistrictCtrl.dispose();
    _destStateCtrl.dispose();
    _destAddressCtrl.dispose();
    _transChargeCtrl.dispose();
    _remarksCtrl.dispose();
    _customerSearchCtrl.dispose();
    _vehicleSearchCtrl.dispose();
    _customPartiesCtrls.forEach((_, ctrl) => ctrl.dispose());
    _customChargesCtrls.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  void _calculateTotal() {
    final trans = double.tryParse(_transChargeCtrl.text) ?? 0.0;
    double extraCharges = 0.0;
    
    _customChargesCtrls.forEach((key, ctrl) {
      final val = double.tryParse(ctrl.text) ?? 0.0;
      extraCharges += val;
    });

    setState(() {
      _totalAmount = trans + extraCharges;
    });
  }

  void _addCustomField(bool isPartyLevel) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text(isPartyLevel ? 'Add Custom Party Field' : 'Add Custom Charge Field'),
          content: AppTextField(
            controller: ctrl,
            label: 'Field Name (e.g. GST Details or Surcharge)',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (isPartyLevel) {
                      _customPartiesFields[name] = '';
                      _customPartiesCtrls[name] = TextEditingController();
                    } else {
                      _customChargesFields[name] = 0.0;
                      _customChargesCtrls[name] = TextEditingController();
                      _customChargesCtrls[name]!.addListener(_calculateTotal);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ensureEntitiesSaved() async {
    final customers = ref.read(customersProvider).value ?? [];
    final vehicles = ref.read(vehiclesProvider).value ?? [];

    final typedCustomerName = _customerSearchCtrl.text.trim();
    if (typedCustomerName.isNotEmpty) {
      final match = customers.where((c) => c.customerName.toLowerCase() == typedCustomerName.toLowerCase()).firstOrNull;
      if (match != null) {
        _selectedCustomerId = match.id;
      } else {
        await _handleAutoCreateCustomer(typedCustomerName);
      }
    }

    final typedVehicleNum = _vehicleSearchCtrl.text.trim();
    if (typedVehicleNum.isNotEmpty) {
      final match = vehicles.where((v) => v.vehicleNumber.toLowerCase() == typedVehicleNum.toLowerCase()).firstOrNull;
      if (match != null) {
        _selectedVehicleId = match.id;
      } else {
        await _handleAutoCreateVehicle(typedVehicleNum);
      }
    }
  }

  Future<void> _saveInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    // Auto-create/save Typed Entities
    await _ensureEntitiesSaved();

    if (_selectedFirmId == null || _selectedCustomerId == null || _selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and select Customer and Vehicle'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final partiesMap = <String, String>{};
      _customPartiesCtrls.forEach((k, ctrl) {
        partiesMap[k] = ctrl.text.trim();
      });

      final chargesMap = <String, double>{};
      _customChargesCtrls.forEach((k, ctrl) {
        chargesMap[k] = double.tryParse(ctrl.text.trim()) ?? 0.0;
      });

      final invoice = InvoiceModel(
        id: widget.invoice?.id ?? const Uuid().v4(),
        invoiceNumber: _invoiceNumberCtrl.text,
        invoiceDate: _invoiceDate,
        tripDate: _tripDate,
        firmId: _selectedFirmId!,
        customerId: _selectedCustomerId!,
        vehicleId: _selectedVehicleId!,
        sourcePin: _sourcePinCtrl.text,
        sourceCity: _sourceCityCtrl.text,
        sourceDistrict: _sourceDistrictCtrl.text,
        sourceState: _sourceStateCtrl.text,
        sourceAddress: _sourceAddressCtrl.text.trim().isNotEmpty
            ? _sourceAddressCtrl.text.trim()
            : '${_sourceCityCtrl.text.trim()}, ${_sourceStateCtrl.text.trim()}',
        destinationPin: _destPinCtrl.text,
        destCity: _destCityCtrl.text,
        destDistrict: _destDistrictCtrl.text,
        destState: _destStateCtrl.text,
        destAddress: _destAddressCtrl.text.trim().isNotEmpty
            ? _destAddressCtrl.text.trim()
            : '${_destCityCtrl.text.trim()}, ${_destStateCtrl.text.trim()}',
        materialDescription: _materialCtrl.text.isNotEmpty ? _materialCtrl.text : null,
        weight: double.tryParse(_weightCtrl.text.trim()),
        transportationCharge: double.tryParse(_transChargeCtrl.text.trim()) ?? 0.0,
        customPartiesFields: partiesMap,
        customChargesFields: chargesMap,
        totalAmount: _totalAmount,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        remarks: _remarksCtrl.text,
      );

      final notifier = ref.read(invoicesProvider.notifier);
      if (widget.invoice == null) {
        await notifier.addInvoice(invoice);
      } else {
        await notifier.updateInvoice(invoice);
      }

      if (mounted) {
        final profile = ref.read(profileControllerProvider);
        final customers = ref.read(customersProvider).value ?? [];
        final vehicles = ref.read(vehiclesProvider).value ?? [];

        final dbFirms = ref.read(firmsProvider).value ?? [];

        final fallbackFirm = FirmModel(
          id: 'user_firm',
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

        final selectedFirm = dbFirms.firstWhere(
          (f) => f.id == invoice.firmId,
          orElse: () => dbFirms.firstWhere((f) => f.isDefault, orElse: () => dbFirms.firstOrNull ?? fallbackFirm),
        );

        final customer = customers.firstWhere(
          (c) => c.id == invoice.customerId,
          orElse: () => CustomerModel(
            id: invoice.customerId,
            customerName: _customerSearchCtrl.text,
            phone: '',
            gstin: '',
            address: '',
            city: '',
            state: '',
            pin: '',
          ),
        );

        final vehicle = vehicles.firstWhere(
          (v) => v.id == invoice.vehicleId,
          orElse: () => VehicleModel(
            id: invoice.vehicleId,
            vehicleNumber: _vehicleSearchCtrl.text,
            type: 'Truck',
            capacity: 10,
            driverName: '',
            driverPhone: '',
            insuranceNumber: '',
            status: VehicleStatus.available,
          ),
        );

        context.pushReplacementNamed(
          RouteNames.previewInvoice,
          extra: {
            'invoice': invoice,
            'firm': selectedFirm,
            'customer': customer,
            'vehicle': vehicle,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully! Generating PDF...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAutoCreateCustomer(String initialName) async {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String? nameError;
    String? phoneError;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add New Customer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    label: 'Customer Name',
                    errorText: nameError,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number (10 Digits)',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: phoneError,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: cityCtrl,
                    label: 'City (Optional)',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final typedName = nameCtrl.text.trim();
                  final typedPhone = phoneCtrl.text.trim();

                  final nErr = Validators.validatePersonName(typedName, fieldName: 'Customer Name');
                  final pErr = Validators.validatePhone(typedPhone);

                  setStateDialog(() {
                    nameError = nErr;
                    phoneError = pErr;
                  });

                  if (nErr != null || pErr != null) return;

                  final newId = const Uuid().v4();
                  final newCustomer = CustomerModel(
                    id: newId,
                    customerName: typedName,
                    phone: typedPhone,
                    gstin: '',
                    address: '',
                    city: cityCtrl.text.trim(),
                    state: '',
                    pin: '',
                  );
                  await ref.read(customersProvider.notifier).addCustomer(newCustomer);
                  setState(() {
                    _selectedCustomerId = newId;
                    _customerSearchCtrl.text = typedName;
                  });
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAutoCreateVehicle(String initialNumber) async {
    final numCtrl = TextEditingController(text: initialNumber);
    final typeCtrl = TextEditingController(text: 'Truck');
    String? numError;
    String? typeError;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add New Vehicle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: numCtrl,
                    label: 'Vehicle Number (Editable)',
                    textCapitalization: TextCapitalization.characters,
                    errorText: numError,
                    onChanged: (val) {
                      if (numError != null) {
                        setStateDialog(() => numError = Validators.validateVehicleNumber(val));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: typeCtrl,
                    label: 'Vehicle Type (Required)',
                    errorText: typeError,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final typedNum = numCtrl.text.trim();
                  final typedType = typeCtrl.text.trim();
                  final validationErr = Validators.validateVehicleNumber(typedNum);

                  setStateDialog(() {
                    numError = validationErr;
                    typeError = typedType.isEmpty ? 'Vehicle type is required' : null;
                  });

                  if (validationErr != null || typedType.isEmpty) return;
                  
                  final formattedNumber = typedNum.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
                  final newId = const Uuid().v4();
                  final newVehicle = VehicleModel(
                    id: newId,
                    vehicleNumber: formattedNumber,
                    type: typedType,
                    capacity: 10.0,
                    driverName: '',
                    driverPhone: '',
                    insuranceNumber: '',
                    status: VehicleStatus.available,
                  );
                  await ref.read(vehiclesProvider.notifier).addVehicle(newVehicle);
                  setState(() {
                    _selectedVehicleId = newId;
                    _vehicleSearchCtrl.text = formattedNumber;
                  });
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider);
    final customers = ref.watch(customersProvider).value ?? [];
    final vehicles = ref.watch(vehiclesProvider).value ?? [];

    final firms = ref.watch(firmsProvider).value ?? [];

    // Fallback firm if database list is empty
    final fallbackFirm = FirmModel(
      id: 'user_firm',
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

    final availableFirms = firms.isNotEmpty ? firms : [fallbackFirm];

    // Auto-select default firm or firm with signature
    if (_selectedFirmId == null || !availableFirms.any((f) => f.id == _selectedFirmId)) {
      final defaultFirm = availableFirms.firstWhere(
        (f) => f.isDefault && f.signaturePath != null && f.signaturePath!.isNotEmpty,
        orElse: () => availableFirms.firstWhere(
          (f) => f.signaturePath != null && f.signaturePath!.isNotEmpty,
          orElse: () => availableFirms.firstWhere((f) => f.isDefault, orElse: () => availableFirms.first),
        ),
      );
      _selectedFirmId = defaultFirm.id;
    }

    // Pre-populate customer and vehicle search texts when editing an invoice
    if (widget.invoice != null) {
      if (_selectedCustomerId != null && customers.isNotEmpty) {
        final customer = customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
        if (customer != null && _customerSearchCtrl.text != customer.customerName) {
          _customerSearchCtrl.text = customer.customerName;
        }
      }
      if (_selectedVehicleId != null && vehicles.isNotEmpty) {
        final vehicle = vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
        if (vehicle != null && _vehicleSearchCtrl.text != vehicle.vehicleNumber) {
          _vehicleSearchCtrl.text = vehicle.vehicleNumber;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Create Invoice' : 'Edit Invoice'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Content
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Entities
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Parties & Vehicle', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton.filledTonal(
                          onPressed: () => _addCustomField(true),
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Custom Field',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Searchable Multi-Firm Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Firm',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              DropdownButtonFormField<String>(
                                value: _selectedFirmId,
                                isExpanded: true,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                items: availableFirms.map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          f.businessName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (f.signaturePath != null && f.signaturePath!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.draw_rounded, size: 16, color: Colors.green.shade700),
                                      ],
                                      if (f.isDefault) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: TextStyle(fontSize: 9, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedFirmId = val);
                                },
                                validator: (val) => val == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Searchable & Auto-creating Customer Input
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => Autocomplete<CustomerModel>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final typed = textEditingValue.text.trim();
                                if (typed.isEmpty) return const Iterable<CustomerModel>.empty();
                                final matches = customers.where((c) => c.customerName.toLowerCase().contains(typed.toLowerCase())).toList();
                                if (matches.isEmpty) {
                                  return [CustomerModel(id: 'CREATE_NEW', customerName: 'CREATE_NEW', phone: '', gstin: '', address: '', city: '', state: '', pin: '')];
                                }
                                return matches;
                              },
                              displayStringForOption: (option) => option.id == 'CREATE_NEW' ? _customerSearchCtrl.text : option.customerName,
                              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                if (_customerSearchCtrl.text.isNotEmpty && textController.text != _customerSearchCtrl.text) {
                                  textController.text = _customerSearchCtrl.text;
                                }
                                return AppTextField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  label: 'Customer Name',
                                  prefixIcon: const Icon(Icons.person),
                                  onChanged: (val) {
                                    _customerSearchCtrl.text = val;
                                  },
                                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                final typedName = _customerSearchCtrl.text.trim();
                                final hasMatch = options.any((c) => c.id != 'CREATE_NEW' && c.customerName.toLowerCase() == typedName.toLowerCase());
                                final validOptions = options.where((c) => c.id != 'CREATE_NEW');
                                
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: 200),
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        children: [
                                          ...validOptions.map((customer) => ListTile(
                                            title: Text(customer.customerName),
                                            onTap: () {
                                              onSelected(customer);
                                              setState(() {
                                                _selectedCustomerId = customer.id;
                                                _customerSearchCtrl.text = customer.customerName;
                                              });
                                            },
                                          )),
                                          if (typedName.isNotEmpty && !hasMatch)
                                            ListTile(
                                              tileColor: AppColors.primaryBlue.withOpacity(0.05),
                                              title: Text('Create Customer "$typedName"', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                              leading: const Icon(Icons.add, color: AppColors.primaryBlue),
                                              onTap: () {
                                                _handleAutoCreateCustomer(typedName);
                                                FocusScope.of(context).unfocus();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Searchable & Auto-creating Vehicle Input
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => Autocomplete<VehicleModel>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final typed = textEditingValue.text.trim();
                                if (typed.isEmpty) return const Iterable<VehicleModel>.empty();
                                final matches = vehicles.where((v) => v.vehicleNumber.toLowerCase().contains(typed.toLowerCase())).toList();
                                if (matches.isEmpty) {
                                  return [VehicleModel(id: 'CREATE_NEW', vehicleNumber: 'CREATE_NEW', type: '', capacity: 0, driverName: '', driverPhone: '', insuranceNumber: '', status: VehicleStatus.available)];
                                }
                                return matches;
                              },
                              displayStringForOption: (option) => option.id == 'CREATE_NEW' ? _vehicleSearchCtrl.text : option.vehicleNumber,
                              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                if (_vehicleSearchCtrl.text.isNotEmpty && textController.text != _vehicleSearchCtrl.text) {
                                  textController.text = _vehicleSearchCtrl.text;
                                }
                                return AppTextField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  label: 'Vehicle Number',
                                  prefixIcon: const Icon(Icons.local_shipping),
                                  onChanged: (val) {
                                    _vehicleSearchCtrl.text = val;
                                  },
                                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                final typedNum = _vehicleSearchCtrl.text.trim();
                                final hasMatch = options.any((v) => v.id != 'CREATE_NEW' && v.vehicleNumber.toLowerCase() == typedNum.toLowerCase());
                                final validOptions = options.where((v) => v.id != 'CREATE_NEW');

                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: 200),
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        children: [
                                          ...validOptions.map((vehicle) => ListTile(
                                            title: Text(vehicle.vehicleNumber),
                                            onTap: () {
                                              onSelected(vehicle);
                                              setState(() {
                                                _selectedVehicleId = vehicle.id;
                                                _vehicleSearchCtrl.text = vehicle.vehicleNumber;
                                              });
                                            },
                                          )),
                                          if (typedNum.isNotEmpty && !hasMatch)
                                            ListTile(
                                              tileColor: AppColors.primaryBlue.withOpacity(0.05),
                                              title: Text('Create Vehicle "$typedNum"', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                              leading: const Icon(Icons.add, color: AppColors.primaryBlue),
                                              onTap: () {
                                                _handleAutoCreateVehicle(typedNum);
                                                FocusScope.of(context).unfocus();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Dynamic Custom Parties & Vehicle Level Fields
                    if (_customPartiesFields.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _customPartiesFields.keys.map((key) {
                          return SizedBox(
                            width: 250,
                            child: AppTextField(
                              controller: _customPartiesCtrls[key],
                              label: key,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                onPressed: () {
                                  setState(() {
                                    _customPartiesFields.remove(key);
                                    _customPartiesCtrls.remove(key);
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    // Section 2: Trip & Location
                    Text('Trip Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _sourcePinCtrl,
                            label: 'Source PIN (Optional)',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (val) => _fetchPinDetails(val, true),
                            validator: (val) => val != null && val.isNotEmpty && val.length != 6 ? 'PIN must be 6 digits' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _sourceCityCtrl,
                            label: 'Source City *',
                            hint: 'e.g. Mumbai',
                            validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _sourceStateCtrl,
                            label: 'Source State *',
                            hint: 'e.g. Maharashtra',
                            validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoadingSourcePin) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                    ] else if (profile.enablePostOfficeSelection && _sourcePinOptions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PinCodeDetails>(
                        value: _selectedSourcePinOption,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Source Post Office / Area (${_sourcePinOptions.length} available)',
                          prefixIcon: const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _sourcePinOptions.map((opt) {
                          return DropdownMenuItem<PinCodeDetails>(
                            value: opt,
                            child: Text(
                              '${opt.name} (${opt.city}, ${opt.state})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null) {
                            _onSelectSourceLocation(selected);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _sourceAddressCtrl,
                      label: 'Source Detailed Address / Street (Optional)',
                      hint: 'Enter building, street, or landmark if needed',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _destPinCtrl,
                            label: 'Dest. PIN (Optional)',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (val) => _fetchPinDetails(val, false),
                            validator: (val) => val != null && val.isNotEmpty && val.length != 6 ? 'PIN must be 6 digits' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _destCityCtrl,
                            label: 'Dest. City *',
                            hint: 'e.g. Delhi',
                            validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _destStateCtrl,
                            label: 'Dest. State *',
                            hint: 'e.g. Delhi',
                            validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoadingDestPin) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                    ] else if (profile.enablePostOfficeSelection && _destPinOptions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PinCodeDetails>(
                        value: _selectedDestPinOption,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Destination Post Office / Area (${_destPinOptions.length} available)',
                          prefixIcon: const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _destPinOptions.map((opt) {
                          return DropdownMenuItem<PinCodeDetails>(
                            value: opt,
                            child: Text(
                              '${opt.name} (${opt.city}, ${opt.state})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null) {
                            _onSelectDestLocation(selected);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _destAddressCtrl,
                      label: 'Dest. Detailed Address / Street (Optional)',
                      hint: 'Enter building, street, or landmark if needed',
                    ),
                    const SizedBox(height: 32),

                    // Section 3: Material & Charges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cargo & Charges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton.filledTonal(
                          onPressed: () => _addCustomField(false),
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Custom Charge',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: AppTextField(controller: _materialCtrl, label: 'Material Description (Optional)')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _weightCtrl,
                            label: 'Weight (Tons) (Optional)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              final selectedVehicle = vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
                              return Validators.validateWeightAgainstCapacity(val, selectedVehicle?.capacity);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 250,
                          child: AppTextField(
                            controller: _transChargeCtrl,
                            label: 'Transportation Charge',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        
                        // Render Dynamic Custom Charges Fields
                        ..._customChargesFields.keys.map((key) {
                          return SizedBox(
                            width: 250,
                            child: AppTextField(
                              controller: _customChargesCtrls[key],
                              label: key,
                              keyboardType: TextInputType.number,
                              validator: (val) => val != null && val.isNotEmpty && double.tryParse(val) == null ? 'Must be a number' : null,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                onPressed: () {
                                  setState(() {
                                    _customChargesFields.remove(key);
                                    _customChargesCtrls.remove(key);
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Section 4: Payment
                    Text('Payment & Remarks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentMethod>(
                            value: _paymentMethod,
                            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                            items: PaymentMethod.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<PaymentStatus>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                            items: PaymentStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
                            onChanged: (val) => setState(() => _paymentStatus = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(controller: _remarksCtrl, label: 'Remarks', maxLines: 3),
                    const SizedBox(height: 80), // padding for scroll
                  ],
                ),
              ),
            ),
          ),
          
          // Live Total Card
          Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _invoiceNumberCtrl,
                  label: 'Invoice Number',
                  readOnly: true,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _invoiceDate.isAfter(now) ? now : _invoiceDate,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (date != null) setState(() => _invoiceDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Invoice Date', border: OutlineInputBorder()),
                    child: Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                  ),
                ),
                const SizedBox(height: 32),
                AppCard(
                  color: AppColors.primaryBlue,
                  child: Column(
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(_totalAmount),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;

                    // Guarantee auto-created customer and vehicle are written to Hive first
                    await _ensureEntitiesSaved();

                    final customer = customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
                    final vehicle = vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;

                    if (customer == null || vehicle == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select or create Customer and Vehicle before previewing'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    // Gather dynamic custom inputs
                    final partiesMap = <String, String>{};
                    _customPartiesCtrls.forEach((k, ctrl) {
                      partiesMap[k] = ctrl.text.trim();
                    });

                    final chargesMap = <String, double>{};
                    _customChargesCtrls.forEach((k, ctrl) {
                      chargesMap[k] = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    });

                    final invoice = InvoiceModel(
                      id: widget.invoice?.id ?? const Uuid().v4(),
                      invoiceNumber: _invoiceNumberCtrl.text,
                      invoiceDate: _invoiceDate,
                      tripDate: _tripDate,
                      firmId: _selectedFirmId!,
                      customerId: _selectedCustomerId!,
                      vehicleId: _selectedVehicleId!,
                      sourcePin: _sourcePinCtrl.text,
                      sourceCity: _sourceCityCtrl.text,
                      sourceDistrict: _sourceDistrictCtrl.text,
                      sourceState: _sourceStateCtrl.text,
                      sourceAddress: _sourceAddressCtrl.text.trim().isNotEmpty
                          ? _sourceAddressCtrl.text.trim()
                          : '${_sourceCityCtrl.text.trim()}, ${_sourceStateCtrl.text.trim()}',
                      destinationPin: _destPinCtrl.text,
                      destCity: _destCityCtrl.text,
                      destDistrict: _destDistrictCtrl.text,
                      destState: _destStateCtrl.text,
                      destAddress: _destAddressCtrl.text.trim().isNotEmpty
                          ? _destAddressCtrl.text.trim()
                          : '${_destCityCtrl.text.trim()}, ${_destStateCtrl.text.trim()}',
                      materialDescription: _materialCtrl.text.isNotEmpty ? _materialCtrl.text : null,
                      weight: double.tryParse(_weightCtrl.text.trim()),
                      transportationCharge: double.tryParse(_transChargeCtrl.text.trim()) ?? 0.0,
                      customPartiesFields: partiesMap,
                      customChargesFields: chargesMap,
                      totalAmount: _totalAmount,
                      paymentMethod: _paymentMethod,
                      paymentStatus: _paymentStatus,
                      remarks: _remarksCtrl.text,
                    );

                    context.pushNamed(
                      RouteNames.previewInvoice,
                      extra: {
                        'invoice': invoice,
                        'firm': availableFirms.firstWhere((f) => f.id == _selectedFirmId, orElse: () => fallbackFirm),
                        'customer': customer,
                        'vehicle': vehicle,
                      },
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text('Preview Invoice'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Save Invoice',
                  isLoading: _isLoading,
                  onPressed: _saveInvoice,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
