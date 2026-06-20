import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repo_sphere/app.dart';
import 'package:repo_sphere/features/auth/presentation/providers/auth_provider.dart';

/// Fake auth notifier that resolves synchronously to a signed-out state,
/// so the app skips the secure-storage platform channel (unavailable in tests)
/// and deterministically renders the router instead of the loading splash.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => null;
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuthNotifier.new),
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
