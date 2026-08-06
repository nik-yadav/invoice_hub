import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_error_widget.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/placeholder_tab_screen.dart';
import '../../features/dashboard/presentation/widgets/dashboard_overview_tab.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/firms/domain/models/firm_model.dart';
import '../../features/firms/presentation/screens/firm_list_screen.dart';
import '../../features/firms/presentation/screens/firm_form_screen.dart';
import '../../features/customers/domain/models/customer_model.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/vehicles/domain/models/vehicle_model.dart';
import '../../features/vehicles/presentation/screens/vehicle_list_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_form_screen.dart';
import '../../features/invoices/domain/models/invoice_model.dart';
import '../../features/invoices/presentation/screens/invoice_list_screen.dart';
import '../../features/invoices/presentation/screens/invoice_form_screen.dart';
import '../../features/invoices/presentation/screens/invoice_preview_screen.dart';
import 'route_names.dart';

/// Global Key for Root Navigator.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Riverpod provider delivering GoRouter instance configured with authentication routes.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboardPath,
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardOverviewTab(),
              ),
            ],
          ),
          // Branch 1: Invoices
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.invoicesPath,
                name: RouteNames.invoices,
                builder: (context, state) => const InvoiceListScreen(),
              ),
            ],
          ),
          // Branch 2: Vehicles
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.vehiclesPath,
                name: RouteNames.vehicles,
                builder: (context, state) => const VehicleListScreen(),
              ),
            ],
          ),
          // Branch 3: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.customersPath,
                name: RouteNames.customers,
                builder: (context, state) => const CustomerListScreen(),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // Standalone Full-Screen Routes for sub-screens
      GoRoute(
        path: RouteNames.firmsPath,
        name: RouteNames.firms,
        builder: (context, state) => const FirmListScreen(),
      ),
      GoRoute(
        path: RouteNames.addFirmPath,
        name: RouteNames.addFirm,
        builder: (context, state) => const FirmFormScreen(),
      ),
      GoRoute(
        path: RouteNames.editFirmPath,
        name: RouteNames.editFirm,
        builder: (context, state) {
          final firm = state.extra as FirmModel;
          return FirmFormScreen(firm: firm);
        },
      ),
      GoRoute(
        path: RouteNames.addCustomerPath,
        name: RouteNames.addCustomer,
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: RouteNames.editCustomerPath,
        name: RouteNames.editCustomer,
        builder: (context, state) {
          final customer = state.extra as CustomerModel;
          return CustomerFormScreen(customer: customer);
        },
      ),
      GoRoute(
        path: RouteNames.addVehiclePath,
        name: RouteNames.addVehicle,
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: RouteNames.editVehiclePath,
        name: RouteNames.editVehicle,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel;
          return VehicleFormScreen(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: RouteNames.addInvoicePath,
        name: RouteNames.addInvoice,
        builder: (context, state) {
          final invoice = state.extra as InvoiceModel?;
          return InvoiceFormScreen(invoice: invoice);
        },
      ),
      GoRoute(
        path: RouteNames.editInvoicePath,
        name: RouteNames.editInvoice,
        builder: (context, state) {
          final invoice = state.extra as InvoiceModel;
          return InvoiceFormScreen(invoice: invoice);
        },
      ),
      GoRoute(
        path: RouteNames.previewInvoicePath,
        name: RouteNames.previewInvoice,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return InvoicePreviewScreen(
            invoice: extra['invoice'] as InvoiceModel,
            firm: extra['firm'] as FirmModel,
            customer: extra['customer'] as CustomerModel,
            vehicle: extra['vehicle'] as VehicleModel,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: AppErrorWidget(
        title: 'Page Not Found',
        message: 'The requested route "${state.uri.path}" could not be located.',
        onRetry: () => context.goNamed(RouteNames.dashboard),
        retryText: 'Go to Dashboard',
      ),
    ),
  );
});
