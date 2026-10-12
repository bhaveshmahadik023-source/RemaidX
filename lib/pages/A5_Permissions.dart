import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remindx/pages/app_widget.dart';
import '../constants.dart';
 

class PermissionsPage extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionsPage({super.key, required this.onDone});
  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _loc = false, _notif = false, _alarm = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb) return;
    final l = await Permission.locationAlways.isGranted;
    final n = await Permission.notification.isGranted;
    final a = await Permission.scheduleExactAlarm.isGranted;
    if (!mounted) return;
    setState(() {
      _loc = l;
      _notif = n;
      _alarm = a;
    });
  }

  Future<void> _ask(Future<void> Function() request) async {
    if (!kIsWeb) await request();{
      await request();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text('Allow access',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kTextDark)),
                  const SizedBox(height: 6),
                  const Text('So reminders work in the background',
                      style: TextStyle(fontSize: 13, color: kTextGrey)),
                  const SizedBox(height: 24),
                  _PermCard(
                    icon: Icons.location_on_outlined,
                    title: 'Location - always',
                    sub: 'To know when you reach your place',
                    granted: _loc,
                    onAllow: () => _ask(() async {
                      await Permission.locationWhenInUse.request();
                      await Permission.locationAlways.request();
                    }),
                  ),
                  _PermCard(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    sub: 'To show reminder messages',
                    granted: _notif,
                    onAllow: () =>
                        _ask(() => Permission.notification.request()),
                  ),
                  _PermCard(
                    icon: Icons.alarm,
                    title: 'Alarms and reminders',
                    sub: 'To ring at the exact time',
                    granted: _alarm,
                    onAllow: () =>
                        _ask(() => Permission.scheduleExactAlarm.request()),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kAmberLight,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.battery_charging_full,
                            color: kAmberDark),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Battery tip',
                                  style: TextStyle(
                                      color: kAmberDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              SizedBox(height: 4),
                              Text(
                                  'Set the app to "Unrestricted" so reminders are not delayed on your phone.',
                                  style: TextStyle(
                                      color: kAmberDark, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(text: 'Continue', onTap: widget.onDone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool granted;
  final VoidCallback onAllow;
  const _PermCard(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.granted,
      required this.onAllow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: kTealLight,
              child: Icon(icon, color: kTeal)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextDark)),
                const SizedBox(height: 2),
                Text(sub,
                    style:
                        const TextStyle(fontSize: 12, color: kTextGrey)),
                const SizedBox(height: 10),
                granted
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: kTealLight,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: kTeal),
                            SizedBox(width: 4),
                            Text('Allowed',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B4F49))),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 22),
                          ),
                          onPressed: onAllow,
                          child: const Text('Allow',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}