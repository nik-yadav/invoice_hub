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

/// Presentation screen for Requesting Password Reset Link.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final success = await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
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
                title: 'Reset Password',
                subtitle: 'Enter your registered email address to receive password reset instructions',
              ),
              const SizedBox(height: UIConstants.spacing24),
              if (_emailSent) ...[
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: UIConstants.borderRadiusMedium,
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 36),
                      const SizedBox(height: UIConstants.spacing8),
                      Text(
                        'Password Reset Email Sent!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacing4),
                      Text(
                        'We have sent password recovery instructions to ${_emailController.text}. Please check your inbox.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacing24),
                AppButton(
                  text: 'Back to Sign In',
                  onPressed: () => context.goNamed(RouteNames.login),
                ),
              ] else ...[
                AppTextField(
                  label: 'Email Address',
                  hint: 'name@transportcompany.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: UIConstants.spacing24),
                AppButton(
                  text: 'Send Reset Link',
                  onPressed: _handleResetPassword,
                  isLoading: isLoading,
                ),
                const SizedBox(height: UIConstants.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remembered your password? ',
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
            ],
          ),
        ),
      ),
    );
  }
}
