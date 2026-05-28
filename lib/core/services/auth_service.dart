import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
    String phoneNumber,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'displayName': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': 'user',
          'rating': 5.0,
        });
      }

      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return null;
  }
}
