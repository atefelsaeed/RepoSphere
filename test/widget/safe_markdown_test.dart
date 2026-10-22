import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/l10n/l10n.dart';
import 'package:repo_sphere/shared/widgets/safe_markdown.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  const body = 'hello\n\n![pixel](https://tracker.example/pixel.png)';

  testWidgets('SafeMarkdownBody does not fetch images until tapped', (t) async {
    await t.pumpWidget(_app(const SafeMarkdownBody(data: body)));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Load image from tracker.example'), findsOneWidget);
  });

  testWidgets('SafeMarkdown does not fetch images until tapped', (t) async {
    await t.pumpWidget(_app(const SizedBox(
      height: 400,
      child: SafeMarkdown(data: body),
    )));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Load image from tracker.example'), findsOneWidget);
  });

  // Guard: a new screen that renders other people's Markdown with the raw
  // package widgets would silently bring back tracking images and unchecked
  // link schemes. Everything must go through safe_markdown.dart.
  test('lib/ renders Markdown only through SafeMarkdown widgets', () {
    final raw = RegExp(r'(?<![A-Za-z])(MarkdownBody|Markdown)\(');
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.endsWith('safe_markdown.dart')) continue;
      if (raw.hasMatch(f.readAsStringSync())) offenders.add(f.path);
    }
    expect(offenders, isEmpty,
        reason: 'Use SafeMarkdownBody / SafeMarkdown instead of the raw '
            'flutter_markdown_plus widgets in: $offenders');
  });
}
