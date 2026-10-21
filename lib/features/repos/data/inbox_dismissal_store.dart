import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/inbox_item_entity.dart';

/// An item the user marked done or snoozed. A "done" item comes back only if
/// it has new activity after it was dismissed.
class InboxDismissal {
  final DateTime? snoozedUntil;
  final DateTime? doneAt;
  const InboxDismissal({this.snoozedUntil, this.doneAt});

  Map<String, dynamic> toJson() => {
        if (snoozedUntil != null) 'u': snoozedUntil!.toIso8601String(),
        if (doneAt != null) 'd': doneAt!.toIso8601String(),
      };

  static InboxDismissal fromJson(Map<String, dynamic> j) => InboxDismissal(
        snoozedUntil: j['u'] == null ? null : DateTime.parse(j['u'] as String),
        doneAt: j['d'] == null ? null : DateTime.parse(j['d'] as String),
      );

  bool hides(InboxItem item, DateTime now) {
    if (snoozedUntil != null && now.isBefore(snoozedUntil!)) return true;
    if (doneAt != null && !item.updatedAt.isAfter(doneAt!)) return true;
    return false;
  }
}

/// Persistence for [InboxDismissal]s, shared by the UI and background check.
class InboxDismissalStore {
  static const _key = 'inbox_dismissals_v1';

  static Map<String, InboxDismissal> read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const {};
    try {
      final now = DateTime.now();
      final map = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) =>
          MapEntry(k, InboxDismissal.fromJson(v as Map<String, dynamic>)));
      // Drop expired snoozes with no "done" marker.
      map.removeWhere((_, d) =>
          d.doneAt == null &&
          d.snoozedUntil != null &&
          d.snoozedUntil!.isBefore(now));
      return map;
    } on Object {
      return const {};
    }
  }

  static Future<void> write(
          SharedPreferences prefs, Map<String, InboxDismissal> map) =>
      prefs.setString(
          _key, jsonEncode(map.map((k, v) => MapEntry(k, v.toJson()))));

  static bool isHidden(Map<String, InboxDismissal> map, InboxItem item,
          DateTime now) =>
      map[item.key]?.hides(item, now) ?? false;
}
