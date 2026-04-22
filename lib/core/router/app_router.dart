import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/repos/domain/entities/repo_entity.dart';
import '../../features/repos/presentation/screens/file_viewer_screen.dart';
import '../../features/repos/presentation/screens/repo_browser_screen.dart';
import '../../features/repos/presentation/screens/repo_detail_screen.dart';
import '../../features/repos/presentation/screens/repos_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/repos',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/repos',
        name: 'repos',
        builder: (_, __) => const ReposScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'repo-detail',
            builder: (_, state) =>
                RepoDetailScreen(repo: state.extra as RepoEntity),
          ),
          GoRoute(
            path: ':id/browse',
            name: 'repo-browser',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, String path});
              return RepoBrowserScreen(
                  repo: extra.repo, path: extra.path);
            },
          ),
          GoRoute(
            path: ':id/file',
            name: 'file-viewer',
            builder: (_, state) {
              final extra = state.extra
                  as ({RepoEntity repo, String path, String name});
              return FileViewerScreen(
                repo: extra.repo,
                path: extra.path,
                name: extra.name,
              );
            },
          ),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<String?>>(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    if (authState.isLoading) return null;

    final isAuthenticated = authState.valueOrNull?.isNotEmpty == true;
    final isOnAuth = state.matchedLocation == '/auth';

    if (!isAuthenticated && !isOnAuth) return '/auth';
    if (isAuthenticated && isOnAuth) return '/repos';
    return null;
  }
}
