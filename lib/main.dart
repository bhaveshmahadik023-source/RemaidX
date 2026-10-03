import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'pages/home_page.dart';
import 'pages/auth_switcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snap.hasData ? const HomePage() : const AuthSwitcher();
        },
      ),
    );
  }
}