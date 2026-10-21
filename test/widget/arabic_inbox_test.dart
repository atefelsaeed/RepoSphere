import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/auth/presentation/providers/connections_provider.dart';
import 'package:repo_sphere/features/repos/data/git_provider_factory.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';
import 'package:repo_sphere/features/repos/presentation/screens/inbox_screen.dart';
import 'package:repo_sphere/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_provider.dart';

class _Conns extends ConnectionsNotifier {
  @override
  Future<List<GitConnection>> build() async => const [ghConn];
}

Future<void> _pump(WidgetTester t, List<InboxItem> items) async {
  SharedPreferences.setMockInitialValues({});
  registerTimeagoLocales();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const InboxScreen()),
  ]);
  await t.pumpWidget(ProviderScope(
    overrides: [
      connectionsProvider.overrideWith(_Conns.new),
      activeProvidersProvider.overrideWithValue([
        FakeProvider(ghConn,
            capabilities: const ProviderCapabilities(
                inbox: true, itemDetail: true, approvePullRequests: true),
            items: items),
      ]),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Inbox renders in Arabic, right-to-left', (t) async {
    await _pump(t, [
      item(ghConn, 1, 'Fix build', [InboxReason.ciFailed]),
      item(ghConn, 2, 'Review me', [InboxReason.reviewRequested]),
    ]);

    expect(find.text('الوارد'), findsOneWidget);
    expect(find.text('كل شيء · 2'), findsOneWidget);
    expect(find.text('فشل CI · 1'), findsOneWidget);
    expect(find.text('مطلوب مراجعتك'), findsWidgets);
    // Layout direction comes from the language.
    final dir = Directionality.of(t.element(find.text('الوارد')));
    expect(dir, TextDirection.rtl);
    // Relative time is Arabic too (not "1 hour ago").
    expect(find.textContaining('hour'), findsNothing);
  });

  testWidgets('empty Arabic inbox', (t) async {
    await _pump(t, const []);
    expect(find.text('لا شيء يحتاج انتباهك'), findsOneWidget);
  });

  testWidgets('quick actions are Arabic and confirm text names the PR',
      (t) async {
    await _pump(t, [
      item(ghConn, 7, 'Review me', [InboxReason.reviewRequested]),
    ]);
    await t.longPress(find.text('Review me'));
    await t.pumpAndSettle();

    expect(find.text('موافقة'), findsOneWidget);
    await t.tap(find.text('موافقة'));
    await t.pumpAndSettle();
    expect(find.textContaining('acme/app #7'), findsOneWidget);
    expect(find.text('تأكيد'), findsOneWidget);
  });
}
