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

  /// Lie un enfant à un parent et propage les adresses du parent vers le document de l'enfant
  Future<void> linkChildToParent({
    required String parentUid,
    required String childUid,
    required String childEmail,
    required String childName,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final parentRef = firestore.collection('users').doc(parentUid);
    final childRef = firestore.collection('users').doc(childUid);

    // Ajouter l'enfant dans le tableau children du parent
    await parentRef.update({
      'children': FieldValue.arrayUnion([
        {
          'uid': childUid,
          'email': childEmail,
          'name': childName,
          // Les adresses propres de l'enfant peuvent être remplies côté enfant
          'addresses': [],
        },
      ]),
    });

    // S'assurer que le document enfant existe et contient la référence au parent
    await childRef.set({
      'uid': childUid,
      'parentUid': parentUid,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Récupérer les adresses du parent et les copier dans le document enfant sous "parentAddresses"
    final parentSnap = await parentRef.get();
    final parentData = parentSnap.data();
    final List<dynamic> parentAddresses =
        (parentData != null
            ? (parentData['addresses'] as List<dynamic>? ?? [])
            : []);

    await childRef.set({
      'parentAddresses': parentAddresses,
    }, SetOptions(merge: true));
  }

  Future<User?> registerWithEmail(
    String email,
    String password, {
    String? name,
    String? accountType,
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
          'accountType': accountType ?? 'parent',
          'addresses': [],
          'children': [],
          'riskZones': [],
          'createdAt': DateTime.now().toIso8601String(),
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
          return rawAddresses.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('accountType', isEqualTo: 'child')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    return {
      'uid': data['uid'],
      'email': data['email'],
      'name': data['name'],
      'addresses': data['addresses'] ?? [],
    };
  }

  Future<List<String>> suggestChildEmails(String query) async {
    if (query.isEmpty) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('accountType', isEqualTo: 'child')
            .where('email', isGreaterThanOrEqualTo: query)
            .where('email', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(10)
            .get();
    return snapshot.docs
        .map((doc) => doc.data()['email'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCurrentUserChildrenAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('children')) {
          final List<dynamic> children = data['children'];
          List<Map<String, dynamic>> allAddresses = [];

          for (var child in children) {
            if (child is Map<String, dynamic> &&
                child.containsKey('addresses')) {
              final List<dynamic> childAddresses = child['addresses'];
              for (var address in childAddresses) {
                if (address is Map<String, dynamic>) {
                  allAddresses.add({
                    ...address,
                    'childName': child['name'],
                    'childEmail': child['email'],
                  });
                }
              }
            }
          }
          return allAddresses;
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les positions actuelles des enfants liés au compte courant
  Future<List<Map<String, dynamic>>> getCurrentUserChildrenLocations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final firestore = FirebaseFirestore.instance;
      final parentDoc = await firestore.collection('users').doc(user.uid).get();
      if (!parentDoc.exists) return [];
      final data = parentDoc.data();
      final List<dynamic> children =
          (data?['children'] as List<dynamic>?) ?? [];
      final List<Map<String, dynamic>> locations = [];

      for (final child in children) {
        if (child is Map<String, dynamic> && child['uid'] != null) {
          final childUid = child['uid'] as String;
          final childSnap =
              await firestore.collection('users').doc(childUid).get();
          if (childSnap.exists) {
            final childData = childSnap.data();
            final currentLocation =
                childData?['currentLocation'] as Map<String, dynamic>?;
            final double? lat =
                (currentLocation?['latitude'] as num?)?.toDouble();
            final double? lon =
                (currentLocation?['longitude'] as num?)?.toDouble();
            if (lat != null && lon != null) {
              locations.add({
                'name': child['name'] ?? 'Enfant',
                'latitude': lat,
                'longitude': lon,
                'lastUpdate': currentLocation?['lastUpdate'],
              });
            }
          }
        }
      }
      return locations;
    } catch (e) {
      rethrow;
    }
  }

  /// Adresse partagée par le parent: récupère sur l'enfant les adresses
  Future<List<Map<String, dynamic>>> getChildParentAddresses(
    String childUid,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(childUid)
              .get();
      if (!doc.exists) return [];
      final data = doc.data();
      final List<dynamic> raw =
          (data?['parentAddresses'] as List<dynamic>?) ?? [];
      return raw.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentUserAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('addresses')) {
          final List<dynamic> rawAddresses = data['addresses'];
          return rawAddresses.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentUserRiskZones() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('riskZones')) {
          final List<dynamic> rawRiskZones = data['riskZones'];
          return rawRiskZones.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère le nom de l'utilisateur connecté depuis Firestore
  Future<String?> getCurrentUserName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('name')) {
          return data['name'] as String?;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère l'utilisateur actuellement connecté
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Récupère toutes les données de l'utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
