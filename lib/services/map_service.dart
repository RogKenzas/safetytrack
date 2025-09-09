import 'dart:ui';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as location_package;
import 'dart:math' as math;

class MapService {
  // Position par défaut (Yaoundé, Cameroun) utilisée en fallback si la géolocalisation échoue
  final LatLng initialPosition = LatLng(3.848033, 11.502075);

  final List<LatLng> markers = [];

  // Ajouter un marqueur
  void addMarker(LatLng position) {
    markers.add(position);
  }

  // Supprimer un marqueur
  void removeMarker(LatLng position) {
    markers.remove(position);
  }

  // Réinitialiser tous les marqueurs
  void clearMarkers() {
    markers.clear();
  }

  /// Get current user position
  Future<LatLng?> getCurrentUserPosition() async {
    try {
      location_package.Location location = location_package.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return null;
      }

      location_package.PermissionStatus permissionGranted =
          await location.requestPermission();
      if (permissionGranted == location_package.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != location_package.PermissionStatus.granted)
          return null;
      }

      final locData = await location.getLocation();
      return LatLng(locData.latitude!, locData.longitude!);
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  // Alias pour getCurrentUserPosition
  Future<LatLng?> getCurrentPosition() async {
    return getCurrentUserPosition();
  }

  // Géocodage inverse : obtenir une adresse à partir de coordonnées
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      if (position.latitude == 0 && position.longitude == 0) {
        return "Position non définie";
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return "${placemark.street}, ${placemark.locality}";
      } else {
        return "Adresse non trouvée";
      }
    } catch (e, stack) {
      print('Erreur geocoding: $e');
      print(stack);
      return "Erreur lors de la récupération de l'adresse";
    }
  }

  Future<void> saveAddressForCurrentUser({
    required String name,
    required String address,
    required LatLng position,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Donnée d'adresse
    final addressData = {
      'name': name,
      'address': address,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Ajout dans un tableau d'adresses du parent
    await docRef.update({
      'addresses': FieldValue.arrayUnion([addressData]),
    });

    // Propager l'adresse vers tous les enfants liés
    final parentSnap = await docRef.get();
    if (parentSnap.exists) {
      final parentData = parentSnap.data();
      if (parentData != null && parentData['children'] != null) {
        final List<dynamic> children = parentData['children'];
        for (final child in children) {
          if (child is Map<String, dynamic> && child['uid'] != null) {
            final childRef = FirebaseFirestore.instance
                .collection('users')
                .doc(child['uid']);
            await childRef.update({
              'parentAddresses': FieldValue.arrayUnion([addressData]),
            });
          }
        }
      }
    }
  }

  // Suggérer des adresses basées sur une requête
  Future<List<Map<String, dynamic>>> suggestAddresses(String query) async {
    if (query.isEmpty) return [];

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> suggestions = [];

      for (Location location in locations) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          suggestions.add({
            'address':
                '${placemark.street}, ${placemark.locality}, ${placemark.country}',
            'latitude': location.latitude,
            'longitude': location.longitude,
            'street': placemark.street,
            'locality': placemark.locality,
            'country': placemark.country,
          });
        }
      }

      return suggestions;
    } catch (e) {
      print('Erreur lors de la suggestion d\'adresses: $e');
      return [];
    }
  }

  // Sauvegarder une zone de risque avec propagation automatique
  Future<void> saveRiskZone({
    required String name,
    required String address,
    required LatLng position,
    required String type,
    String? color,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    // Déterminer la couleur selon le type
    final zoneColor = color ?? _getZoneColor(type);

    final riskZone = {
      'name': name,
      'address': address,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'color': zoneColor.toString(),
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': user.uid,
    };

    // Sauvegarder dans le document de l'utilisateur
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    await userDocRef.update({
      'riskZones': FieldValue.arrayUnion([riskZone]),
    });

    // Propager aux enfants si c'est un parent
    final userDoc = await userDocRef.get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['children'] != null) {
        List<dynamic> children = userData['children'];
        for (var child in children) {
          if (child is Map<String, dynamic> && child['uid'] != null) {
            final childDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(child['uid']);
            await childDocRef.update({
              'parentRiskZones': FieldValue.arrayUnion([riskZone]),
            });
          }
        }
      }
    }
  }

  // Supprimer une zone de risque de l'utilisateur courant et la dé-propager des enfants
  Future<void> removeRiskZoneForCurrentUser(Map<String, dynamic> zone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDocRef.update({
      'riskZones': FieldValue.arrayRemove([zone]),
    });

    // Dé-propager des enfants si c'est un parent
    final userDoc = await userDocRef.get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['children'] != null) {
        final List<dynamic> children = userData['children'];
        for (final child in children) {
          if (child is Map<String, dynamic> && child['uid'] != null) {
            final childDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(child['uid']);
            await childDocRef.update({
              'parentRiskZones': FieldValue.arrayRemove([zone]),
            });
          }
        }
      }
    }
  }

  // Cette fonction est déjà définie ailleurs, il faut donc la renommer pour éviter le conflit.
  // Sauvegarder une adresse avec propagation automatique aux enfants
  Future<void> saveAddressForCurrentUserAddress({
    required String name,
    required String address,
    required LatLng position,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final addressData = {
      'name': name,
      'address': address,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Ajouter dans le tableau d'adresses de l'utilisateur
    await docRef.update({
      'addresses': FieldValue.arrayUnion([addressData]),
    });

    // Propager aux enfants si c'est un parent
    final userDoc = await docRef.get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['children'] != null) {
        List<dynamic> children = userData['children'];
        for (var child in children) {
          if (child is Map<String, dynamic> && child['uid'] != null) {
            final childDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(child['uid']);
            await childDocRef.update({
              'parentAddresses': FieldValue.arrayUnion([addressData]),
            });
          }
        }
      }
    }
  }

  // Supprimer une adresse de l'utilisateur courant et la dé-propager des enfants
  Future<void> removeAddressForCurrentUser(Map<String, dynamic> address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDocRef.update({
      'addresses': FieldValue.arrayRemove([address]),
    });

    // Dé-propager des enfants si c'est un parent
    final userDoc = await userDocRef.get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['children'] != null) {
        final List<dynamic> children = userData['children'];
        for (final child in children) {
          if (child is Map<String, dynamic> && child['uid'] != null) {
            final childDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(child['uid']);
            await childDocRef.update({
              'parentAddresses': FieldValue.arrayRemove([address]),
            });
          }
        }
      }
    }
  }

  // Partager explicitement une adresse existante avec tous les enfants liés
  Future<void> shareAddressWithChildren(Map<String, dynamic> address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final userDoc = await userDocRef.get();
    if (!userDoc.exists) return;

    final userData = userDoc.data();
    if (userData == null || userData['children'] == null) return;

    final List<dynamic> children = userData['children'];
    for (final child in children) {
      if (child is Map<String, dynamic> && child['uid'] != null) {
        final childDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(child['uid']);
        await childDocRef.update({
          'parentAddresses': FieldValue.arrayUnion([address]),
        });
      }
    }
  }

  // Obtenir la couleur par défaut selon le type de zone
  Color _getZoneColor(String type) {
    switch (type) {
      case 'school':
        return const Color(0xFFFF9800);
      case 'home':
        return const Color(0xFF4CAF50);
      case 'work':
        return const Color(0xFF2196F3);
      case 'park':
        return const Color(0xFF8BC34A);
      case 'hospital':
        return const Color(0xFFF44336);
      case 'shopping':
        return const Color(0xFF9C27B0);
      case 'risk':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // Calculer la distance entre deux points (formule de Haversine)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

    double lat1Rad = math.pi * point1.latitude / 180;
    double lat2Rad = math.pi * point2.latitude / 180;
    double deltaLatRad = math.pi * (point2.latitude - point1.latitude) / 180;
    double deltaLonRad = math.pi * (point2.longitude - point1.longitude) / 180;

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Vérifier si un point est proche d'une zone de risque
  bool isNearRiskZone(LatLng userPosition, LatLng riskZonePosition) {
    double distance = calculateDistance(userPosition, riskZonePosition);
    return distance <= 100;
  }
}
