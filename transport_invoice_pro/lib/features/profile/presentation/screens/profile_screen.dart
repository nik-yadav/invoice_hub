import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../firms/presentation/providers/firm_provider.dart';
import '../../../firms/presentation/screens/firm_form_screen.dart';
import '../controllers/profile_controller.dart';

/// Premium presentation screen displaying personal profile data and managing firm profiles.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _buildThumb(String? path, {double size = 44, IconData fallback = Icons.business_rounded}) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('data:image')) {
        try {
          final bytes = base64Decode(path.split(',').last);
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, width: size, height: size, fit: BoxFit.contain),
          );
        } catch (_) {}
      } else {
        try {
          final file = File(path);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(file, width: size, height: size, fit: BoxFit.cover),
            );
          }
        } catch (_) {}
      }
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(fallback, color: AppColors.primaryBlue, size: size * 0.55),
    );
  }

  void _showEditPersonalProfileDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileControllerProvider);

    final fullNameController = TextEditingController(text: profile.fullName);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Personal Info'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Full Name',
                      controller: fullNameController,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: UIConstants.spacing12),
                    AppTextField(
                      label: 'Email Address',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: UIConstants.spacing12),
                    AppTextField(
                      label: 'Mobile Phone',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Save',
              width: 120,
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  await ref.read(profileControllerProvider.notifier).updateProfile(
                        fullName: fullNameController.text.trim(),
                        companyName: profile.companyName,
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        gstin: profile.gstin,
                        address: profile.address,
                        transportLicense: profile.transportLicense,
                      );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personal profile saved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openFirmFormModal(BuildContext context, {FirmModel? firm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: FirmFormScreen(firm: firm),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.goNamed(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider);
    final firmsState = ref.watch(firmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Firms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Personal Header Card
                AppCard(
                  color: theme.colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(UIConstants.spacing24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : 'U',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: UIConstants.spacing20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacing4),
                              Text(
                                profile.email.isNotEmpty ? profile.email : 'No email added',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacing4),
                              Text(
                                profile.phone.isNotEmpty ? profile.phone : 'No phone added',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.white),
                          tooltip: 'Edit Personal Info',
                          onPressed: () => _showEditPersonalProfileDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.spacing20),

                // 2. Personal Details Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Personal Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            onPressed: () => _showEditPersonalProfileDialog(context, ref),
                          ),
                        ],
                      ),
                      const Divider(height: UIConstants.spacing24),
                      _buildInfoTile(
                        context,
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: profile.fullName,
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: profile.email.isNotEmpty ? profile.email : 'Not specified',
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.phone_outlined,
                        title: 'Mobile Contact',
                        value: profile.phone.isNotEmpty ? profile.phone : 'Not specified',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacing24),

                // 3. Manage Firms Section (Inline)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage My Firms',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text('Add New Firm'),
                      onPressed: () => _openFirmFormModal(context),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacing12),

                // List of Registered Firms
                firmsState.when(
                  data: (firms) {
                    if (firms.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.business_outlined, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('No Firms Added Yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                'Create your transport firm profile to start generating professional invoices.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create Transport Firm'),
                                onPressed: () => _openFirmFormModal(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: firms.map((firm) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildThumb(firm.logoPath, size: 48, fallback: Icons.business_rounded),
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
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              if (firm.isDefault)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.green.shade700),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT FIRM',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Owner: ${firm.ownerName}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                                          if (firm.gstin.isNotEmpty)
                                            Text('GSTIN: ${firm.gstin}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${firm.address}${firm.city.isNotEmpty ? ", ${firm.city}" : ""}${firm.state.isNotEmpty ? ", ${firm.state}" : ""}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      firm.signaturePath != null && firm.signaturePath!.isNotEmpty
                                          ? Icons.draw_rounded
                                          : Icons.gesture_outlined,
                                      size: 16,
                                      color: firm.signaturePath != null && firm.signaturePath!.isNotEmpty
                                          ? Colors.green.shade700
                                          : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      firm.signaturePath != null && firm.signaturePath!.isNotEmpty
                                          ? 'Digital Signature Attached'
                                          : 'No Signature Added',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: firm.signaturePath != null && firm.signaturePath!.isNotEmpty
                                            ? Colors.green.shade700
                                            : AppColors.textSecondaryLight,
                                        fontWeight: firm.signaturePath != null && firm.signaturePath!.isNotEmpty
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (firm.signaturePath != null && firm.signaturePath!.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.white,
                                        ),
                                        child: _buildThumb(firm.signaturePath, size: 28, fallback: Icons.draw),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!firm.isDefault)
                                      TextButton.icon(
                                        icon: const Icon(Icons.star_outline, size: 16),
                                        label: const Text('Set as Default'),
                                        onPressed: () {
                                          ref.read(firmsProvider.notifier).updateFirm(firm.copyWith(isDefault: true));
                                        },
                                      ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text('Edit'),
                                      onPressed: () => _openFirmFormModal(context, firm: firm),
                                    ),
                                    if (!firm.isDefault)
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                        label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Firm Profile?'),
                                              content: Text('Are you sure you want to delete ${firm.businessName}?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(firmsProvider.notifier).deleteFirm(firm.id);
                                          }
                                        },
                                      )
                                    else
                                      Tooltip(
                                        message: 'Default firm cannot be deleted',
                                        child: TextButton.icon(
                                          icon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                          label: const Text('Default Protected', style: TextStyle(color: Colors.grey)),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Default firm cannot be deleted. Please set another firm as default first.'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error loading firms: $e'),
                ),
                const SizedBox(height: UIConstants.spacing24),

                // Location & Address Settings Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location & Address Settings',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: UIConstants.spacing24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: Container(
                          padding: const EdgeInsets.all(UIConstants.spacing8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: UIConstants.borderRadiusCircular,
                          ),
                          child: Icon(Icons.markunread_mailbox_outlined, color: theme.colorScheme.primary, size: 20),
                        ),
                        title: const Text('Select Post Office for PIN Codes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text(
                          'When enabled, entering a 6-digit PIN code allows selecting a specific post office/area. When disabled, only City and State are used in detailed address.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: profile.enablePostOfficeSelection,
                        onChanged: (val) {
                          ref.read(profileControllerProvider.notifier).togglePostOfficeSelection(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacing24),

                // 4. System & App Info Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System & Storage Info', style: theme.textTheme.titleMedium),
                      const Divider(height: UIConstants.spacing24),
                      _buildInfoTile(
                        context,
                        icon: Icons.cloud_done_outlined,
                        title: 'API Backend Engine',
                        value: 'Node.js Express & Prisma ORM Active',
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.info_outline,
                        title: 'App Version',
                        value: '${AppConstants.appName} v${AppConstants.appVersion} (${AppConstants.buildNumber})',
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.copyright_rounded,
                        title: 'Legal Copyright',
                        value: AppConstants.copyrightNotice,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacing24),

                // 5. Sign Out Button
                AppButton(
                  text: 'Sign Out Account',
                  icon: Icons.logout_rounded,
                  onPressed: () => _handleLogout(context, ref),
                ),
                const SizedBox(height: UIConstants.spacing20),

                // 6. Dynamic Footer Copyright
                Center(
                  child: Text(
                    AppConstants.copyrightNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.spacing16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : UIConstants.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: UIConstants.borderRadiusCircular,
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: UIConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
