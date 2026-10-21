import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SharedPreferences key holding `system`, `en` or `ar`.
const localePrefKey = 'locale';

/// Languages the app is translated into.
const supportedLanguageCodes = ['en', 'ar'];

/// The user's language choice; null follows the device language.
final localeProvider = StateProvider<Locale?>((ref) => null);

/// Parses the stored preference. Unknown values fall back to the device language.
Locale? localeFromPref(String? value) =>
    supportedLanguageCodes.contains(value) ? Locale(value!) : null;

String localeToPref(Locale? locale) => locale?.languageCode ?? 'system';

/// The locale to use for text that is produced outside the widget tree (e.g.
/// background notifications): the saved choice, else the device language if
/// supported, else English.
Locale resolveLocale(String? pref, Locale deviceLocale) =>
    localeFromPref(pref) ??
    (supportedLanguageCodes.contains(deviceLocale.languageCode)
        ? Locale(deviceLocale.languageCode)
        : const Locale('en'));
