import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/alarm_sounds.dart';
import '../models/reminder.dart';
import '../services/alarm_service.dart';
import '../services/reminder_service.dart';
import '../widgets/common.dart'; // PrimaryButton
import 'E2_Time_picker.dart';
import 'E4_Alarm_sound.dart';

// E1: Daily alarm form.
// The user sets time, task, days, ring style, sound and snooze.
// Save = store in Firestore + set the alarm on the phone.
// Pass [editing] to edit an existing alarm (used later by B5).
class DailyAlarmPage extends StatefulWidget {
  final Reminder? editing;
  const DailyAlarmPage({super.key, this.editing});

  @override
  State<DailyAlarmPage> createState() => _DailyAlarmPageState();
}

class _DailyAlarmPageState extends State<DailyAlarmPage> {
  final _title = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7}; // 1 = Monday ... 7 = Sunday
  bool _ring = true; // "Ring like an alarm"
  bool _snooze = true; // "Snooze 10 minutes"
  String _sound = kDefaultAlarmSound;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Editing: fill the form with the saved values.
    final r = widget.editing;
    if (r != null) {
      _title.text = r.title;
      _time = TimeOfDay(hour: r.hour ?? 18, minute: r.minute ?? 0);
      _days
        ..clear()
        ..addAll(r.days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : r.days);
      _ring = r.alertType == 'ring';
      _snooze = r.snoozeMin > 0;
      _sound = r.sound;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // "6:00" and "PM" are shown in two different sizes in the big card.
  String get _clock {
    final h12 = _time.hour % 12 == 0 ? 12 : _time.hour % 12;
    return '$h12:${_time.minute.toString().padLeft(2, '0')}';
  }

  String get _period => _time.hour < 12 ? 'AM' : 'PM';

  // E2: open the time sheet.
  Future<void> _pickTime() async {
    final t = await showTimeSheet(context, _time);
    if (t != null) setState(() => _time = t);
  }

  // Open the sound list and take the chosen sound.
  Future<void> _pickSound() async {
    final s = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => AlarmSoundPage(selected: _sound)),
    );
    if (s != null) setState(() => _sound = s);
  }

  bool _is(Set<int> preset) =>
      _days.length == preset.length && _days.containsAll(preset);

  void _setPreset(Set<int> preset) => setState(() {
        _days
          ..clear()
          ..addAll(preset);
      });

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return _msg('Enter a task name');
    if (_days.isEmpty) return _msg('Select at least one day');

    setState(() => _saving = true);
    try {
      // Ask the phone for notification / exact alarm / full screen permission.
      await AlarmService.ensurePermissions();

      final days = _days.toList()..sort();
      final snoozeMin = _snooze ? 10 : 0;

      // 1. Save in Firestore (no lat/lng for daily alarms).
      final data = {
        'title': title,
        'type': 'daily',
        'category': '',
        'placeName': '',
        'alertType': _ring ? 'ring' : 'message',
        'sound': _sound,
        'hour': _time.hour,
        'minute': _time.minute,
        'days': days,
        'snoozeMin': snoozeMin,
      };
      final service = ReminderService();
      final String id;
      if (widget.editing == null) {
        id = await service.add(data);
      } else {
        id = widget.editing!.id;
        await service.update(id, data);
      }

      // 2. Set the alarm on the phone.
      await AlarmService.schedule(AlarmData(
        id: id,
        title: title,
        sound: _sound,
        hour: _time.hour,
        minute: _time.minute,
        days: days,
        snoozeMin: snoozeMin,
        ring: _ring,
      ));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg(e.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const line = Divider(height: 1, color: Color(0xFFEDF0EF));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: Text(widget.editing == null ? 'Daily alarm' : 'Edit alarm',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the layout phone-sized when opened in Chrome.
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      // Big amber time card. Tap to open the time sheet (E2).
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _pickTime,
                        child: Container(
                          height: 119,
                          decoration: BoxDecoration(
                            color: kAmberLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kAmber),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(_clock,
                                      style: const TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w700,
                                          color: kAmberDark)),
                                  const SizedBox(width: 8),
                                  Text(_period,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: kAmberDark)),
                                ],
                              ),
                              const Text('Tap to change time',
                                  style: TextStyle(
                                      fontSize: 12, color: kAmberDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Task name
                      const _Label('What is the task?', 12),
                      TextField(
                        controller: _title,
                        style: const TextStyle(fontSize: 15, color: kTextDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. Go to gym',
                          hintStyle:
                              const TextStyle(color: Color(0xFF9AA5A3)),
                          prefixIcon:
                              const Icon(Icons.alarm, color: kTextGrey),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: kTeal, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Day circles M T W T F S S
                      const _Label('Repeat', 13),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 7; i++)
                            _DayDot(
                              letter: dayLetters[i],
                              selected: _days.contains(i + 1),
                              onTap: () => setState(() {
                                _days.contains(i + 1)
                                    ? _days.remove(i + 1)
                                    : _days.add(i + 1);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // One-tap day presets
                      Row(
                        children: [
                          _PresetChip('Every day', _is({1, 2, 3, 4, 5, 6, 7}),
                              () => _setPreset({1, 2, 3, 4, 5, 6, 7})),
                          const SizedBox(width: 8),
                          _PresetChip('Weekdays', _is({1, 2, 3, 4, 5}),
                              () => _setPreset({1, 2, 3, 4, 5})),
                          const SizedBox(width: 8),
                          _PresetChip('Weekends', _is({6, 7}),
                              () => _setPreset({6, 7})),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Setting rows
                      line,
                      _SettingRow(
                        icon: Icons.volume_up_outlined,
                        title: 'Ring like an alarm',
                        trailing: _PillSwitch(
                            value: _ring,
                            onChanged: (v) => setState(() => _ring = v)),
                        onTap: () => setState(() => _ring = !_ring),
                      ),
                      line,
                      // The sound only matters when "Ring" is on.
                      Opacity(
                        opacity: _ring ? 1 : 0.4,
                        child: _SettingRow(
                          icon: Icons.notifications_none,
                          title: 'Alarm sound',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(alarmSoundName(_sound),
                                  style: const TextStyle(
                                      fontSize: 13, color: kTextGrey)),
                              const Icon(Icons.chevron_right,
                                  color: kTextGrey),
                            ],
                          ),
                          onTap: _ring ? _pickSound : null,
                        ),
                      ),
                      line,
                      _SettingRow(
                        icon: Icons.access_time,
                        title: 'Snooze 10 minutes',
                        trailing: _PillSwitch(
                            value: _snooze,
                            onChanged: (v) => setState(() => _snooze = v)),
                        onTap: () => setState(() => _snooze = !_snooze),
                      ),
                      line,
                    ],
                  ),
                ),

                // Save button stays at the bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PrimaryButton(
                    text:
                        widget.editing == null ? 'Save alarm' : 'Update alarm',
                    loading: _saving,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Small grey heading above a field.
class _Label extends StatelessWidget {
  final String text;
  final double size;
  const _Label(this.text, this.size);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w500,
                color: kTextGrey)),
      );
}

// One day circle. Amber when selected.
class _DayDot extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;
  const _DayDot(
      {required this.letter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kAmber : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? kAmber : kBorder, width: 1.5),
        ),
        child: Text(letter,
            style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : kTextDark)),
      ),
    );
  }
}

// Preset chip (Every day / Weekdays / Weekends).
class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kAmberLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? kAmber : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? kAmberDark : kTextDark)),
      ),
    );
  }
}

// One row of the list: icon, title and something on the right.
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap; // null = row cannot be tapped
  const _SettingRow(
      {required this.icon,
      required this.title,
      required this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, size: 24, color: kTextGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextDark)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// The small round switch from the design (44 x 26). Teal when on.
class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PillSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? kTeal : const Color(0xFFC9CFCE),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}