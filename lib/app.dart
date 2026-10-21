import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/connections_provider.dart';

class RepoSphereApp extends ConsumerWidget {
  const RepoSphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsState = ref.watch(connectionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    if (connectionsState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const _SplashScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (router.canPop()) router.pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: MaterialApp.router(
          title: 'RepoSphere',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          routerConfig: router,
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withAlpha(60),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.hub_rounded, size: 38, color: Colors.white),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            Text(
              'RepoSphere',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            )
                .animate(delay: 180.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, curve: Curves.easeOut),
            const SizedBox(height: 6),
            Text(
              'Your Git universe, one dashboard',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ).animate(delay: 280.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
