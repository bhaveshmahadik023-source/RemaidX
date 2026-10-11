import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder.dart';

// All Firestore work for reminders is done here.
// Screens never talk to Firestore directly, they call this class.
class ReminderService {
  // Path: users/{current user id}/reminders
  // Each user can only see their own reminders.
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('reminders');

  // Live list of reminders, newest first.
  // It updates automatically when data changes in Firestore.
  // Note: a document without "createdAt" will not appear in this list.
  Stream<List<Reminder>> stream() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Reminder.fromDoc).toList());

  // Save a new reminder. Status starts as "active".
  Future<void> add(Map<String, dynamic> data) => _col.add({
        ...data,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

  // Change status (active / triggered / done / paused).
  Future<void> setStatus(String id, String status) =>
      _col.doc(id).update({'status': status});

  // Delete a reminder.
  Future<void> delete(String id) => _col.doc(id).delete();
}