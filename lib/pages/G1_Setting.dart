
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remindx/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remindx/services/geofence_service.dart';
class G1Settings extends StatefulWidget {
  const G1Settings({super.key});

  @override
  State<G1Settings> createState() => _G1SettingsState();
}

class _G1SettingsState extends State<G1Settings> {
  static const Color teal = Color(0xFF117C75);
  static const Color lightTeal = Color(0xFFE5F4F1);
  static const Color borderColor = Color(0xFFDCE5E3);

  int radius = 700;
  String alertType = 'Message';
  String alarmSound = 'Morning bell';

  bool loading = true;

  final List<int> radiusOptions = [
    100,
    300,
    500,
    700,
    1000,
  ];

  final List<String> alertOptions = [
    'Message',
    'Ring',
  ];

  final List<String> soundOptions = [
    'Morning bell',
    'Classic alarm',
    'Gentle chime',
    'Digital beep',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from Firestore.
  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadSettings();

      if (!mounted) return;

      setState(() {
        radius = settings['defaultRadius'] ?? 700;
        alertType = settings['defaultAlert'] ?? 'Message';
        alarmSound = settings['alarmSound'] ?? 'Morning bell';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint('Error loading settings: $e');
    }
  }

  // Save default radius.
  Future<void> _saveRadius(int value) async {
    setState(() {
      radius = value;
    });

    try {
      await SettingsService.saveSettings({
        'defaultRadius': value,
      });
    } catch (e) {
      debugPrint('Error saving radius: $e');
    }
  }

  // Save default alert.
  Future<void> _saveAlert(String value) async {
    setState(() {
      alertType = value;
    });

    try {
      await SettingsService.saveSettings({
        'defaultAlert': value,
      });
    } catch (e) {
      debugPrint('Error saving alert type: $e');
    }
  }

  // Save alarm sound.
  Future<void> _saveSound(String value) async {
    setState(() {
      alarmSound = value;
    });

    try {
      await SettingsService.saveSettings({
        'alarmSound': value,
      });
    } catch (e) {
      debugPrint('Error saving alarm sound: $e');
    }
  }

  String _radiusLabel(int value) {
    return value == 1000 ? '1 km' : '$value m';
  }

  // Show radius options.
  void _showRadiusOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default radius',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...radiusOptions.map(
                  (value) => RadioListTile<int>(
                    value: value,
                    groupValue: radius,
                    activeColor: teal,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _radiusLabel(value),
                      style: const TextStyle(fontSize: 16),
                    ),
                    onChanged: (selected) async {
                      if (selected == null) return;

                      await _saveRadius(selected);

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show alert options.
  void _showAlertOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default alert',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...alertOptions.map(
                  (value) => RadioListTile<String>(
                    value: value,
                    groupValue: alertType,
                    activeColor: teal,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      value,
                      style: const TextStyle(fontSize: 16),
                    ),
                    secondary: Icon(
                      value == 'Message'
                          ? Icons.notifications_outlined
                          : Icons.ring_volume_outlined,
                    ),
                    onChanged: (selected) async {
                      if (selected == null) return;

                      await _saveAlert(selected);

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show alarm sound options.
  void _showSoundOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alarm sound',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...soundOptions.map(
                  (value) => RadioListTile<String>(
                    value: value,
                    groupValue: alarmSound,
                    activeColor: teal,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      value,
                      style: const TextStyle(fontSize: 16),
                    ),
                    secondary: const Icon(Icons.music_note),
                    onChanged: (selected) async {
                      if (selected == null) return;

                      await _saveSound(selected);

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Open phone application settings.
  Future<void> _openPhoneSettings() async {
    if (kIsWeb) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please open your device settings manually.',
          ),
        ),
      );
      return;
    }

    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open phone settings.'),
        ),
      );

      debugPrint('Error opening app settings: $e');
    }
  }

  // Firebase logout.

Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text(
        'Are you sure you want to log out?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, false);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
  await GeofenceService.stopMonitoring();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('logged_out', true);

  await FirebaseAuth.instance.signOut();

  if (!mounted) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
} catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout failed: $e'),
      ),
    );
  }
}



  // Section heading.
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 10,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          color: Color(0xFF687875),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Setting row.
  Widget _settingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 57,
        child: Row(
          children: [
            Icon(
              icon,
              size: 23,
              color: const Color(0xFF657572),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202A28),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E6260),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right,
              size: 23,
              color: Color(0xFF60716F),
            ),
          ],
        ),
      ),
    );
  }

  // Permission row.
  Widget _permissionRow({
    required String title,
    required String status,
    required VoidCallback onTap,
    bool needsAction = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 53),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEAF0EF),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202A28),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: needsAction ? teal : lightTeal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: needsAction ? Colors.white : teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: teal,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Teal header.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 22,
              ),
              color: teal,
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 24,
                ),
                children: [
                  // Account card.
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: lightTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: teal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                user?.email ??
                                    'No email available',
                                style: const TextStyle(
                                  color: Color(0xFF657572),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle('Defaults'),

                  _settingRow(
                    icon: Icons.my_location_outlined,
                    title: 'Default radius',
                    value: _radiusLabel(radius),
                    onTap: _showRadiusOptions,
                  ),

                  const Divider(
                    height: 1,
                    color: Color(0xFFEAF0EF),
                  ),

                  _settingRow(
                    icon: Icons.volume_up_outlined,
                    title: 'Default alert',
                    value: alertType,
                    onTap: _showAlertOptions,
                  ),

                  const Divider(
                    height: 1,
                    color: Color(0xFFEAF0EF),
                  ),

                  _settingRow(
                    icon: Icons.alarm_outlined,
                    title: 'Alarm sound',
                    value: alarmSound,
                    onTap: _showSoundOptions,
                  ),

                  _sectionTitle('Permissions'),

                  _permissionRow(
                    title: 'Location - always',
                    status: 'Open',
                    onTap: _openPhoneSettings,
                  ),

                  _permissionRow(
                    title: 'Notifications',
                    status: 'Open',
                    onTap: _openPhoneSettings,
                  ),

                  _permissionRow(
                    title: 'Alarms and reminders',
                    status: 'Allow',
                    needsAction: true,
                    onTap: _openPhoneSettings,
                  ),

                  const SizedBox(height: 24),

                  // Logout button.
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      size: 19,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                      side: const BorderSide(
                        color: borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
