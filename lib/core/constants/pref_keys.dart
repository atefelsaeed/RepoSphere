/// SharedPreferences keys that hold data derived from a connected account
/// (inbox titles, dismissals, workspaces, search history, alert state).
///
/// Everything listed in [accountScopedPrefKeys] is deleted when the user
/// disconnects, so nothing from a removed account stays on the device.
/// Add a key here whenever a new account-derived value is persisted.
class PrefKeys {
  PrefKeys._();

  static const inboxCache = 'inbox_cache_v1';
  static const inboxDismissals = 'inbox_dismissals_v1';
  static const workspaces = 'workspaces_v1';
  static const recentSearches = 'recent_searches';
  static const inboxAlertSeen = 'inbox_alert_seen_v1';
  static const inboxAlertsEnabled = 'inbox_alerts_enabled';
}

const accountScopedPrefKeys = <String>[
  PrefKeys.inboxCache,
  PrefKeys.inboxDismissals,
  PrefKeys.workspaces,
  PrefKeys.recentSearches,
  PrefKeys.inboxAlertSeen,
  PrefKeys.inboxAlertsEnabled,
];
