import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kTextGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: kTeal, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AuthService().logout();
      // main.dart cha StreamBuilder aapoaap Login page dakhavel
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('RemindX',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: kTealLight, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline,
                    color: kTeal, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Welcome, $name 👋',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kTextDark)),
              if (user?.email != null) ...[
                const SizedBox(height: 6),
                Text(user!.email!,
                    style: const TextStyle(color: kTextGrey, fontSize: 15)),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: 220,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kTeal),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: kTeal),
                  label: const Text('Log out',
                      style: TextStyle(
                          color: kTeal,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}