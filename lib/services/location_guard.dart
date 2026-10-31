import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Reminder alerts work with the phone's GPS.
// Call this before saving a reminder:
//
//   if (!await LocationGuard.ensureReady(context)) return;
//
// It returns true when GPS is ON and the app has location permission.
// Otherwise it shows a message (with a button that opens the right
// settings page) and returns false, so the reminder is NOT saved.
class LocationGuard {
  LocationGuard._();

  static Future<bool> ensureReady(BuildContext context) async {
    // 1. Is GPS (location service) turned on?
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      if (!context.mounted) return false;

      final open = await _ask(
        context,
        title: 'Turn on location',
        message: 'RemindX needs your location to alert you when you reach '
            'this place. Please turn on location, then tap Save again.',
        button: 'Turn on',
      );

      if (open == true) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    // 2. Does the app have permission?
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is needed to save this reminder.'),
        ),
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;

      final open = await _ask(
        context,
        title: 'Allow location',
        message: 'Location permission is blocked. Please allow location for '
            'RemindX in the app settings, then tap Save again.',
        button: 'Open settings',
      );

      if (open == true) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    return true;
  }

  static Future<bool?> _ask(
    BuildContext context, {
    required String title,
    required String message,
    required String button,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.location_off_outlined,
          size: 40,
          color: Color(0xFF117C75),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(button),
          ),
        ],
      ),
    );
  }
}