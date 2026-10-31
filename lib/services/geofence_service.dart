import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification.dart';

// One active reminder that we are watching.
class _Target {
  final String id;
  final String title;
  final String placeName;
  final double lat;
  final double lng;
  final double radius; // meters
  final bool ring; // true = loud alarm, false = normal notification
  final String alertType; // exactly what is saved in Firestore (for logs)

  const _Target({
    required this.id,
    required this.title,
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.ring,
    required this.alertType,
  });
}

class GeofenceService {
  static StreamSubscription<Position>? _positionSubscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _remindersSubscription;

  // Active reminders kept in memory.
  // Checking distance against this list is instant (no internet needed),
  // so the alert comes much faster than asking Firestore on every GPS update.
  static List<_Target> _targets = [];

  // Reminders that are being fired right now (prevents a double alert).
  static final Set<String> _firing = {};

  static Position? _lastPosition;
  static bool _askedBackgroundPermission = false;

  static Future<void> startMonitoring() async {
    // Prevent duplicate listeners.
    await stopMonitoring();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Geofence: not started (user is not logged in)');
      return;
    }

    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) {
      debugPrint('Geofence: not started (GPS is off)');
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Geofence: not started (location permission denied)');
      return;
    }

    debugPrint('Geofence: started');

    // To keep working when the app is not on screen, Android needs
    // "Allow all the time". Ask once per app start.
    unawaited(_ensureBackgroundPermission());

    // Watch the user's reminders. The list updates by itself when a
    // reminder is added, deleted, done or triggered.
    // GPS runs ONLY while at least one reminder is active.
    _remindersSubscription = FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        final list = <_Target>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Only "active" reminders can ring.
          if (data['status'] != 'active') {
            _firing.remove(doc.id);
            continue;
          }

          final lat = data['lat'];
          final lng = data['lng'];
          if (lat is! num || lng is! num) continue;

          final radiusValue = data['radiusM'];
          final alertType = (data['alertType'] ?? 'Message').toString();
          final alertLower = alertType.toLowerCase();

          list.add(_Target(
            id: doc.id,
            title: (data['title'] ?? 'RemindX Reminder').toString(),
            placeName:
                (data['placeName'] ?? 'your selected place').toString(),
            lat: lat.toDouble(),
            lng: lng.toDouble(),
            radius: radiusValue is num ? radiusValue.toDouble() : 700.0,
            // "Ring", "ring" or anything that mentions ring / alarm.
            ring: alertLower.contains('ring') || alertLower.contains('alarm'),
            alertType: alertType,
          ));
        }

        _targets = list;
        debugPrint('Geofence: watching ${list.length} active reminder(s)');

        _syncLocationStream();

        // A new reminder may already be inside its radius: check right away.
        final p = _lastPosition;
        if (p != null) _check(p);
      },
      onError: (e) => debugPrint('Reminder listener error: $e'),
    );
  }

  // Asks for "Allow all the time" location (needed for background alerts).
  static Future<void> _ensureBackgroundPermission() async {
    if (kIsWeb || _askedBackgroundPermission) return;
    _askedBackgroundPermission = true;

    try {
      final status = await Permission.locationAlways.status;
      if (status.isGranted) return;

      final result = await Permission.locationAlways.request();
      debugPrint('Background location permission: $result');
    } catch (e) {
      debugPrint('Background location permission error: $e');
    }
  }

  // Start the GPS stream when there is something to watch,
  // stop it when there is nothing (saves battery, and the
  // "RemindX is watching" notification disappears).
  static void _syncLocationStream() {
    if (_targets.isEmpty) {
      _stopLocationStream();
      return;
    }
    if (_positionSubscription != null) return;
    _startLocationStream();
  }

  static void _startLocationStream() {
    // On Android the GPS runs as a "foreground service". This keeps it alive
    // while the app is in the background (a small notification stays visible).
    final LocationSettings settings =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
                intervalDuration: const Duration(seconds: 3),
                foregroundNotificationConfig: ForegroundNotificationConfig(
                  notificationTitle: 'RemindX is watching your reminders',
                  notificationText:
                      'You will be alerted when you reach your places.',
                  enableWakeLock: true,
                  setOngoing: true,
                ),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
              );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        _lastPosition = position;
        _check(position);
      },
      onError: (e) => debugPrint('Location stream error: $e'),
    );

    debugPrint('Geofence: GPS stream started');

    // Check once immediately, so we do not wait for the first movement.
    Geolocator.getCurrentPosition().then((first) {
      _lastPosition = first;
      _check(first);
    }).catchError((_) {});
  }

  static void _stopLocationStream() {
    if (_positionSubscription == null) return;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('Geofence: GPS stream stopped (no active reminders)');
  }

  // Compares the position with every active reminder.
  static Future<void> _check(Position position) async {
    for (final t in List<_Target>.from(_targets)) {
      if (_firing.contains(t.id)) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        t.lat,
        t.lng,
      );

      if (distance <= t.radius) {
        await _fire(t);
      }
    }
  }

  static Future<void> _fire(_Target t) async {
    debugPrint(
      'Geofence: firing "${t.title}" '
      '(saved alertType: "${t.alertType}", ring: ${t.ring})',
    );

    // Stop any second alert for this reminder straight away.
    _firing.add(t.id);
    _targets = _targets.where((x) => x.id != t.id).toList();

    // 1. Show the alert FIRST. It must not wait for the internet:
    //    when the app is in the background the phone may block the network,
    //    and waiting for Firestore would delay (or lose) the alert.
    await NotificationService.showNotification(
      title: t.title,
      body: 'You reached ${t.placeName}',
      reminderId: t.id,
      ring: t.ring,
    );

    // 2. Then mark it "triggered", so it never rings again, even after the
    //    app is restarted. This is NOT awaited: Firestore keeps the change
    //    and saves it as soon as the internet is available.
    //    (If "Stop" is tapped later, the status becomes "done". Firestore
    //    applies the changes in the same order, so "done" always wins.)
    unawaited(
      FirebaseFirestore.instance
          .collection('reminders')
          .doc(t.id)
          .update({
        'status': 'triggered',
        'triggeredAt': FieldValue.serverTimestamp(),
      }).catchError((Object e) {
        debugPrint('Could not mark reminder as triggered: $e');
      }),
    );
  }

  static Future<void> stopMonitoring() async {
    _stopLocationStream();

    await _remindersSubscription?.cancel();
    _remindersSubscription = null;

    _targets = [];
    _firing.clear();
    _lastPosition = null;
  }
}