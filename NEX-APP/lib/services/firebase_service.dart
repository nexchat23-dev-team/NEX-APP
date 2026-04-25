import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return auth.signOut();
  }

  Future<int> getUserTokenBalance() async {
    final user = currentUser;
    if (user == null) return 0;
    final doc = await firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['tokens'] ?? 0) as int;
  }

  Stream<int> listenTokenBalance() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
      return (snapshot.data()?['tokens'] ?? 0) as int;
    });
  }
}
