import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/l10n/l10n.dart';
import 'package:repo_sphere/shared/widgets/remote_markdown_image.dart';

void main() {
  testWidgets('a remote image is not fetched until the reader taps', (t) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: remoteMarkdownImage(
            Uri.parse('https://tracker.example/pixel.png'), null, 'pixel'),
      ),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Load image from tracker.example'), findsOneWidget);
  });
}
