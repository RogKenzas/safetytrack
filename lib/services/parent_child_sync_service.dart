import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class ParentChildSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Streams pour la synchronisation temps réel
  StreamSubscription<DocumentSnapshot>? _parentLocationListener;
  StreamSubscription<DocumentSnapshot>? _parentZonesListener;
  StreamSubscription<DocumentSnapshot>? _childLocationListener;
  
  // Callbacks pour les mises à jour
  Function(LatLng)? onParentLocationUpdate;
  Function(List<Map<String, dynamic>>)? onParentZonesUpdate;
  Function(LatLng)? onChildLocationUpdate;

  /// Démarrer la synchronisation pour un parent
  Future<void> startParentSync({
    required String childUid,
    required Function(LatLng) onChildLocationUpdate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    this.onChildLocationUpdate = onChildLocationUpdate;

    // Écouter la position de l'enfant
    _childLocationListener = _firestore
        .collection('users')
        .doc(childUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['currentLocation'] != null) {
          final location = data['currentLocation'];
          final latLng = LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          );
          onChildLocationUpdate(latLng);
        }
      }
    });
  }

  /// Démarrer la synchronisation pour un enfant
  Future<void> startChildSync({
    required String parentUid,
    required Function(LatLng) onParentLocationUpdate,
    required Function(List<Map<String, dynamic>>) onParentZonesUpdate,
  }) async {
    this.onParentLocationUpdate = onParentLocationUpdate;
    this.onParentZonesUpdate = onParentZonesUpdate;

    // Écouter la position du parent
    _parentLocationListener = _firestore
        .collection('users')
        .doc(parentUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['currentLocation'] != null) {
          final location = data['currentLocation'];
          final latLng = LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          );
          onParentLocationUpdate(latLng);
        }
      }
    });

    // Écouter les zones d'alerte du parent
    _parentZonesListener = _firestore
        .collection('users')
        .doc(parentUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['riskZones'] != null) {
          final List<dynamic> rawZones = data['riskZones'];
          final zones = rawZones
              .whereType<Map<String, dynamic>>()
              .map((zone) => Map<String, dynamic>.from(zone))
              .toList();
          onParentZonesUpdate(zones);
        }
      }
    });
  }

  /// Mettre à jour la position actuelle de l'utilisateur
  Future<void> updateCurrentLocation(LatLng position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la position: $e');
    }
  }

  /// Propager une zone d'alerte aux enfants
  Future<void> propagateRiskZoneToChildren(Map<String, dynamic> riskZone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer la liste des enfants
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['children'] != null) {
          List<dynamic> children = userData['children'];
          
          // Ajouter la zone d'alerte à chaque enfant
          for (var child in children) {
            if (child is Map<String, dynamic> && child['uid'] != null) {
              await _firestore
                  .collection('users')
                  .doc(child['uid'])
                  .update({
                'parentRiskZones': FieldValue.arrayUnion([riskZone]),
              });
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la propagation de la zone d\'alerte: $e');
    }
  }

  /// Récupérer les zones d'alerte du parent pour un enfant
  Future<List<Map<String, dynamic>>> getParentRiskZones(String parentUid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(parentUid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['riskZones'] != null) {
          final List<dynamic> rawZones = data['riskZones'];
          return rawZones
              .whereType<Map<String, dynamic>>()
              .map((zone) => Map<String, dynamic>.from(zone))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des zones d\'alerte: $e');
      return [];
    }
  }

  /// Récupérer la position actuelle du parent
  Future<LatLng?> getParentCurrentLocation(String parentUid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(parentUid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['currentLocation'] != null) {
          final location = data['currentLocation'];
          return LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          );
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la position du parent: $e');
      return null;
    }
  }

  /// Arrêter toutes les synchronisations
  void stopAllSync() {
    _parentLocationListener?.cancel();
    _parentZonesListener?.cancel();
    _childLocationListener?.cancel();
    
    _parentLocationListener = null;
    _parentZonesListener = null;
    _childLocationListener = null;
  }

  /// Vérifier si un utilisateur est en ligne
  Future<bool> isUserOnline(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['currentLocation'] != null) {
          final timestamp = data['currentLocation']['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final now = DateTime.now();
            final lastUpdate = timestamp.toDate();
            final difference = now.difference(lastUpdate);
            
            // Considérer en ligne si la dernière mise à jour date de moins de 5 minutes
            return difference.inMinutes < 5;
          }
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du statut en ligne: $e');
      return false;
    }
  }

  /// Obtenir le statut de connexion de tous les enfants d'un parent
  Future<List<Map<String, dynamic>>> getChildrenOnlineStatus(String parentUid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(parentUid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['children'] != null) {
          List<dynamic> children = data['children'];
          List<Map<String, dynamic>> childrenStatus = [];

          for (var child in children) {
            if (child is Map<String, dynamic> && child['uid'] != null) {
              final isOnline = await isUserOnline(child['uid']);
              childrenStatus.add({
                'uid': child['uid'],
                'name': child['name'] ?? 'Enfant',
                'email': child['email'] ?? '',
                'isOnline': isOnline,
                'lastSeen': isOnline ? 'En ligne' : 'Hors ligne',
              });
            }
          }
          return childrenStatus;
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération du statut des enfants: $e');
      return [];
    }
  }
}
