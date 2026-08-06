import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/responsive_layout.dart';

/// Extension methods on BuildContext for quick access to Theme, MediaQuery, and Navigation.
extension ContextExtensions on BuildContext {
  // Theme Shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // MediaQuery Shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  // Device Responsive Shortcuts
  bool get isMobile => ResponsiveLayout.isMobile(this);
  bool get isTablet => ResponsiveLayout.isTablet(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);

  // Navigation Shortcuts
  void pushNamedLocation(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic> queryParameters = const {}}) {
    goNamed(name, pathParameters: pathParameters, queryParameters: queryParameters);
  }
}
