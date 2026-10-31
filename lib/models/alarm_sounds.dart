// lib/models/alarm_sounds.dart

class AlarmSound {
  final String key;
  final String name;
  final String? assetPath;

  const AlarmSound({
    required this.key,
    required this.name,
    this.assetPath,
  });
}

const List<AlarmSound> kAlarmSounds = [
  AlarmSound(
    key: 'morning_bell',
    name: 'Morning bell',
    assetPath: 'audio/morning_bell.mp3',
  ),
  AlarmSound(
    key: 'soft_chime',
    name: 'Soft chime',
    assetPath: 'audio/soft_chime.mp3',
  ),
  AlarmSound(
    key: 'digital_beep',
    name: 'Digital beep',
    assetPath: 'audio/digital_beep.mp3',
  ),
  AlarmSound(
    key: 'default',
    name: 'Phone default',
    assetPath: 'audio/alarm.mp3',
  ),
];

const String kDefaultAlarmSound = 'morning_bell';

String alarmSoundName(String key) {
  return kAlarmSounds
      .firstWhere(
        (sound) => sound.key == key,
        orElse: () => kAlarmSounds.first,
      )
      .name;
}

AlarmSound alarmSoundByKey(String key) {
  return kAlarmSounds.firstWhere(
    (sound) => sound.key == key,
    orElse: () => kAlarmSounds.first,
  );
}