import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_env.dart';
import 'app/app_initializer.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    // Bootstrap async application services
    await AppInitializer.init(environment: AppEnvironment.dev);

    // Global error listener for Flutter framework UI errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('Flutter UI Error: ${details.exceptionAsString()}');
      }
    };

    runApp(
      const ProviderScope(
        child: TransportInvoiceProApp(),
      ),
    );
  }, (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Unhandled Zone Error: $error\n$stackTrace');
    }
  });
}
