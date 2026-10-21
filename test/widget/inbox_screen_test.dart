import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/auth/presentation/providers/connections_provider.dart';
import 'package:repo_sphere/features/repos/data/git_provider_factory.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';
import 'package:repo_sphere/features/repos/presentation/screens/inbox_screen.dart';
import 'package:repo_sphere/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_provider.dart';

class _Conns extends ConnectionsNotifier {
  @override
  Future<List<GitConnection>> build() async => const [ghConn, glConn];
}

String? _pushed;

Future<void> _pump(WidgetTester t, List<FakeProvider> providers) async {
  SharedPreferences.setMockInitialValues({});
  _pushed = null;
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const InboxScreen(),
      routes: [
        GoRoute(
          path: 'item',
          name: 'inbox-item',
          builder: (_, s) {
            _pushed = (s.extra as InboxItem).title;
            return const Scaffold(body: Text('DETAIL SCREEN'));
          },
        ),
        GoRoute(
            path: 'repos', name: 'repos', builder: (_, __) => const SizedBox()),
        GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (_, __) => const SizedBox()),
        GoRoute(
            path: 'workspaces',
            name: 'workspaces',
            builder: (_, __) => const SizedBox()),
      ],
    ),
  ]);
  await t.pumpWidget(ProviderScope(
    overrides: [
      connectionsProvider.overrideWith(_Conns.new),
      activeProvidersProvider.overrideWithValue(providers),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  final full = ProviderCapabilities(
      inbox: true,
      itemDetail: true,
      approvePullRequests: true,
      requestChanges: true,
      mergePullRequests: true,
      rerunCi: true);

  testWidgets('lists items by urgency and shows counts per reason', (t) async {
    await _pump(t, [
      FakeProvider(ghConn,
          capabilities: full,
          items: InboxItem.mergeAndSort([
            item(ghConn, 1, 'Mention me', [InboxReason.mentioned]),
            item(ghConn, 2, 'Broken build', [InboxReason.ciFailed]),
            item(ghConn, 3, 'Please review', [InboxReason.reviewRequested]),
          ])),
    ]);

    final broken = t.getTopLeft(find.text('Broken build')).dy;
    final review = t.getTopLeft(find.text('Please review')).dy;
    final mention = t.getTopLeft(find.text('Mention me')).dy;
    expect(broken < review && review < mention, isTrue);
    expect(find.text('Everything · 3'), findsOneWidget);
    expect(find.text('CI failed · 1'), findsOneWidget);
  });

  testWidgets('reason chip filters the list', (t) async {
    await _pump(t, [
      FakeProvider(ghConn, capabilities: full, items: [
        item(ghConn, 1, 'Broken build', [InboxReason.ciFailed]),
        item(ghConn, 2, 'Please review', [InboxReason.reviewRequested]),
      ]),
    ]);

    await t.tap(find.text('CI failed · 1'));
    await t.pumpAndSettle();

    expect(find.text('Broken build'), findsOneWidget);
    expect(find.text('Please review'), findsNothing);
  });

  testWidgets('empty inbox says you are all caught up', (t) async {
    await _pump(t, [FakeProvider(ghConn, capabilities: full)]);
    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('a failing account shows its reason, not a false all-clear',
      (t) async {
    await _pump(t, [
      FakeProvider(ghConn, capabilities: full)
        ..inboxError = const GitHubRateLimitException(
            'Rate limit exceeded. Resets in 5m.'),
      FakeProvider(glConn, capabilities: full, items: [
        item(glConn, 7, 'GitLab thing', [InboxReason.assigned]),
      ]),
    ]);

    expect(find.text('GitLab thing'), findsOneWidget);
    expect(find.textContaining('Rate limit exceeded'), findsOneWidget);
    expect(find.text("You're all caught up"), findsNothing);
  });

  testWidgets('partial results warn that some may be missing', (t) async {
    await _pump(t, [
      FakeProvider(ghConn, capabilities: full)
        ..batch = () => InboxBatch(
              [
                item(ghConn, 1, 'Only this loaded', [InboxReason.ciFailed])
              ],
              const [GitHubApiException('Search failed.')],
            ),
    ]);

    expect(find.text('Only this loaded'), findsOneWidget);
    expect(find.textContaining('may be missing'), findsOneWidget);
  });

  testWidgets('tap opens the detail screen when the provider supports it',
      (t) async {
    await _pump(t, [
      FakeProvider(ghConn, capabilities: full, items: [
        item(ghConn, 1, 'Broken build', [InboxReason.ciFailed]),
      ]),
    ]);

    await t.tap(find.text('Broken build'));
    await t.pumpAndSettle();

    expect(find.text('DETAIL SCREEN'), findsOneWidget);
    expect(_pushed, 'Broken build');
  });

  testWidgets('long-press opens actions; only supported ones are offered',
      (t) async {
    await _pump(t, [
      FakeProvider(
        glConn,
        // GitLab: no "request changes".
        capabilities: const ProviderCapabilities(
            inbox: true,
            itemDetail: true,
            approvePullRequests: true,
            mergePullRequests: true,
            rerunCi: true),
        items: [
          item(glConn, 4, 'Upgrade SDK', [InboxReason.ciFailed])
        ],
      ),
    ]);

    await t.longPress(find.text('Upgrade SDK'));
    await t.pumpAndSettle();

    expect(find.text('Re-run failed CI'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Request changes'), findsNothing);
  });

  testWidgets('approve asks for confirmation, then runs on the right account',
      (t) async {
    final gh = FakeProvider(ghConn, capabilities: full, items: [
      item(ghConn, 9, 'Review me', [InboxReason.reviewRequested]),
    ]);
    await _pump(t, [gh]);

    await t.longPress(find.text('Review me'));
    await t.pumpAndSettle();
    await t.tap(find.text('Approve'));
    await t.pumpAndSettle();
    expect(find.text('Approve?'), findsOneWidget);
    expect(gh.actions, isEmpty); // nothing happens before confirming

    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();

    expect(gh.actions, ['approve:9']);
  });
}
