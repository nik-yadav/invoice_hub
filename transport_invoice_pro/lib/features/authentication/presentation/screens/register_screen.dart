import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_header.dart';

/// Presentation screen for User & Transport Business Registration.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final success = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          companyName: _companyNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to Transport Invoice Pro.'),
          backgroundColor: Colors.green,
        ),
      );
      context.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final errorMessage = next.error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Create Account',
                subtitle: 'Register your transport firm to start issuing invoices',
              ),
              const SizedBox(height: UIConstants.spacing24),
              AppTextField(
                label: 'Full Name',
                hint: 'John Doe',
                controller: _fullNameController,
                validator: (value) => Validators.validateRequired(value, fieldName: 'Full Name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: UIConstants.spacing16),
              AppTextField(
                label: 'Transport / Company Name',
                hint: 'Logistics India Pvt Ltd',
                controller: _companyNameController,
                validator: (value) => Validators.validateRequired(value, fieldName: 'Company Name'),
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              const SizedBox(height: UIConstants.spacing16),
              AppTextField(
                label: 'Mobile Number',
                hint: '9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: UIConstants.spacing16),
              AppTextField(
                label: 'Email Address',
                hint: 'name@transportcompany.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: UIConstants.spacing16),
              AppTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacing16),
              AppTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.lock_clock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacing24),
              AppButton(
                text: 'Create Account',
                onPressed: _handleRegister,
                isLoading: isLoading,
              ),
              const SizedBox(height: UIConstants.spacing24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context.goNamed(RouteNames.login),
                    child: Text(
                      'Sign In',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
}
