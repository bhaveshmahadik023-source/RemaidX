import 'package:flutter/material.dart';

import '../services/notification.dart';

// F2: Location reminder alert screen.
// Opens when the user reaches a reminder place (RING reminders).
// The alarm keeps ringing until Stop is tapped.
//
// If the phone is locked or the screen is off, the notification's
// full-screen intent brings the app up and this screen is shown.
class ReminderAlertPage extends StatefulWidget {
  final String title;
  final String body;
  final String? reminderId;

  const ReminderAlertPage({
    super.key,
    required this.title,
    required this.body,
    this.reminderId,
  });

  @override
  State<ReminderAlertPage> createState() => _ReminderAlertPageState();
}

class _ReminderAlertPageState extends State<ReminderAlertPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  bool _busy = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    if (_busy) return;

    setState(() => _busy = true);

    await NotificationService.stopAlert(widget.reminderId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B4F49),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                const Text(
                  'You have arrived',
                  style: TextStyle(
                    color: Color(0xFFBFE3DD),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 32),

                // Pulsing alarm icon.
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = _pulse.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 190 + 24 * t,
                          height: 190 + 24 * t,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 140 + 12 * t,
                          height: 140 + 12 * t,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF0B4F49),
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFBFE3DD),
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B4F49),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _busy ? null : _stop,
                    child: Text(
                      _busy ? 'Stopping...' : 'Stop',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}