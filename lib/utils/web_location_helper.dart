import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Helper pour gérer la géolocalisation sur le web
class WebLocationHelper {
  /// Vérifier si la géolocalisation est supportée
  static bool get isGeolocationSupported {
    if (!kIsWeb) return false;
    return html.window.navigator.geolocation != null;
  }

  /// Vérifier si HTTPS est requis
  static bool get isHttpsRequired {
    if (!kIsWeb) return false;
    return html.window.location.protocol != 'https:' &&
        html.window.location.hostname != 'localhost';
  }

  /// Obtenir la position actuelle avec gestion d'erreurs
  static Future<Map<String, dynamic>?> getCurrentPosition() async {
    if (!kIsWeb || !isGeolocationSupported) {
      return null;
    }

    try {
      final position =
          await html.window.navigator.geolocation.getCurrentPosition();
      return {
        'latitude': position.coords?.latitude ?? 0.0,
        'longitude': position.coords?.longitude ?? 0.0,
        'accuracy': position.coords?.accuracy ?? 0.0,
        'timestamp': position.timestamp ?? 0,
      };
    } catch (e) {
      print('Erreur géolocalisation web: $e');
      return null;
    }
  }

  /// Obtenir le message d'erreur approprié
  static String getErrorMessage(dynamic error) {
    if (!kIsWeb) return 'Géolocalisation non supportée';

    if (isHttpsRequired) {
      return 'HTTPS requis pour la géolocalisation';
    }

    if (!isGeolocationSupported) {
      return 'Géolocalisation non supportée par ce navigateur';
    }

    return 'Erreur de géolocalisation: $error';
  }

  /// Vérifier les permissions de géolocalisation
  static Future<bool> checkPermission() async {
    if (!kIsWeb || !isGeolocationSupported) return false;

    try {
      // Essayer d'obtenir la position pour vérifier les permissions
      await html.window.navigator.geolocation.getCurrentPosition();
      return true;
    } catch (e) {
      return false;
    }
  }
}
