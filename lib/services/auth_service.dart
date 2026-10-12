
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Authentication state stream for AuthGate
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user
  Future<UserCredential> register(
    String name,
    String email,
    String password,
  ) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Could not create the user account.',
      );
    }

    // Save user profile in Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': cleanName,
      'email': cleanEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update Firebase Auth display name
    await user.updateDisplayName(cleanName);

    return credential;
  }

  // Login existing user
  Future<UserCredential> login(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
