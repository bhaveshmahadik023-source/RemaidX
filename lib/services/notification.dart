
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _webPermissionGranted = false;

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

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (kIsWeb) {
      // Prevent the browser plugin from throwing the permission error.
      // Web notification support needs a web-specific implementation.
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'remindx_reminders',
      'RemindX Reminders',
      channelDescription: 'Notifications for nearby place reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
