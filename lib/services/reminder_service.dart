
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder.dart';

// All Firestore work for reminders is done here.
class ReminderService {
  // Path: users/{current user id}/reminders
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('reminders');

  // Live list of reminders, newest first.
  Stream<List<Reminder>> stream() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Reminder.fromDoc).toList());

  // Save a new reminder and return its Firestore document ID.
  Future<String> add(Map<String, dynamic> data) async {
    final doc = await _col.add({
      ...data,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Update an existing reminder without changing its document ID.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  // Change status: active / triggered / done / paused.
  Future<void> setStatus(String id, String status) =>
      _col.doc(id).update({'status': status});

  // Delete a reminder.
  Future<void> delete(String id) => _col.doc(id).delete();
}
