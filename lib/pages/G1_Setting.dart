
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

  // Load saved settings from the phone.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      radius = prefs.getInt('default_radius') ?? 700;
      alertType = prefs.getString('default_alert') ?? 'Message';
      alarmSound =
          prefs.getString('alarm_sound') ?? 'Morning bell';
      loading = false;
    });
  }

  // Save default radius.
  Future<void> _saveRadius(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_radius', value);

    if (!mounted) return;
    setState(() => radius = value);
  }

  // Save default alert.
  Future<void> _saveAlert(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_alert', value);

    if (!mounted) return;
    setState(() => alertType = value);
  }

  // Save selected sound.
  Future<void> _saveSound(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_sound', value);

    if (!mounted) return;
    setState(() => alarmSound = value);
  }

  String _radiusLabel(int value) {
    return value == 1000 ? '1 km' : '$value m';
  }

  // Default radius options.
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...radiusOptions.map(
                  (value) => RadioListTile<int>(
                    value: value,
                    groupValue: radius,
                    activeColor: teal,
                    title: Text(_radiusLabel(value)),
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

  // Default alert options.
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...alertOptions.map(
                  (value) => RadioListTile<String>(
                    value: value,
                    groupValue: alertType,
                    activeColor: teal,
                    title: Text(value),
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

  // Alarm sound options.
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...soundOptions.map(
                  (value) => RadioListTile<String>(
                    value: value,
                    groupValue: alarmSound,
                    activeColor: teal,
                    title: Text(value),
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

  // Open the phone's application settings.
  Future<void> _openPhoneSettings() async {
    await AppSettings.openAppSettings();
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
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: teal,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate should automatically show the
      // unauthenticated welcome/login screen.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 0.5,
          color: Color(0xFF687875),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 45,
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF657572),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4E6260),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF60716F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionRow({
    required String title,
    required String status,
    required VoidCallback onTap,
    bool needsAction = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: needsAction ? teal : lightTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
      return const Center(
        child: CircularProgressIndicator(
          color: teal,
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
                20, 18, 20, 20,
              ),
              color: teal,
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  14, 14, 14, 20,
                ),
                children: [
                  // Account card.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: const BoxDecoration(
                            color: lightTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ??
                                    'No email available',
                                style: const TextStyle(
                                  color: Color(0xFF657572),
                                  fontSize: 10,
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

                  const SizedBox(height: 18),

                  // Logout button.
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      size: 17,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity, 44,
                      ),
                      side: const BorderSide(
                        color: borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
