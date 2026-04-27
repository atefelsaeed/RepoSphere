import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/utils/exceptions.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final themeStr = prefs.getString('themeMode') ?? 'system';
  final initialTheme = switch (themeStr) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  final app = ProviderScope(
    observers: [_AuthErrorObserver()],
    overrides: [
      themeModeProvider.overrideWith((ref) => initialTheme),
    ],
    child: const RepoSphereApp(),
  );

  if (AppConfig.hasSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment =
            const bool.fromEnvironment('dart.vm.product') ? 'production' : 'debug';
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}

/// Watches every provider for [GitHubAuthException] and auto-logs out.
class _AuthErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (error is GitHubAuthException) {
      container.read(authProvider.notifier).logout();
    }
  }
}
