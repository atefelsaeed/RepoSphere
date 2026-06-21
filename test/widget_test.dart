import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repo_sphere/app.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/auth/presentation/providers/connections_provider.dart';

/// Fake connections notifier that resolves synchronously to "no accounts",
/// so the app skips the secure-storage platform channel (unavailable in tests)
/// and deterministically renders the auth route instead of the loading splash.
class _FakeConnectionsNotifier extends ConnectionsNotifier {
  @override
  Future<List<GitConnection>> build() async => const [];
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionsProvider.overrideWith(_FakeConnectionsNotifier.new),
        ],
        child: const RepoSphereApp(),
      ),
    );

    // Flush flutter_animate timers and the auth redirect so no Timer
    // stays pending after the widget tree is disposed.
    await tester.pumpAndSettle();

    expect(find.byType(RepoSphereApp), findsOneWidget);
  });
}
