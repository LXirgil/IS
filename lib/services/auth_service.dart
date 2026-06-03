import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._private();
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._private();

  FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth => _auth ??= FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

