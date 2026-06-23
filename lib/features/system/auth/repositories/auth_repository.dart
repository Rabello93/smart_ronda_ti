import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('tecnicos').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserDoc(String uid) {
    return _firestore.collection('tecnicos').doc(uid).get();
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('tecnicos').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);
}
