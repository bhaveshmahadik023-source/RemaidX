
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification.dart';

class GeofenceService {
  static StreamSubscription<Position>? _positionSubscription;

  static final Set<String> _triggeredReminders = {};

  static Future<void> startMonitoring() async {
    // Prevent duplicate location listeners.
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final locationEnabled =
        await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) return;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      await _checkNearbyReminders(
        user.uid,
        position,
      );
    });
  }

  static Future<void> _checkNearbyReminders(
    String userId,
    Position position,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['status'] != 'active') continue;

      final lat = data['lat'];
      final lng = data['lng'];

      if (lat is! num || lng is! num) continue;

      final radiusValue = data['radiusM'];
      final radius = radiusValue is num
          ? radiusValue.toDouble()
          : 700.0;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat.toDouble(),
        lng.toDouble(),
      );

      if (distance <= radius &&
          !_triggeredReminders.contains(doc.id)) {
        _triggeredReminders.add(doc.id);

        await NotificationService.showNotification(
          title: (data['title'] ?? 'RemindX Reminder').toString(),
          body:
              'You reached ${(data['placeName'] ?? 'your selected place').toString()}',
        );
      }
    }
  }

  static Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
