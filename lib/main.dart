import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:remindx/pages/auth_gate.dart';

import 'firebase_options.dart';
import 'constants.dart';
import 'services/notification.dart';
import 'services/alarm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  // Initialize alarm and local notification service
  await AlarmService.init();

  runApp(const RemindXApp());
}

class RemindXApp extends StatelessWidget {
  const RemindXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AlarmService.navigatorKey,
      title: 'RemindX',
      debugShowCheckedModeBanner: false,
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