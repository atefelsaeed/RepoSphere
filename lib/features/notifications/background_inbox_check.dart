import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/providers/locale_provider.dart';
import '../../l10n/l10n.dart';
import '../auth/data/secure_token_storage.dart';
import '../repos/data/git_provider_factory.dart';
import '../repos/data/inbox_dismissal_store.dart';
import '../repos/data/inbox_loader.dart';
import '../repos/domain/repositories/git_provider.dart';
import 'inbox_alerts.dart';
import 'notification_service.dart';

const kInboxCheckTask = 'inbox-check';
const _enabledKey = 'inbox_alerts_enabled';
const _seenKey = 'inbox_alert_seen_v1';

/// How often Android is asked to run the check (its minimum is 15 min). iOS
/// decides the real timing itself and may run it far less often.
const _checkEvery = Duration(minutes: 30);

@pragma('vm:entry-point')
void inboxCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await runInboxCheck();
      return true;
    } on Object catch (e) {
      debugPrint('inbox background check failed: $e');
      return false; // let the OS retry with backoff
    }
  });
}

Future<bool> inboxAlertsEnabled() async =>
    (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

/// Fetches every account, notifies about newly urgent items, and refreshes
/// the Inbox cache. Safe to call from a background isolate.
///
/// Returns how many items were announced. [force] ignores the enabled switch
/// (used by "Check now").
Future<int> runInboxCheck({bool force = false}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // the UI isolate may have changed settings
  if (!force && !(prefs.getBool(_enabledKey) ?? false)) return 0;

  final connections = await SecureTokenStorage.readConnections();
  if (connections.isEmpty) return 0;

  final client = http.Client();
  try {
    final providers = connections
        .map((c) => buildGitProvider(c, client))
        .whereType<GitProvider>();
    final load = await loadInbox(providers);
    // Never overwrite state from an all-failed (offline) run.
    if (load.allFailed) return 0;

    await InboxCache.write(prefs, load.items);

    final now = DateTime.now();
    final dismissals = InboxDismissalStore.read(prefs);
    final visible = load.items
        .where((i) => !InboxDismissalStore.isHidden(dismissals, i, now))
        .toList();

    final seenList = prefs.getStringList(_seenKey);
    final plan = planAlerts(visible, seenList?.toSet());
    await prefs.setStringList(_seenKey, plan.nextSeen.toList());

    if (plan.fresh.isEmpty) return 0;
    // No BuildContext here (background isolate): use the saved language choice,
    // else the device language, else English.
    final l = lookupAppLocalizations(resolveLocale(
        prefs.getString(localePrefKey), PlatformDispatcher.instance.locale));
    final text = alertText(plan.fresh, l);
    await NotificationService.showInboxAlert(text.title, text.body,
        channelName: l.alertChannelName,
        channelDescription: l.alertChannelDescription);
    return plan.fresh.length;
  } finally {
    client.close();
  }
}

/// Call once at startup (mobile only): wires the dispatcher and makes sure
/// the periodic check matches the saved setting.
Future<void> initBackgroundWork() async {
  if (!NotificationService.supported) return;
  await NotificationService.init();
  await Workmanager().initialize(inboxCallbackDispatcher);
  if (await inboxAlertsEnabled()) await _schedule();
}

Future<void> _schedule() => Workmanager().registerPeriodicTask(
      kInboxCheckTask,
      kInboxCheckTask,
      frequency: _checkEvery,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );

/// Turns inbox alerts on/off. Enabling asks for notification permission and
/// returns false (leaving alerts off) if it is denied.
Future<bool> setInboxAlerts(bool on) async {
  final prefs = await SharedPreferences.getInstance();
  if (on) {
    if (!await NotificationService.requestPermission()) return false;
    // Re-seed on enable so the existing backlog doesn't fire at once.
    await prefs.remove(_seenKey);
    await prefs.setBool(_enabledKey, true);
    await _schedule();
  } else {
    await prefs.setBool(_enabledKey, false);
    await Workmanager().cancelByUniqueName(kInboxCheckTask);
  }
  return true;
}
