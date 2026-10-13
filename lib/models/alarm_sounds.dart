// One alarm sound the user can choose.
class AlarmSound {
  final String key; // file name in android/app/src/main/res/raw (no ".wav")
  final String name; // name shown in the app
  const AlarmSound(this.key, this.name);
}

const kAlarmSounds = [
  AlarmSound('morning_bell', 'Morning bell'),
  AlarmSound('soft_chime', 'Soft chime'),
  AlarmSound('digital_beep', 'Digital beep'),
  AlarmSound('default', 'Phone default'), // no file, uses the phone's own sound
];

const kDefaultAlarmSound = 'morning_bell';

// "morning_bell" -> "Morning bell"
String alarmSoundName(String key) => kAlarmSounds
    .firstWhere((s) => s.key == key, orElse: () => kAlarmSounds.first)
    .name;