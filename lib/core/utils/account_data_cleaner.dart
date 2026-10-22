import 'package:shared_preferences/shared_preferences.dart';
import '../constants/pref_keys.dart';

/// Deletes every locally cached value that came from a connected account.
/// Theme and language are not account data and are kept.
Future<void> clearAccountScopedPrefs([SharedPreferences? prefs]) async {
  final p = prefs ?? await SharedPreferences.getInstance();
  for (final key in accountScopedPrefKeys) {
    await p.remove(key);
  }
}
