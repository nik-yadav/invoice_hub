import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/services/user_session.dart';
import '../../../../core/widgets/app_loading_indicator.dart';

/// Application Splash Screen.
/// Displays app branding while async initialization completes and redirects based on UserSession.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    if (UserSession.isLoggedIn) {
      context.goNamed(RouteNames.dashboard);
    } else {
      context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: UIConstants.borderRadiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: UIConstants.spacing24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing8),
            Text(
              'Enterprise Transport Management & Invoicing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: UIConstants.spacing48),
            const AppLoadingIndicator(
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
