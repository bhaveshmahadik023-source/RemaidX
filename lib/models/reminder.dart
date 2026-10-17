import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

// One reminder saved in Firestore at users/{uid}/reminders/{id}.
// The same class is used for all 3 types: place, shopping, daily.
class Reminder {
  final String id; // Firestore document id
  final String title; // task name, e.g. "Buy clothes"
  final String type; // "place", "shopping" or "daily"
  final String category; // only for shopping, e.g. "Clothes"
  final String placeName; // e.g. "Phoenix Mall, Pune"
  final String alertType; // "message" or "ring"
  final String status; // "active", "triggered", "done" or "paused"
  final String sound; // alarm sound key (daily alarms), e.g. "morning_bell"
  final double? lat, lng; // empty for daily alarms
  final int radiusM; // alert distance in meters
  final int snoozeMin; // snooze time in minutes (0 = snooze off)
  final int? hour, minute; // only for daily alarms
  final List<int> days; // only for daily alarms (1 = Monday ... 7 = Sunday)

  Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.placeName,
    required this.alertType,
    required this.status,
    required this.sound,
    required this.radiusM,
    required this.snoozeMin,
    required this.days,
    this.lat,
    this.lng,
    this.hour,
    this.minute,
  });

  // Converts a Firestore document into a Reminder.
  // Every field has a default value, so missing data will not crash the app.
  factory Reminder.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Reminder(
      id: d.id,
      title: m['title'] ?? '',
      type: m['type'] ?? 'place',
      category: m['category'] ?? '',
      placeName: m['placeName'] ?? '',
      alertType: m['alertType'] ?? 'message',
      status: m['status'] ?? 'active',
      sound: m['sound'] ?? 'morning_bell',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      radiusM: (m['radiusM'] as num?)?.toInt() ?? 700,
      snoozeMin: (m['snoozeMin'] as num?)?.toInt() ?? 10,
      hour: (m['hour'] as num?)?.toInt(),
      minute: (m['minute'] as num?)?.toInt(),
      days: List<int>.from(m['days'] ?? const []),
    );
  }

  // True if this reminder has a location (daily alarms do not).
  bool get hasLocation => lat != null && lng != null;
  LatLng get latLng => LatLng(lat!, lng!);

  // Text for the radius: 700 -> "700 m", 1500 -> "1.5 km"
  String get radiusLabel => radiusM >= 1000
      ? '${(radiusM / 1000).toStringAsFixed(radiusM % 1000 == 0 ? 0 : 1)} km'
      : '$radiusM m';

  // "7:30 AM" for daily alarms
  String get timeLabel {
    final h = hour ?? 0;
    final m = (minute ?? 0).toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m ${h < 12 ? 'AM' : 'PM'}';
  }

  // "Every day", "Weekdays", "Weekends" or "Mon, Wed"
  String get daysLabel {
    final d = [...days]..sort();
    if (d.isEmpty || d.length >= 7) return 'Every day';
    if (d.join() == '12345') return 'Weekdays';
    if (d.join() == '67') return 'Weekends';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d.map((x) => names[x - 1]).join(', ');
  }
}