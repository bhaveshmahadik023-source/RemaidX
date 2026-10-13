import 'package:flutter/material.dart';
import '../constants.dart';

// E2: Time picker as a bottom sheet (hour, minute, AM/PM wheels).
// Returns the chosen time, or null if the user taps Cancel.
Future<TimeOfDay?> showTimeSheet(BuildContext context, TimeOfDay initial) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _TimeSheet(initial: initial),
  );
}

class _TimeSheet extends StatefulWidget {
  final TimeOfDay initial;
  const _TimeSheet({required this.initial});

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late int _hIdx; // 0..11  means hour 1..12
  late int _m; // 0..59
  late int _ap; // 0 = AM, 1 = PM
  late final FixedExtentScrollController _hc, _mc, _ac;

  @override
  void initState() {
    super.initState();
    final h = widget.initial.hour;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    _hIdx = h12 - 1;
    _m = widget.initial.minute;
    _ap = h >= 12 ? 1 : 0;
    _hc = FixedExtentScrollController(initialItem: _hIdx);
    _mc = FixedExtentScrollController(initialItem: _m);
    _ac = FixedExtentScrollController(initialItem: _ap);
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    _ac.dispose();
    super.dispose();
  }

  // Wheel values -> TimeOfDay (12 AM = 0:00, 12 PM = 12:00)
  TimeOfDay get _result {
    var h = (_hIdx + 1) % 12;
    if (_ap == 1) h += 12;
    return TimeOfDay(hour: h, minute: _m);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small grey handle bar
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Set time',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextDark)),
            const SizedBox(height: 20),

            // The three wheels with the amber band behind the middle row
            SizedBox(
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                        color: kAmberLight,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Wheel(
                        controller: _hc,
                        selected: _hIdx,
                        count: 12,
                        loop: true,
                        label: (i) => '${i + 1}',
                        onChanged: (i) => setState(() => _hIdx = i),
                      ),
                      _Wheel(
                        controller: _mc,
                        selected: _m,
                        count: 60,
                        loop: true,
                        label: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _m = i),
                      ),
                      _Wheel(
                        controller: _ac,
                        selected: _ap,
                        count: 2,
                        loop: false,
                        label: (i) => i == 0 ? 'AM' : 'PM',
                        onChanged: (i) => setState(() => _ap = i),
                      ),
                    ],
                  ),
                  // The ":" between hour and minute
                  Transform.translate(
                    offset: const Offset(-40, -2),
                    child: const Text(':',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: kAmberDark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cancel and OK
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 51,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 51,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context, _result),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// One scrolling column. The selected row is big and dark, the others small and grey.
class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int selected; // index of the selected row
  final int count; // how many values (12, 60 or 2)
  final bool loop; // true = goes round and round (hours, minutes)
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.controller,
    required this.selected,
    required this.count,
    required this.loop,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    int wrap(int i) => ((i % count) + count) % count;

    return SizedBox(
      width: 80,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 56,
        diameterRatio: 100, // big number = flat list, like the design
        perspective: 0.0005,
        physics: const FixedExtentScrollPhysics(), // snaps to a row
        onSelectedItemChanged: (i) => onChanged(loop ? wrap(i) : i),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: loop ? null : count, // null = endless
          builder: (context, i) {
            final idx = loop ? wrap(i) : i;
            final sel = idx == selected;
            return Center(
              child: Text(label(idx),
                  style: TextStyle(
                    fontSize: sel ? 30 : 22,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? kAmberDark : const Color(0xFF9AA5A3),
                  )),
            );
          },
        ),
      ),
    );
  }
}