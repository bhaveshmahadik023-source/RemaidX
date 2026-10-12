import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/common.dart';// PrimaryButton

class WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;
  const WelcomePage(
      {super.key, required this.onGetStarted, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _mapPreview(),
                  const SizedBox(height: 28),
                  const Text('Remind me when I arrive',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kTextDark)),
                  const SizedBox(height: 8),
                  const Text('Pick a place, find shops or set a daily alarm',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextGrey)),
                  const SizedBox(height: 24),
                  const _OptionCard(
                      icon: Icons.location_on_outlined,
                      bg: kTealLight,
                      color: kTeal,
                      title: 'I know the place',
                      sub: 'Add a place and your task'),
                  const _OptionCard(
                      icon: Icons.storefront_outlined,
                      bg: kPurpleLight,
                      color: Color(0xFF534AB7),
                      title: 'Find shops for me',
                      sub: 'Tell us what to buy, we suggest shops'),
                  const _OptionCard(
                      icon: Icons.alarm,
                      bg: kAmberLight,
                      color: kAmberDark,
                      title: 'Daily alarm',
                      sub: 'Repeat a task at a fixed time'),
                  const SizedBox(height: 18),
                  PrimaryButton(text: 'Get started', onTap: onGetStarted),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onLogin,
                    child: const Text('I already have an account',
                        style: TextStyle(
                            color: kTeal, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: const Color(0xFFE9EDEB)),
            Positioned(
                top: 16,
                right: 42,
                child: _block(98, 40)),
            Positioned(left: 20, bottom: 32, child: _block(72, 44)),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: kTeal, width: 1.5),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kTeal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Center(
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          color: const Color(0xFFCFE5C3),
          borderRadius: BorderRadius.circular(8)));
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color bg, color;
  final String title, sub;
  const _OptionCard(
      {required this.icon,
      required this.bg,
      required this.color,
      required this.title,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 22, backgroundColor: bg, child: Icon(icon, color: color)),
          const SizedBox(width: 16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}