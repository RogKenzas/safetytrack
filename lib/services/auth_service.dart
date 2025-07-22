import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null && name != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
        });
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _getMessageFromErrorCode(e);
    }
  }

  String _getMessageFromErrorCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "L'adresse email est invalide.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'user-not-found':
        return "Aucun utilisateur trouvé pour cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'email-already-in-use':
        return "Cet email est déjà utilisé.";
      case 'weak-password':
        return "Le mot de passe est trop faible.";
      default:
        return "Une erreur est survenue. Veuillez réessayer.";
    }
  }

  Future<List<Map<String, dynamic>>> getUserAddresses(String uid) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('addresses')) {
          final List<dynamic> rawAddresses = data['addresses'];
          return rawAddresses
              .whereType<Map<String, dynamic>>()
              .toList(); // convertit et filtre
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
