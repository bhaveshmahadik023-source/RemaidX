
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:remindx/pages/B2_Home_empty.dart';
import 'package:remindx/services/geofence_service.dart';
import 'package:remindx/services/alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_switcher.dart';
import 'A5_Permissions.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snap.hasData) {
          return const _HomeGate();
        }

        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnap) {
            if (!prefsSnap.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final loggedOut =
                prefsSnap.data!.getBool('logged_out') ?? false;

            return AuthSwitcher(
              key: ValueKey(loggedOut),
              initialPage: loggedOut ? 'login' : 'welcome',
            );
          },
        );
      },
    );
  }
}

class _HomeGate extends StatefulWidget {
  const _HomeGate();

  @override
  State<_HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<_HomeGate> {
  bool? _done;

  @override
  void initState() {
    super.initState();

    _clearLogoutFlag();
    _loadPermissionsStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService.openLaunchAlarmIfAny();
    });
  }

  Future<void> _clearLogoutFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_out', false);
  }

  Future<void> _loadPermissionsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('permissions_done') ?? false;

    if (done) {
      await GeofenceService.startMonitoring();
    }

    if (mounted) {
      setState(() {
        _done = done;
      });
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('permissions_done', true);

    debugPrint('GEOFENCE: Starting monitoring');

    await GeofenceService.startMonitoring();

    debugPrint('GEOFENCE: Monitoring started');

    if (mounted) {
      setState(() {
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

   return _done!
    ? const HomePage()
    : PermissionsPage(onDone: _finish);
  }
}
