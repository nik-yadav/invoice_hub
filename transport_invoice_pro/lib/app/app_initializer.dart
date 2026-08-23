import 'package:flutter/material.dart';

import '../core/database/hive_service.dart';
import '../core/database/supabase_service.dart';
import '../core/services/user_session.dart';
import 'app_env.dart';

/// Class responsible for bootstrapping asynchronous framework services before runApp.
class AppInitializer {
  AppInitializer._();

  /// Executes all required asynchronous initializations in order.
  static Future<void> init({AppEnvironment? environment}) async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Environment Configuration
    AppEnv.initialize(environment: environment);

    // 2. Initialize Local Storage (Hive)
    await HiveService.init();

    // 3. Initialize User Session
    await UserSession.init();

    // 4. Initialize Cloud Backend (Supabase)
    await SupabaseService.init();
  }
}
