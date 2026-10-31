
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>
      _settingsDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences');
  }

  static String _currentUid() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  // Load settings for the currently logged-in user.
  static Future<Map<String, dynamic>> loadSettings() async {
    final uid = _currentUid();

    final snapshot =
        await _settingsDocument(uid).get();

    return snapshot.data() ?? {
      'defaultRadius': 700,
      'defaultAlert': 'Message',
      'alarmSound': 'Morning bell',
    };
  }

  // Save only the settings that have changed.
  static Future<void> saveSettings(
    Map<String, dynamic> settings,
  ) async {
    final uid = _currentUid();

    await _settingsDocument(uid).set(
      settings,
      SetOptions(merge: true),
    );
  }
}
