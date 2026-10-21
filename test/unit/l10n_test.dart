import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/providers/locale_provider.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/l10n/app_localizations.dart';
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
}
