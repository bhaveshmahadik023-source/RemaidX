import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:remindx/A1__wlcome.dart';
import 'package:remindx/pages/B2_Home_empty.dart';

import 'firebase_options.dart';
import 'constants.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RemindXApp());
}

class RemindXApp extends StatelessWidget {
  const RemindXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemindX',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kTeal,
        ),
        useMaterial3: true,
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          // Firebase authentication check होत असताना
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // User already logged in
          if (snap.hasData) {
            return const HomePage();
          }

          // User is not logged in
          return const welcomepage();
        },
      ),
    );
  }
}