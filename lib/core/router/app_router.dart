import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/repos/domain/entities/commit_entity.dart';
import '../../features/repos/domain/entities/issue_entity.dart';
import '../../features/repos/domain/entities/pull_request_entity.dart';
import '../../features/repos/domain/entities/repo_entity.dart';
import '../../features/repos/presentation/screens/commit_detail_screen.dart';
import '../../features/repos/presentation/screens/file_viewer_screen.dart';
import '../../features/repos/presentation/screens/profile_screen.dart';
import '../../features/repos/presentation/screens/search_screen.dart';
import '../../features/repos/presentation/screens/repo_browser_screen.dart';
import '../../features/repos/presentation/screens/repo_commits_screen.dart';
import '../../features/repos/presentation/screens/repo_detail_screen.dart';
import '../../features/repos/presentation/screens/repo_issue_detail_screen.dart';
import '../../features/repos/presentation/screens/repo_issues_screen.dart';
import '../../features/repos/presentation/screens/repo_pr_detail_screen.dart';
import '../../features/repos/presentation/screens/repo_prs_screen.dart';
import '../../features/repos/presentation/screens/activity_screen.dart';
import '../../features/repos/presentation/screens/notifications_screen.dart';
import '../../features/repos/presentation/screens/repo_readme_screen.dart';
import '../../features/repos/presentation/screens/repo_releases_screen.dart';
import '../../features/repos/presentation/screens/gists_screen.dart';
import '../../features/repos/presentation/screens/repos_screen.dart';
import '../../features/repos/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/repos',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Route not found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.goNamed('repos'),
              icon: const Icon(Icons.home_rounded, size: 16),
              label: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/activity',
        name: 'activity',
        builder: (_, __) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/gists',
        name: 'gists',
        builder: (_, __) => const GistsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
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
              final extra = state.extra as ({RepoEntity repo, String path, String? branch});
              return RepoBrowserScreen(repo: extra.repo, path: extra.path, initialBranch: extra.branch);
            },
          ),
          GoRoute(
            path: ':id/commits',
            name: 'repo-commits',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, String? branch});
              return RepoCommitsScreen(
                repo: extra.repo,
                initialBranch: extra.branch,
              );
            },
          ),
          GoRoute(
            path: ':id/commit',
            name: 'commit-detail',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, CommitEntity commit});
              return CommitDetailScreen(repo: extra.repo, commit: extra.commit);
            },
          ),
          GoRoute(
            path: ':id/prs',
            name: 'repo-prs',
            builder: (_, state) =>
                RepoPrsScreen(repo: state.extra as RepoEntity),
          ),
          GoRoute(
            path: ':id/pr',
            name: 'pr-detail',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, PullRequestEntity pr});
              return RepoPrDetailScreen(repo: extra.repo, pr: extra.pr);
            },
          ),
          GoRoute(
            path: ':id/issues',
            name: 'repo-issues',
            builder: (_, state) =>
                RepoIssuesScreen(repo: state.extra as RepoEntity),
          ),
          GoRoute(
            path: ':id/issue',
            name: 'issue-detail',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, IssueEntity issue});
              return RepoIssueDetailScreen(
                  repo: extra.repo, issue: extra.issue);
            },
          ),
          GoRoute(
            path: ':id/readme',
            name: 'repo-readme',
            builder: (_, state) =>
                RepoReadmeScreen(repo: state.extra as RepoEntity),
          ),
          GoRoute(
            path: ':id/releases',
            name: 'repo-releases',
            builder: (_, state) =>
                RepoReleasesScreen(repo: state.extra as RepoEntity),
          ),
          GoRoute(
            path: ':id/file',
            name: 'file-viewer',
            builder: (_, state) {
              final extra =
                  state.extra as ({RepoEntity repo, String path, String name});
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
    _ref.listen<AsyncValue<String?>>(
        authProvider, (_, __) => notifyListeners());
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
