import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart'
    show Alarm, AlarmSettings, NotificationSettings, VolumeSettings;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm_sounds.dart';
import '../models/reminder.dart';
import '../pages/E3_Alarm_ringing.dart';
import 'notification.dart';

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

    if (decoded is! Map<String, dynamic> || decoded['kind'] != 'daily') {
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

/// Daily alarm service.
///
/// The alarm itself (sound, vibration, full-screen pop-up, Stop button) is
/// run by the native "alarm" package. It uses an Android foreground service
/// and exact AlarmManager scheduling, so it rings even when the app is in the
/// background or closed, without the user tapping anything.
///
/// This class also sets up the notification plugin used by location reminders.
class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Assign this key to MaterialApp.navigatorKey.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static bool _ringOpen = false;
  static AlarmData? _pendingAlarm;
  static StreamSubscription? _ringingSub;

  // Ids of the alarms that are ringing right now.
  static final Set<int> _ringingIds = {};

  // How many weeks ahead alarms are scheduled. The alarm package has no
  // "repeat every week", so every coming occurrence is scheduled in advance.
  // Opening the app (or editing the alarm) schedules the next weeks again.
  static const int _weeksAhead = 8;

  /// Initialize notifications and the alarm service.
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

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

    // The notification plugin is shared with location reminders.
    // This is the ONE place that initializes it.
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload != null && payload.startsWith('{')) {
          _onNotificationResponse(response);
        } else {
          // Location reminder (Ring / Message): Stop button and taps.
          NotificationService.handleResponse(response);
        }
      },
    );

    // Native alarm service.
    await Alarm.init();

    await _ringingSub?.cancel();
    _ringingSub = Alarm.ringing.listen((alarmSet) {
      _ringingIds
        ..clear()
        ..addAll(alarmSet.alarms.map((a) => a.id));

      // Nothing is ringing any more (for example "Stop" was tapped on the
      // alarm notification): close the ringing screen.
      if (alarmSet.alarms.isEmpty) {
        if (_ringOpen) {
          _ringOpen = false;
          navigatorKey.currentState?.pop();
        }
        return;
      }

      // An alarm started ringing: show the ringing screen.
      for (final alarm in alarmSet.alarms) {
        final payload = alarm.payload;
        if (payload == null || payload.isEmpty) continue;

        _handlePayload(payload);
        break;
      }
    });

    _initialized = true;
  }

  /// Request notification and exact-alarm permissions.
  static Future<void> ensurePermissions() async {
    if (kIsWeb) return;

    await init();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

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
      debugPrint('Unable to open alarm screen: $e');
    }
  }

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

  /// Open a pending alarm after navigation is ready.
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

  // ---------------- Ids ----------------

  /// Stable base number for each reminder.
  static int _baseId(String id) {
    var hash = 0;

    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) % 1000000;
    }

    return hash;
  }

  // weekday: 1..7, week: 0.._weeksAhead-1  ->  unique alarm id
  static int _alarmId(String id, int weekday, int week) {
    return _baseId(id) * 100 + weekday * 10 + week;
  }

  static int _snoozeAlarmId(String id) {
    return _baseId(id) * 100 + 90;
  }

  // ---------------- Scheduling ----------------

  /// Cancel all scheduled alarms (and the snooze) of one reminder.
  static Future<void> _cancelScheduled(String id) async {
    if (kIsWeb) return;

    await init();

    for (var weekday = 1; weekday <= 7; weekday++) {
      for (var week = 0; week < _weeksAhead; week++) {
        await Alarm.stop(_alarmId(id, weekday, week));
      }
    }

    await Alarm.stop(_snoozeAlarmId(id));
  }

  /// Cancel an alarm from the Home page.
  static Future<void> cancel(String id) async {
    await _cancelScheduled(id);
    debugPrint('ALARM: cancelled alarm id=$id');
  }

  /// Next date of a weekday at a given time (local phone time).
  static DateTime _nextOccurrence(int weekday, int hour, int minute) {
    final now = DateTime.now();

    var result = DateTime(now.year, now.month, now.day, hour, minute);

    while (result.weekday != weekday || !result.isAfter(now)) {
      result = DateTime(
        result.year,
        result.month,
        result.day + 1,
        hour,
        minute,
      );
    }

    return result;
  }

  static AlarmSettings _settings({
    required int id,
    required DateTime dateTime,
    required AlarmData data,
    String body = 'Your daily alarm is ringing.',
  }) {
    // The sound chosen for this alarm. The alarm package needs the full
    // asset path (it starts with "assets/").
    final path = alarmSoundByKey(data.sound).assetPath;

    final String? assetPath = (path == null || path.isEmpty)
        ? null // null = the phone's default alarm sound
        : (path.startsWith('assets/') ? path : 'assets/$path');

    return AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: assetPath,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: false,
      androidFullScreenIntent: true,
      // Keep ringing even if the app is swiped away from recent apps.
      androidStopAlarmOnTermination: false,
      payload: data.toPayload(),
      volumeSettings: VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: data.title,
        body: body,
        stopButton: 'Stop',
      ),
    );
  }

  /// Schedule the alarm for the selected weekdays (the next few weeks).
  static Future<void> schedule(AlarmData data) async {
    debugPrint('ALARM: schedule() started');

    if (kIsWeb) {
      debugPrint('ALARM: running on web, alarms are not supported');
      return;
    }

    try {
      await ensurePermissions();

      await _cancelScheduled(data.id);

      final selectedDays = data.days.toSet().toList()..sort();

      debugPrint(
        'ALARM: id=${data.id}, days=$selectedDays, '
        'time=${data.hour}:${data.minute}',
      );

      if (selectedDays.isEmpty) {
        debugPrint('ALARM: no weekdays selected');
        return;
      }

      for (final weekday in selectedDays) {
        if (weekday < DateTime.monday || weekday > DateTime.sunday) {
          debugPrint('ALARM: invalid weekday=$weekday');
          continue;
        }

        final first = _nextOccurrence(weekday, data.hour, data.minute);

        for (var week = 0; week < _weeksAhead; week++) {
          final when = DateTime(
            first.year,
            first.month,
            first.day + 7 * week,
            data.hour,
            data.minute,
          );

          await Alarm.set(
            alarmSettings: _settings(
              id: _alarmId(data.id, weekday, week),
              dateTime: when,
              data: data,
            ),
          );
        }

        debugPrint('ALARM: scheduled weekday=$weekday from $first');
      }
    } catch (e, st) {
      debugPrint('ALARM ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // Stops every alarm that is ringing right now.
  static Future<void> _stopRinging() async {
    for (final id in List<int>.from(_ringingIds)) {
      await Alarm.stop(id);
    }
    _ringingIds.clear();
  }

  /// Snooze the current alarm.
  static Future<void> snooze(AlarmData data) async {
    if (kIsWeb) return;

    // The ringing screen closes itself, so do not close it twice.
    _ringOpen = false;

    await _stopRinging();

    final minutes = data.snoozeMin > 0 ? data.snoozeMin : 10;
    final next = DateTime.now().add(Duration(minutes: minutes));

    await Alarm.set(
      alarmSettings: _settings(
        id: _snoozeAlarmId(data.id),
        dateTime: next,
        data: data,
        body: 'Snoozed reminder',
      ),
    );

    debugPrint('ALARM: snoozed until $next');
  }

  /// Dismiss the current alarm (and any pending snooze).
  static Future<void> dismiss(AlarmData data) async {
    if (kIsWeb) return;

    _ringOpen = false;

    await _stopRinging();
    await Alarm.stop(_snoozeAlarmId(data.id));

    debugPrint('ALARM: dismissed ${data.id}');
  }
}