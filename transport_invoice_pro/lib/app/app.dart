import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/services/user_session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_toast.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

/// Root Application Widget for Transport Invoice Pro.
/// Integrates Riverpod, GoRouter, and Material 3 Design System.
class TransportInvoiceProApp extends ConsumerStatefulWidget {
  const TransportInvoiceProApp({super.key});

  @override
  ConsumerState<TransportInvoiceProApp> createState() => _TransportInvoiceProAppState();
}

class _TransportInvoiceProAppState extends ConsumerState<TransportInvoiceProApp> {
  StreamSubscription<void>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    _sessionExpiredSubscription = UserSession.onSessionExpired.listen((_) {
      ref.read(authControllerProvider.notifier).invalidateAllProviders();
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        navContext.goNamed(RouteNames.login);
        AppToast.showError(navContext, 'Your session has expired. Please log in again.');
      }
    });
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
