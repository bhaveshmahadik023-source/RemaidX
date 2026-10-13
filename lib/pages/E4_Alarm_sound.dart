import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/alarm_sounds.dart';

// Small screen with the list of alarm sounds.
// Tap a sound: the screen closes and returns the sound key (e.g. "morning_bell").
class AlarmSoundPage extends StatelessWidget {
  final String selected; // sound that is selected now
  const AlarmSoundPage({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('Alarm sound',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final s in kAlarmSounds) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_none,
                        color: kTextGrey),
                    title: Text(s.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    trailing: s.key == selected
                        ? const Icon(Icons.check_circle, color: kTeal)
                        : null,
                    onTap: () => Navigator.pop(context, s.key),
                  ),
                  const Divider(height: 1, color: Color(0xFFEDF0EF)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}