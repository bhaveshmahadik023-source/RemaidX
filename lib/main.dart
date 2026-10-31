import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:remindx/pages/auth_gate.dart';

import 'firebase_options.dart';
import 'constants.dart';
import 'services/alarm_service.dart';
import 'services/notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sets up notifications (this also calls AlarmService.init()).
  await NotificationService.initialize();

  runApp(const RemindXApp());

  // If the app was opened by a daily alarm, show the ringing screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AlarmService.openLaunchAlarmIfAny();
  });
}

class RemindXApp extends StatelessWidget {
  const RemindXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemindX',
      debugShowCheckedModeBanner: false,

      // One navigator key, shared by the daily alarm ringing screen
      // and the "Stop" pop-up of location alarms.
      navigatorKey: AlarmService.navigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kTeal,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}