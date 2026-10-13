// File: lib/services/alarm_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../pages/E3_Alarm_ringing.dart';
import 'reminder_service.dart';

/// Data required to schedule and display a daily alarm.
class AlarmData {
  final String id;
  final String title;
  final String sound;
  final int hour;
  final int minute;
  final List<int> days;
  final int snoozeMin;
  final bool ring;

  const AlarmData({
    required this.id,
    required this.title,
    required this.sound,
    required this.hour,
    required this.minute,
    required this.days,
    required this.snoozeMin,
    required this.ring,
  });

  factory AlarmData.fromReminder(Reminder r) {
    return AlarmData(
      id: r.id,
      title: r.title,
      sound: r.sound,
      hour: r.hour ?? 0,
      minute: r.minute ?? 0,
      days: List<int>.from(r.days),
      snoozeMin: r.snoozeMin,
      ring: r.alertType == 'ring',
    );
  }

  String toPayload() {
    return jsonEncode({
      'kind': 'daily',
      'id': id,
      'title': title,
      'sound': sound,
      'hour': hour,
      'minute': minute,
      'days': days,
      'snoozeMin': snoozeMin,
      'ring': ring,
    });
  }

  factory AlarmData.fromPayload(String payload) {
    final decoded = jsonDecode(payload);

    if (decoded is! Map<String, dynamic> ||
        decoded['kind'] != 'daily') {
      throw const FormatException('Not a daily alarm payload');
    }

    return AlarmData(
      id: decoded['id'] as String,
      title: decoded['title'] as String,
      sound: decoded['sound'] as String? ?? 'default',
      hour: decoded['hour'] as int,
      minute: decoded['minute'] as int,
      days: List<int>.from(decoded['days'] as List),
      snoozeMin: decoded['snoozeMin'] as int,
      ring: decoded['ring'] as bool,
    );
  }

  String get timeLabel {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;

    return '$h12:${minute.toString().padLeft(2, '0')} '
        '${hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Daily alarm and notification service.
class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// IMPORTANT: Assign this key to MaterialApp.navigatorKey.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static bool _ringOpen = false;
  static AlarmData? _pendingAlarm;

  /// Initialize notifications and timezone.
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tzdata.initializeTimeZones();

    // India timezone. Change this if the app must support other timezones.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

   await _plugin.initialize(
  settings: settings,
  onDidReceiveNotificationResponse: _onNotificationResponse,
);
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;

      if (payload != null && payload.isNotEmpty) {
        _handlePayload(payload);
      }
    }
  }

  /// Request notification and exact-alarm permissions.
  static Future<void> ensurePermissions() async {
    if (kIsWeb) return;

    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Handle a notification tapped by the user.
  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) return;

    _handlePayload(payload);
  }

  static void _handlePayload(String payload) {
    try {
      final data = AlarmData.fromPayload(payload);
      _open(data);
    } catch (e) {
      debugPrint('Unable to open alarm notification: $e');
    }
  }

  /// Open the ringing page. If navigation is not ready, keep it pending.
  static void _open(AlarmData data) {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      _pendingAlarm = data;
      return;
    }

    if (_ringOpen) return;

    _ringOpen = true;
    _pendingAlarm = null;

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AlarmRingingPage(data: data),
      ),
    );
  }

  /// Call after the app's first screen is ready to handle a pending alarm.
  static void openLaunchAlarmIfAny() {
    final data = _pendingAlarm;

    if (data != null && navigatorKey.currentState != null) {
      _open(data);
    }
  }

  /// Called when the ringing screen closes.
  static void ringPageClosed() {
    _ringOpen = false;
  }

  /// Generate a stable group of notification IDs for each reminder.
  static int _baseId(String id) {
    var hash = 0;

    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) % 1000000;
    }

    return hash;
  }

  static int _dayNotificationId(String id, int weekday) {
    return _baseId(id) * 10 + weekday;
  }

  static int _snoozeNotificationId(String id) {
    return _baseId(id) * 10 + 8;
  }

  /// Cancel all weekly alarm notifications and its snooze notification.
  static Future<void> _cancelScheduled(String id) async {
    if (kIsWeb) return;

    await init();

    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(
  id: _dayNotificationId(id, day),
);
    }

   await _plugin.cancel(
  id: _snoozeNotificationId(id),
);
  }

  /// Find the next occurrence of a selected weekday and time.
  static tz.TZDateTime _nextOccurrence(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);

    var result = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (result.weekday != weekday || !result.isAfter(now)) {
      result = result.add(const Duration(days: 1));
    }

    return result;
  }

  static NotificationDetails _notificationDetails(AlarmData data) {
    final androidDetails = AndroidNotificationDetails(
      'remindx_daily_alarms',
      'Daily alarms',
      channelDescription: 'Scheduled reminders from RemindX',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Schedule a repeating alarm for the selected weekdays.
  static Future<void> schedule(AlarmData data) async {
    if (kIsWeb) {
      debugPrint('Local alarm scheduling is not supported on web.');
      return;
    }

    await ensurePermissions();
    await _cancelScheduled(data.id);

    final selectedDays = data.days.toSet().toList()..sort();

    for (final weekday in selectedDays) {
      if (weekday < 1 || weekday > 7) continue;

      final scheduledDate = _nextOccurrence(
        weekday,
        data.hour,
        data.minute,
      );

final minutes = data.snoozeMin > 0 ? data.snoozeMin : 10;

final nextTime = tz.TZDateTime.now(tz.local).add(
  Duration(minutes: minutes),
);

await _plugin.zonedSchedule(
  id: _snoozeNotificationId(data.id),
  title: data.title,
  body: 'Snoozed reminder',
  scheduledDate: scheduledDate,
  notificationDetails: _notificationDetails(data),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  payload: data.toPayload(),
);
    }
  }

/// Snooze the current alarm and show it again after snoozeMin minutes.
static Future<void> snooze(AlarmData data) async {
  if (kIsWeb) return;

  await ensurePermissions();

  final minutes = data.snoozeMin > 0 ? data.snoozeMin : 10;

  final nextTime = tz.TZDateTime.now(tz.local).add(
    Duration(minutes: minutes),
  );

  await _plugin.cancel(
    id: _snoozeNotificationId(data.id),
  );

  await _plugin.zonedSchedule(
    id: _snoozeNotificationId(data.id),
    title: data.title,
    body: 'Snoozed reminder',
    scheduledDate: nextTime,
    notificationDetails: _notificationDetails(data),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: data.toPayload(),
  );

  _ringOpen = false;
}

  /// Dismiss the alarm, cancel its schedules and mark the reminder done.
  static Future<void> dismiss(AlarmData data) async {
    await _cancelScheduled(data.id);

    _ringOpen = false;

    try {
      await ReminderService().setStatus(data.id, 'done');
    } catch (e) {
      debugPrint('Could not update reminder status: $e');
    }
  }
}