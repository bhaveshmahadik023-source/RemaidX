import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player.dart';

import '../firebase_options.dart';
import '../pages/F2_Reminder_alert.dart';
import 'alarm_service.dart' show AlarmService;

const String _stopActionId = 'stop';

// The alarm sound is played by the MAIN isolate (the running app).
// A notification button can be handled in a different (background) isolate,
// which cannot stop that sound. So the button sends a message to the main
// isolate through this named port, and the main isolate stops the alarm.
const String _stopPortName = 'remindx_stop_port';

// Marks a reminder as "done" in Firestore.
Future<void> _markDone(String reminderId) async {
  try {
    // In a background isolate Firebase may not be started yet.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .update({'status': 'done'});

    debugPrint('Reminder marked as done: $reminderId');
  } catch (e) {
    debugPrint('Could not mark reminder as done: $e');
  }
}

// Handles a tap on a LOCATION reminder notification or on its "Stop" button.
//  - Any tap stops the alarm sound.
//  - "Stop" also marks the reminder as "done".
// (Daily alarm notifications are handled by AlarmService, not here.)
Future<void> _handleResponse(NotificationResponse response) async {
  final isStop = response.actionId == _stopActionId;
  final reminderId = response.payload;

  debugPrint(
    'Notification response: action=${response.actionId}, id=$reminderId',
  );

  // Hand the work to the main isolate, where the alarm is playing.
  final port = IsolateNameServer.lookupPortByName(_stopPortName);
  if (port != null) {
    port.send({'stop': isStop, 'id': reminderId});
    return;
  }

  // The main isolate cannot be reached: do what we can from here.
  await NotificationService.stopRing();
  if (isStop && reminderId != null && reminderId.isNotEmpty) {
    await _markDone(reminderId);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _webPermissionGranted = false;

  // Android keeps the settings of a channel forever, so a changed
  // setting needs a new channel id.
  //   quiet ring channel : vibration + pop-up, NO sound (the alarm sound is
  //                        played by FlutterRingtonePlayer instead)
  //   loud ring channel  : used only if the alarm player fails
  //   message channel    : normal reminder notification
  static const String _quietRingChannelId = 'remindx_ring_quiet_v4';
  static const String _loudRingChannelId = 'remindx_ring_v3';
  static const String _messageChannelId = 'remindx_message_v2';

  // The alarm stops by itself after this time if nobody taps Stop.
  static const Duration _maxRingTime = Duration(seconds: 60);
  static Timer? _autoStopTimer;

  static bool _stopPortReady = false;

  // Listens (in the main isolate) for "stop" messages from the notification.
  static void _listenForStop() {
    if (_stopPortReady) return;
    _stopPortReady = true;

    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_stopPortName);
    IsolateNameServer.registerPortWithName(port.sendPort, _stopPortName);

    port.listen((message) async {
      if (message is Map && message['stop'] == true) {
        // "Stop" was tapped on the notification.
        await stopRing();
        _closeAlertPage();

        final id = message['id'];
        if (id is String && id.isNotEmpty) {
          await _markDone(id);
        }
      } else {
        // The notification was tapped (or opened by the full-screen intent):
        // make sure the alert screen is showing. The alarm keeps ringing
        // there until Stop is tapped.
        _openAlertPage();
      }
    });
  }

  // Called by AlarmService for every notification tap that is NOT a
  // daily alarm (daily alarms start with "{" because they are JSON).
  static Future<void> handleResponse(NotificationResponse response) {
    return _handleResponse(response);
  }

  static Future<void> initialize() async {
    if (kIsWeb) {
      // The current flutter_local_notifications web implementation
      // requires browser notification permission before show().
      _initialized = true;
      return;
    }

    _listenForStop();

    // AlarmService sets up the notification plugin (only once) and decides
    // what happens when a notification is tapped:
    //   daily alarm        -> opens the E3 ringing screen
    //   location reminder  -> NotificationService.handleResponse
    // Having ONE place that initializes the plugin means neither feature can
    // overwrite the other's tap handling.
    await AlarmService.init();

    final allowed = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    debugPrint('Notification permission allowed: $allowed');

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
      // true = the tap always reaches the running app, so the alarm stops.
      showsUserInterface: true,
    );

    // For a Ring reminder, start the alarm sound first.
    // It plays on the alarm volume and repeats until Stop is tapped.
    var alarmPlaying = false;
    if (ring) {
      try {
        await FlutterRingtonePlayer().playAlarm();
        alarmPlaying = true;

        _autoStopTimer?.cancel();
        _autoStopTimer = Timer(_maxRingTime, () {
          stopRing();
          _closeAlertPage();
        });
      } catch (e) {
        debugPrint('Alarm sound FAILED: $e');
      }
    }

    final AndroidNotificationDetails androidDetails;

    if (ring && alarmPlaying) {
      // Alarm sound is already playing, so this notification is silent.
      // It only vibrates, pops up, and shows the Stop button.
      androidDetails = AndroidNotificationDetails(
        _quietRingChannelId,
        'RemindX Alarm',
        channelDescription: 'Pop-up and vibration while the alarm rings',
        importance: Importance.max,
        priority: Priority.max,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 700, 400, 700, 400, 700]),
        category: AndroidNotificationCategory.alarm,
        // Opens the app over the lock screen, even when the screen is off.
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        actions: const <AndroidNotificationAction>[stopAction],
      );
    } else if (ring) {
      // The alarm player failed: let the notification make the sound.
      androidDetails = AndroidNotificationDetails(
        _loudRingChannelId,
        'RemindX Alarm (backup)',
        channelDescription: 'Loud alarm when you reach a reminder place',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 700, 400, 700, 400, 700]),
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]),
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        actions: const <AndroidNotificationAction>[stopAction],
      );
    } else {
      androidDetails = AndroidNotificationDetails(
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
    }

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        id: _idFor(reminderId),
        title: title,
        body: body,
        notificationDetails: details,
        payload: reminderId,
      );
      debugPrint(
        'Notification shown: "$title" (ring: $ring, alarm playing: $alarmPlaying)',
      );

      // Show the full alert screen (F2) with a big Stop button.
      // If the phone is locked, the full-screen intent above brings the app
      // up, and this screen is already waiting there.
      if (ring && alarmPlaying) {
        _alertTitle = title;
        _alertBody = body;
        _alertReminderId = reminderId;
        _openAlertPage();
      }
    } catch (e) {
      debugPrint('Notification FAILED: $e');
    }
  }

  static bool _alertOpen = false;
  static String _alertTitle = '';
  static String _alertBody = '';
  static String? _alertReminderId;

  // Opens the F2 alert screen on top of whatever is showing.
  static void _openAlertPage() {
    final navigator = AlarmService.navigatorKey.currentState;
    if (navigator == null || _alertOpen) return;

    _alertOpen = true;

    navigator
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ReminderAlertPage(
              title: _alertTitle,
              body: _alertBody,
              reminderId: _alertReminderId,
            ),
          ),
        )
        .whenComplete(() => _alertOpen = false);
  }

  // Closes the F2 screen (used when the alarm is stopped from outside it).
  static void _closeAlertPage() {
    if (!_alertOpen) return;

    _alertOpen = false;
    AlarmService.navigatorKey.currentState?.pop();
  }

  // Called by the F2 screen when the user taps Stop:
  // stops the sound, removes the notification, marks the reminder "done".
  static Future<void> stopAlert(String? reminderId) async {
    await stopRing();

    if (reminderId != null && reminderId.isNotEmpty) {
      await _notifications.cancel(id: _idFor(reminderId));
      await _markDone(reminderId);
    }
  }

  // Stops the alarm sound.
  static Future<void> stopRing() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('Could not stop alarm sound: $e');
    }
  }

  // Stops (removes) the notification and the alarm of one reminder.
  static Future<void> cancel(String reminderId) async {
    if (kIsWeb) return;
    await stopRing();
    await _notifications.cancel(id: _idFor(reminderId));
  }

  // Every reminder gets its own notification id,
  // so two reminders do not replace each other.
  static int _idFor(String? reminderId) {
    if (reminderId == null || reminderId.isEmpty) return 0;
    return reminderId.hashCode & 0x7fffffff;
  }
}