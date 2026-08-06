import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

/// Screen device type enumeration.
enum DeviceType { mobile, tablet, desktop }

/// Responsive layout helper widget and device breakpoint utility.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Check if the screen width is mobile sized.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < UIConstants.mobileBreakpoint;

  /// Check if the screen width is tablet sized.
  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width >= UIConstants.mobileBreakpoint && width < UIConstants.tabletBreakpoint;
  }

  /// Check if the screen width is desktop sized.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= UIConstants.tabletBreakpoint;

  /// Get current device type based on breakpoints.
  static DeviceType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width < UIConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < UIConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Value chooser based on device type.
  static T valueForDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final device = getDeviceType(context);
    switch (device) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= UIConstants.tabletBreakpoint) {
          return desktop;
        }
        if (constraints.maxWidth >= UIConstants.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
