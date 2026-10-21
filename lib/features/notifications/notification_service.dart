import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over local notifications. Mobile only; every call is a no-op
/// elsewhere.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!supported || _ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested when the user turns alerts on, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks the OS for permission; true when granted.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  static Future<void> showInboxAlert(String title, String body,
      {required String channelName, required String channelDescription}) async {
    if (!supported) return;
    await init();
    await _plugin.show(
      id: 1, // one slot: a newer alert replaces the previous summary
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'inbox_alerts',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
