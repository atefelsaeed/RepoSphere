import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/l10n/l10n.dart';
import 'package:repo_sphere/shared/widgets/error_view.dart';

Future<void> _pump(WidgetTester t, Locale locale, Object error) =>
    t.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ErrorView(error: error, onRetry: () {})),
    ));

void main() {
  const err = GitHubApiException('Resource not found.');

  testWidgets('English keeps the message and Retry', (t) async {
    await _pump(t, const Locale('en'), err);
    expect(find.text('Resource not found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Arabic translates the known message and the Retry button',
      (t) async {
    await _pump(t, const Locale('ar'), err);
    expect(find.text('المورد غير موجود.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
