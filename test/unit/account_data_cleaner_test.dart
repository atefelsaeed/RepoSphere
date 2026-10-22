import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sphere/core/constants/pref_keys.dart';
import 'package:repo_sphere/core/utils/account_data_cleaner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('disconnecting removes cached account data but keeps theme and locale',
      () async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.inboxCache: '[{"title":"private PR"}]',
      PrefKeys.inboxDismissals: '{}',
      PrefKeys.workspaces: '[]',
      PrefKeys.recentSearches: ['secret-repo'],
      PrefKeys.inboxAlertSeen: '[]',
      PrefKeys.inboxAlertsEnabled: true,
      'themeMode': 'dark',
      'locale': 'ar',
    });
    final prefs = await SharedPreferences.getInstance();

    await clearAccountScopedPrefs(prefs);

    for (final key in accountScopedPrefKeys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.getString('themeMode'), 'dark');
    expect(prefs.getString('locale'), 'ar');
  });

  test('every account-scoped key is registered for cleanup', () {
    expect(accountScopedPrefKeys, containsAll([
      PrefKeys.inboxCache,
      PrefKeys.inboxDismissals,
      PrefKeys.workspaces,
      PrefKeys.recentSearches,
      PrefKeys.inboxAlertSeen,
      PrefKeys.inboxAlertsEnabled,
    ]));
  });
}
