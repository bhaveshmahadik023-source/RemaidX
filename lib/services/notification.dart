import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _stopActionId = 'stop';

// Runs when the user taps "Stop" on a notification.
// It marks the reminder as "done" in Firestore.
// The notification itself is cancelled by the Stop action
// (cancelNotification: true), so the ringing and vibration stop immediately.
Future<void> _handleResponse(NotificationResponse response) async {
  if (response.actionId != _stopActionId) return;

  final reminderId = response.payload;
  if (reminderId == null || reminderId.isEmpty) return;

  try {
    // In a background isolate Firebase may not be started yet.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .update({'status': 'done'});
  } catch (e) {
    debugPrint('Could not mark reminder as done: $e');
  }
}

// Used when the app is in the background or closed.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _handleResponse(response);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _webPermissionGranted = false;

  // New channel ids: Android keeps the settings of an old channel forever,
  // so the old "remindx_reminders" channel (no vibration) is not reused.
  static const String _ringChannelId = 'remindx_ring_v2';
  static const String _messageChannelId = 'remindx_message_v2';

  static Future<void> initialize() async {
    if (kIsWeb) {
      // The current flutter_local_notifications web implementation
      // requires browser notification permission before show().
      _initialized = true;
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) {
      // Browser permission must be requested by the web implementation.
      // Avoid calling show() until permission is granted.
      return _webPermissionGranted;
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await androidPlugin?.requestNotificationsPermission();

    return granted ?? false;
  }

  // Shows a reminder notification.
  //   reminderId : Firestore document id. Needed so "Stop" can mark it done.
  //   ring       : true  = loud alarm that keeps ringing until Stop is tapped
  //                false = normal notification with vibration
  static Future<void> showNotification({
    required String title,
    required String body,
    String? reminderId,
    bool ring = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (kIsWeb) {
      // Prevent the browser plugin from throwing the permission error.
      // Web notification support needs a web-specific implementation.
      return;
    }

    // The "Stop" button on the notification.
    const AndroidNotificationAction stopAction = AndroidNotificationAction(
      _stopActionId,
      'Stop',
      cancelNotification: true,
      showsUserInterface: false,
    );

    final AndroidNotificationDetails androidDetails = ring
        ? AndroidNotificationDetails(
            _ringChannelId,
            'RemindX Alarm',
            channelDescription: 'Loud alarm when you reach a reminder place',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern:
                Int64List.fromList([0, 700, 400, 700, 400, 700]),
            // Play on the alarm volume, and repeat the sound until
            // the notification is stopped (FLAG_INSISTENT = 4).
            audioAttributesUsage: AudioAttributesUsage.alarm,
            additionalFlags: Int32List.fromList(<int>[4]),
            category: AndroidNotificationCategory.alarm,
            autoCancel: true,
            actions: const <AndroidNotificationAction>[stopAction],
          )
        : AndroidNotificationDetails(
            _messageChannelId,
            'RemindX Reminders',
            channelDescription: 'Notifications for nearby place reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
            autoCancel: true,
            actions: const <AndroidNotificationAction>[stopAction],
          );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: _idFor(reminderId),
      title: title,
      body: body,
      notificationDetails: details,
      payload: reminderId,
    );
  }

  // Stops (removes) the notification of one reminder.
  static Future<void> cancel(String reminderId) async {
    if (kIsWeb) return;
    await _notifications.cancel(id: _idFor(reminderId));
  }

  // Every reminder gets its own notification id,
  // so two reminders do not replace each other.
  static int _idFor(String? reminderId) {
    if (reminderId == null || reminderId.isEmpty) return 0;
    return reminderId.hashCode & 0x7fffffff;
  }
}