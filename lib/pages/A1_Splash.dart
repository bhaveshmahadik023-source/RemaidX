import 'package:flutter/material.dart';
import '../constants.dart';
import 'auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthGate()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTeal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on,
                      color: kTeal, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text('Location Reminder',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Remembered where it matters',
                style: TextStyle(color: Color(0xFFBFE3DD), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}