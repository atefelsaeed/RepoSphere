import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/presentation/widgets/account_connect_form.dart';
import 'package:repo_sphere/l10n/app_localizations.dart';

void main() {
  group('normalizeInstanceUrl', () {
    test('adds https, trims and drops trailing slashes', () {
      expect(normalizeInstanceUrl('  gitlab.client.com/ '),
          'https://gitlab.client.com');
      expect(normalizeInstanceUrl('https://git.example.org///'),
          'https://git.example.org');
    });

    test('keeps an explicit scheme and port', () {
      expect(
          normalizeInstanceUrl('http://10.0.0.5:8080'), 'http://10.0.0.5:8080');
    });

    test('empty stays empty', () {
      expect(normalizeInstanceUrl('   '), '');
    });
  });

  group('tokenHelp', () {
    test('Gitea points at the instance settings (Codeberg by default)', () {
      expect(tokenHelp(GitProviderType.gitea, '').url.host, 'codeberg.org');
      final own = tokenHelp(GitProviderType.gitea, 'https://git.acme.io');
      expect(own.url.path, '/user/settings/applications');
      expect(own.url.host, 'git.acme.io');
    });

    test('GitLab points at the self-hosted instance, else gitlab.com', () {
      expect(tokenHelp(GitProviderType.gitlab, '').url.host, 'gitlab.com');
      final own = tokenHelp(GitProviderType.gitlab, 'https://git.acme.io');
      expect(own.url.host, 'git.acme.io');
      expect(own.scopes, 'api, read_user');
    });

    test('Azure links to the organisation token page', () {
      final h =
          tokenHelp(GitProviderType.azureDevOps, 'https://dev.azure.com/acme');
      expect(h.url.path, '/acme/_usersSettings/tokens');
    });
  });

  group('AccountConnectForm', () {
    Future<void> pump(WidgetTester t) => t.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccountConnectForm(onConnect: (_) async {}),
            ),
          ),
        ));

    testWidgets('offers all three providers; GitHub has no URL field',
        (t) async {
      await pump(t);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('GitLab'), findsOneWidget);
      expect(find.text('Azure DevOps'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget); // button only
    });

    testWidgets('GitLab shows an optional self-hosted URL field', (t) async {
      await pump(t);
      await t.tap(find.text('GitLab'));
      await t.pump();
      expect(find.textContaining('Self-hosted GitLab URL'), findsOneWidget);
      expect(find.text('Create a token on GitLab'), findsOneWidget);
    });

    testWidgets('Azure requires an organisation URL', (t) async {
      await pump(t);
      await t.tap(find.text('Azure DevOps'));
      await t.pump();
      await t.enterText(find.byType(TextField).last, 'azure-pat-token');
      await t.tap(find.text('Connect'));
      await t.pump();
      expect(
          find.text('Azure DevOps needs an organisation URL.'), findsOneWidget);
    });

    testWidgets('Forgejo / Gitea needs a server URL', (t) async {
      await pump(t);
      expect(find.text('Gitea / Forgejo'), findsOneWidget);
      await t.tap(find.text('Gitea / Forgejo'));
      await t.pump();
      expect(find.textContaining('Forgejo / Gitea URL'), findsOneWidget);
      await t.enterText(find.byType(TextField).last, 'a-token');
      await t.tap(find.text('Connect'));
      await t.pump();
      expect(find.text('Forgejo / Gitea needs the server URL.'), findsOneWidget);
    });

    testWidgets('empty token is rejected', (t) async {
      await pump(t);
      await t.tap(find.text('Connect'));
      await t.pump();
      expect(find.text('Enter a token.'), findsOneWidget);
    });
  });
}
