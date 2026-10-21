import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/repos/data/git_provider_factory.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/item_detail_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';
import 'package:repo_sphere/features/repos/presentation/screens/item_detail_screen.dart';

import 'package:repo_sphere/l10n/app_localizations.dart';

import '../support/fake_provider.dart';

Future<FakeProvider> _pump(WidgetTester t,
    {ItemDetail? detail, Object? error}) async {
  final p = FakeProvider(
    ghConn,
    capabilities: const ProviderCapabilities(
        inbox: true, itemDetail: true, approvePullRequests: true),
    detail: detail,
  )..detailError = error;
  final i = item(ghConn, 42, 'Fix checkout', [InboxReason.ciFailed],
      repo: 'acme/shop');
  await t.pumpWidget(ProviderScope(
    overrides: [
      activeProvidersProvider.overrideWithValue([p])
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ItemDetailScreen(item: i),
    ),
  ));
  await t.pumpAndSettle();
  return p;
}

void main() {
  final detail = ItemDetail(
    title: 'Fix checkout race',
    body: 'Fixes the **double charge**.',
    authorLogin: 'bob',
    state: 'open',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    headBranch: 'fix/race',
    baseBranch: 'main',
    files: const [
      DiffFile(
        path: 'lib/cart.dart',
        status: 'modified',
        additions: 1,
        deletions: 1,
        patch: '@@ -1 +1 @@\n-old line\n+new line',
      ),
      DiffFile(path: 'logo.png', status: 'added', additions: 0, deletions: 0),
    ],
    comments: [
      DetailComment(
          authorLogin: 'amy',
          body: 'Nice catch',
          createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    ],
  );

  testWidgets('shows description, branches, files and discussion', (t) async {
    await _pump(t, detail: detail);

    expect(find.text('acme/shop#42'), findsOneWidget);
    expect(find.text('Fix checkout race'), findsOneWidget);
    expect(find.text('fix/race  →  main'), findsOneWidget);
    expect(find.textContaining('Files changed · 2'), findsOneWidget);
    expect(find.text('lib/cart.dart'), findsOneWidget);
    expect(find.text('Discussion · 1'), findsOneWidget);
    expect(find.textContaining('Nice catch'), findsOneWidget);
    expect(find.text('CI failed'), findsOneWidget); // why it is in the inbox
  });

  testWidgets('expanding a file reveals its diff; binary files explain why',
      (t) async {
    await _pump(t, detail: detail);
    await t.scrollUntilVisible(find.text('lib/cart.dart'), 200,
        scrollable: find.byType(Scrollable).first);

    expect(find.text('+new line'), findsNothing); // collapsed by default
    await t.tap(find.text('lib/cart.dart'));
    await t.pumpAndSettle();
    expect(find.text('+new line'), findsOneWidget);
    expect(find.text('-old line'), findsOneWidget);

    await t.tap(find.text('logo.png'));
    await t.pumpAndSettle();
    expect(find.textContaining('No diff available'), findsOneWidget);
  });

  testWidgets('a load failure shows the reason and can retry', (t) async {
    await _pump(t, error: const GitHubApiException('Resource not found.'));
    expect(find.text('Resource not found.'), findsOneWidget);
  });

  testWidgets('the Actions button opens the quick-action sheet', (t) async {
    await _pump(t, detail: detail);
    await t.tap(find.text('Actions'));
    await t.pumpAndSettle();
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Open in browser'), findsWidgets);
  });
}
