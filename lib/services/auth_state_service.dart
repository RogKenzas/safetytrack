import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStateService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthStateService() {
    _init();
  }

  void _init() {
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;

      if (user != null) {
        // Utilisateur connecté, récupérer ses données depuis Firestore
        await _loadUserData(user.uid);
      } else {
        // Utilisateur déconnecté
        _userData = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  } 

  Future<void> _loadUserData(String uid) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        _userData = docSnapshot.data();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
      _userData = null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userData = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.uid);
      notifyListeners();
    }
  }
}
