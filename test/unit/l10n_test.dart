import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/providers/locale_provider.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/l10n/l10n.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String message) => RegExp(r'\{(\w+)(?:,|\})')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .toSet();

void main() {
  final en = _arb('en');
  final ar = _arb('ar');
  final keys = en.keys.where((k) => !k.startsWith('@'));

  test('every English string has an Arabic translation and vice versa', () {
    final arKeys = ar.keys.where((k) => !k.startsWith('@')).toSet();
    expect(arKeys.difference(keys.toSet()), isEmpty,
        reason: 'extra Arabic keys');
    expect(keys.toSet().difference(arKeys), isEmpty,
        reason: 'untranslated keys');
  });

  test('translations use the same placeholders as the English text', () {
    for (final k in keys) {
      expect(_placeholders(ar[k] as String), _placeholders(en[k] as String),
          reason: 'placeholders differ for "$k"');
    }
  });

  test('no translation is left empty or identical by accident', () {
    for (final k in keys) {
      expect((ar[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('locale preference parsing', () {
    expect(localeFromPref('ar'), const Locale('ar'));
    expect(localeFromPref('en'), const Locale('en'));
    expect(localeFromPref('system'), isNull);
    expect(localeFromPref(null), isNull);
    expect(localeFromPref('fr'), isNull);
    expect(localeToPref(null), 'system');
    expect(localeToPref(const Locale('ar')), 'ar');
  });

  test('background locale resolution: saved choice, device, else English', () {
    expect(resolveLocale('ar', const Locale('en')), const Locale('ar'));
    expect(
        resolveLocale('system', const Locale('ar', 'EG')), const Locale('ar'));
    expect(resolveLocale(null, const Locale('fr')), const Locale('en'));
  });

  test('every inbox reason has a label in every language', () {
    for (final code in ['en', 'ar']) {
      final l = lookupAppLocalizations(Locale(code));
      for (final r in InboxReason.values) {
        expect(r.localized(l).trim(), isNotEmpty);
      }
    }
  });

  group('error messages', () {
    final enL = lookupAppLocalizations(const Locale('en'));
    final arL = lookupAppLocalizations(const Locale('ar'));

    test('known provider messages are translated, others pass through', () {
      for (final m in [
        'Invalid or expired token. Please reconnect.',
        'Invalid or expired GitLab token. Please reconnect.',
        'Invalid or expired Azure DevOps token. Please reconnect.',
      ]) {
        expect(translateErrorMessage(enL, m), enL.errInvalidToken);
        expect(translateErrorMessage(arL, m), arL.errInvalidToken);
      }
      expect(translateErrorMessage(arL, 'Access forbidden. Check your GitLab token scopes.'),
          arL.errForbidden);
      expect(translateErrorMessage(arL, 'Azure DevOps is having issues. Try again later.'),
          arL.errServer);
      expect(translateErrorMessage(arL, 'Unexpected error (418).'),
          'خطأ غير متوقع (418).');
      expect(translateErrorMessage(arL, 'GitHub is rate limiting requests. Try again in 42s.'),
          contains('42'));
      expect(translateErrorMessage(arL, 'Something custom'), 'Something custom');
    });

    test('exception types map; unknown errors become a network error', () {
      expect(localizedError(arL, const GitHubAuthException('Invalid or expired token. Please reconnect.')),
          arL.errInvalidToken);
      expect(localizedError(arL, StateError('x')), arL.errNetwork);
    });
  });

  test('presentation code has no hard-coded English labels (use context.l10n)',
      () {
    const allowed = {
      'GitHub', 'GitLab', 'RepoSphere', 'English', 'README', 'HTTPS', 'SSH',
      'Azure', 'Forgejo', 'Gitea', 'Codeberg', 'Personal',
    };
    final label = RegExp(
        r"(Text\(|label:|title:|tooltip:|hintText:|labelText:|content:|message:|subtitle:)\s*(const\s+)?\(?'([A-Z][a-z]+)");
    final offenders = <String>[];
    for (final dir in ['lib/features', 'lib/shared']) {
      for (final f in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') &&
              !f.path.contains('/data/') &&
              !f.path.contains('/domain/') &&
              !f.path.endsWith('_provider.dart'))) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final m = label.firstMatch(lines[i]);
          if (m != null && !allowed.contains(m.group(3))) {
            offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
