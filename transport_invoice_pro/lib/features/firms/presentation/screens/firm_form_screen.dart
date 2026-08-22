import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/digital_signature_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/firm_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/pin_code_service.dart';
import '../providers/firm_provider.dart';

class FirmFormScreen extends ConsumerStatefulWidget {
  final FirmModel? firm;

  const FirmFormScreen({super.key, this.firm});

  @override
  ConsumerState<FirmFormScreen> createState() => _FirmFormScreenState();
}

class _FirmFormScreenState extends ConsumerState<FirmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  List<PinCodeDetails> _pinOptions = [];
  PinCodeDetails? _selectedPinOption;
  bool _isLoadingPin = false;

  void _onSelectLocation(PinCodeDetails details) {
    setState(() {
      _selectedPinOption = details;
      _cityController.text = details.city;
      _stateController.text = details.state;
      _addressController.text = details.address;
    });
  }

  Future<void> _fetchPinDetails(String pin) async {
    if (pin.length == 6) {
      setState(() {
        _isLoadingPin = true;
        _pinOptions = [];
        _selectedPinOption = null;
      });
      final options = await PinCodeService.fetchAllDetails(pin);
      if (mounted) {
        setState(() {
          _isLoadingPin = false;
          _pinOptions = options;
          if (options.isNotEmpty) {
            _onSelectLocation(options.first);
          }
        });
      }
    } else {
      setState(() {
        _pinOptions = [];
        _selectedPinOption = null;
      });
    }
  }

  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstinController;
  late final TextEditingController _panController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinController;

  String? _logoPath;
  String? _signaturePath;
  bool _isDefault = false;
  bool _showPhoneOnInvoice = true;
  bool _showGstinOnInvoice = true;
  bool _showEmailOnInvoice = true;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.firm?.businessName);
    _ownerNameController = TextEditingController(text: widget.firm?.ownerName);
    _phoneController = TextEditingController(text: widget.firm?.phone);
    _emailController = TextEditingController(text: widget.firm?.email);
    _gstinController = TextEditingController(text: widget.firm?.gstin);
    _panController = TextEditingController(text: widget.firm?.pan);
    _addressController = TextEditingController(text: widget.firm?.address);
    _cityController = TextEditingController(text: widget.firm?.city);
    _stateController = TextEditingController(text: widget.firm?.state);
    _pinController = TextEditingController(text: widget.firm?.pin);

    _logoPath = widget.firm?.logoPath;
    _signaturePath = widget.firm?.signaturePath;
    _isDefault = widget.firm?.isDefault ?? false;
    _showPhoneOnInvoice = widget.firm?.showPhoneOnInvoice ?? true;
    _showGstinOnInvoice = widget.firm?.showGstinOnInvoice ?? true;
    _showEmailOnInvoice = widget.firm?.showEmailOnInvoice ?? true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        if (isLogo) {
          setState(() => _logoPath = base64String);
        } else {
          setState(() => _signaturePath = base64String);
          final uploadedUrl = await ApiService.uploadSignature(base64String);
          if (uploadedUrl != null && mounted) {
            setState(() => _signaturePath = uploadedUrl);
          }
        }
      } catch (_) {
        setState(() {
          if (isLogo) {
            _logoPath = image.path;
          } else {
            _signaturePath = image.path;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final existingFirms = ref.read(firmsProvider).value ?? [];
    final shouldBeDefault = _isDefault ||
        existingFirms.isEmpty ||
        (existingFirms.length <= 1) ||
        (_signaturePath != null && _signaturePath!.isNotEmpty && !existingFirms.any((f) => f.id != widget.firm?.id && f.isDefault));

    final newFirm = FirmModel(
      id: widget.firm?.id,
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gstin: _gstinController.text.trim(),
      pan: _panController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pin: _pinController.text.trim(),
      logoPath: _logoPath,
      signaturePath: _signaturePath,
      isDefault: shouldBeDefault,
      showPhoneOnInvoice: _showPhoneOnInvoice,
      showGstinOnInvoice: _showGstinOnInvoice,
      showEmailOnInvoice: _showEmailOnInvoice,
    );

    if (widget.firm == null) {
      await ref.read(firmsProvider.notifier).addFirm(newFirm);
    } else {
      await ref.read(firmsProvider.notifier).updateFirm(newFirm);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.firm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Firm' : 'Add Firm'),
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
              _buildImagePickerRow(),
              const SizedBox(height: 24),
              const Text('Basic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _businessNameController,
                label: 'Business Name',
                prefixIcon: const Icon(Icons.storefront),
                validator: Validators.validateBusinessName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _ownerNameController,
                label: 'Owner Name',
                prefixIcon: const Icon(Icons.person),
                validator: (val) => Validators.validatePersonName(val, fieldName: 'Owner Name'),
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
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 24),
              const Text('Tax & Legal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _gstinController,
                label: 'GSTIN',
                prefixIcon: const Icon(Icons.receipt_long),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _panController,
                label: 'PAN',
                prefixIcon: const Icon(Icons.credit_card),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Street Address',
                prefixIcon: const Icon(Icons.location_on),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              if (_isLoadingPin) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
              ] else if (_pinOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<PinCodeDetails>(
                  value: _selectedPinOption,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Post Office / Area (${_pinOptions.length} available)',
                    prefixIcon: Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _pinOptions.map((opt) {
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
                      _onSelectLocation(selected);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              const Text('Invoice Display Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Show Phone Number on Invoices'),
                subtitle: const Text('Display phone number in firm header on PDF'),
                value: _showPhoneOnInvoice,
                onChanged: (val) => setState(() => _showPhoneOnInvoice = val),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Show GSTIN on Invoices'),
                subtitle: const Text('Display GSTIN number in firm header on PDF'),
                value: _showGstinOnInvoice,
                onChanged: (val) => setState(() => _showGstinOnInvoice = val),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Show Email Address on Invoices'),
                subtitle: const Text('Display email address in firm header on PDF'),
                value: _showEmailOnInvoice,
                onChanged: (val) => setState(() => _showEmailOnInvoice = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Default Firm'),
                subtitle: const Text('Use this firm for new invoices by default'),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Firm',
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

  Widget _buildImagePickerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildImagePicker(
          title: 'Firm Logo',
          path: _logoPath,
          onTap: () => _pickImage(true),
        ),
        _buildImagePicker(
          title: 'Signature',
          path: _signaturePath,
          onTap: _showSignaturePickerOptions,
        ),
      ],
    );
  }

  void _showSignaturePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Authorized Signature', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.draw_rounded, color: AppColors.primaryBlue),
              ),
              title: const Text('Draw Digital Signature'),
              subtitle: const Text('Sign directly on screen with finger or mouse'),
              onTap: () async {
                Navigator.pop(ctx);
                final String? result = await showDialog<String>(
                  context: context,
                  builder: (context) => const DigitalSignatureDialog(),
                );
                if (result != null && mounted) {
                  setState(() => _signaturePath = result);
                  final uploadedUrl = await ApiService.uploadSignature(result);
                  if (uploadedUrl != null && mounted) {
                    setState(() => _signaturePath = uploadedUrl);
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
              ),
              title: const Text('Upload Signature Image'),
              subtitle: const Text('Choose PNG/JPG image file from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({required String title, String? path, required VoidCallback onTap}) {
    Widget? imageWidget;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        imageWidget = Image.network(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (path.startsWith('data:image')) {
        try {
          final bytes = base64Decode(path.split(',').last);
          imageWidget = Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {}
      } else {
        try {
          final file = File(path);
          if (file.existsSync()) {
            imageWidget = Image.file(file, fit: BoxFit.cover);
          }
        } catch (_) {}
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageWidget ??
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: AppColors.primaryBlue, size: 32),
                    SizedBox(height: 8),
                    Text('Upload / Draw', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
