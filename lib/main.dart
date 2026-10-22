import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'l10n/l10n.dart';
import 'features/auth/data/secure_token_storage.dart';
import 'features/notifications/background_inbox_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  try {
    // Before anything reads tokens; never throws, retried next launch on failure.
    await SecureTokenStorage.migrateKeychain();
    await initBackgroundWork();
  } on Object {
    // Background alerts are optional; never block app start.
  }

  final prefs = await SharedPreferences.getInstance();
  final themeStr = prefs.getString('themeMode') ?? 'system';
  final initialTheme = switch (themeStr) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  registerTimeagoLocales();
  final initialLocale = localeFromPref(prefs.getString(localePrefKey));

  final app = ProviderScope(
    overrides: [
      themeModeProvider.overrideWith((ref) => initialTheme),
      localeProvider.overrideWith((ref) => initialLocale),
    ],
    child: const RepoSphereApp(),
  );

  if (AppConfig.hasSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 0.2;
        // Request URLs carry private repo / PR names: keep them out of reports.
        options.beforeBreadcrumb = (breadcrumb, hint) =>
            breadcrumb?.category == 'http' ? null : breadcrumb;
        options.environment = const bool.fromEnvironment('dart.vm.product')
            ? 'production'
            : 'debug';
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}
