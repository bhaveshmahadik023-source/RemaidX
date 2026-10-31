import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/alarm_service.dart';

// E3: Alarm ringing screen.
// The alarm SOUND and VIBRATION are played by the native alarm service
// (see AlarmService), so they work even when the app was closed.
// This screen only shows the alarm and lets the user snooze or dismiss it.
class AlarmRingingPage extends StatefulWidget {
  final AlarmData data;

  const AlarmRingingPage({
    super.key,
    required this.data,
  });

  @override
  State<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends State<AlarmRingingPage> {
  bool _busy = false;

  @override
  void dispose() {
    AlarmService.ringPageClosed();
    super.dispose();
  }

  Future<void> _snooze() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await AlarmService.snooze(widget.data);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not snooze alarm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await AlarmService.dismiss(widget.data);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dismiss alarm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

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

                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  d.timeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  d.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Daily alarm',
                  style: TextStyle(
                    color: Color(0xFFBFE3DD),
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                if (d.snoozeMin > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _busy ? null : _snooze,
                      child: Text(
                        'Snooze ${d.snoozeMin} min',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _SlideToDismiss(
                  onDone: _dismiss,
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

class _SlideToDismiss extends StatefulWidget {
  final VoidCallback onDone;

  const _SlideToDismiss({
    required this.onDone,
  });

  @override
  State<_SlideToDismiss> createState() => _SlideToDismissState();
}

class _SlideToDismissState extends State<_SlideToDismiss> {
  double _x = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const thumb = 56.0;
        final maxX = box.maxWidth - thumb - 8;

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'Slide to dismiss',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),

              Positioned(
                left: 4 + _x,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_done) return;

                    setState(() {
                      _x = (_x + details.delta.dx)
                          .clamp(0.0, maxX)
                          .toDouble();
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_x >= maxX * 0.85 && !_done) {
                      _done = true;

                      setState(() {
                        _x = maxX;
                      });

                      widget.onDone();
                    } else if (!_done) {
                      setState(() {
                        _x = 0;
                      });
                    }
                  },
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: kTeal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}