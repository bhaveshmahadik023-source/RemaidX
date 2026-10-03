import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = cred.user!.uid;

    _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint('Firestore error: $e'));

    cred.user!.updateDisplayName(name.trim());
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> googleLogin() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});

    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);

    final user = cred.user!;
    await _db.collection('users').doc(user.uid).set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> logout() => _auth.signOut();
}