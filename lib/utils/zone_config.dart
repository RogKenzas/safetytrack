import 'package:flutter/material.dart';

class ZoneConfig {
  // Couleurs des zones par type
  static const Map<String, Color> zoneColors = {
    'home': Color(0xFF4CAF50),
    'work': Color(0xFF2196F3),
    'school': Color(0xFFFF9800),
    'park': Color(0xFF8BC34A),
    'hospital': Color(0xFFF44336),
    'shopping': Color(0xFF9C27B0),
    'risk': Color(0xFFFF5722),
    'transport': Color(0xFF607D8B),
    'entertainment': Color(0xFFE91E63),
    'sport': Color(0xFF795548),
  };

  // Types de zones disponibles
  static const List<Map<String, dynamic>> availableZoneTypes = [
    {
      'type': 'home',
      'label': 'Maison',
      'icon': Icons.home,
      'description': 'Zone résidentielle',
      'color': Color(0xFF4CAF50),
    },
    {
      'type': 'work',
      'label': 'Travail',
      'icon': Icons.work,
      'description': 'Zone professionnelle',
      'color': Color(0xFF2196F3),
    },
    {
      'type': 'school',
      'label': 'École',
      'icon': Icons.school,
      'description': 'Établissement scolaire',
      'color': Color(0xFFFF9800),
    },
    {
      'type': 'park',
      'label': 'Parc',
      'icon': Icons.park,
      'description': 'Espace vert',
      'color': Color(0xFF8BC34A),
    },
    {
      'type': 'hospital',
      'label': 'Hôpital',
      'icon': Icons.local_hospital,
      'description': 'Établissement de santé',
      'color': Color(0xFFF44336),
    },
    {
      'type': 'shopping',
      'label': 'Commerce',
      'icon': Icons.shopping_cart,
      'description': 'Zone commerciale',
      'color': Color(0xFF9C27B0),
    },
    {
      'type': 'transport',
      'label': 'Transport',
      'icon': Icons.directions_bus,
      'description': 'Arrêt de transport',
      'color': Color(0xFF607D8B),
    },
    {
      'type': 'entertainment',
      'label': 'Loisirs',
      'icon': Icons.movie,
      'description': 'Zone de divertissement',
      'color': Color(0xFFE91E63),
    },
    {
      'type': 'sport',
      'label': 'Sport',
      'icon': Icons.sports_soccer,
      'description': 'Zone sportive',
      'color': Color(0xFF795548),
    },
    {
      'type': 'risk',
      'label': 'Zone à risque',
      'icon': Icons.warning,
      'description': 'Zone dangereuse',
      'color': Color(0xFFFF5722),
    },
  ];

  // Obtenir la couleur d'une zone par type
  static Color getZoneColor(String type) {
    return zoneColors[type] ?? const Color(0xFF9E9E9E);
  }

  // Obtenir les informations d'un type de zone
  static Map<String, dynamic>? getZoneTypeInfo(String type) {
    try {
      return availableZoneTypes.firstWhere((zone) => zone['type'] == type);
    } catch (e) {
      return null;
    }
  }

  // Obtenir l'icône d'une zone par type
  static IconData getZoneIcon(String type) {
    final zoneInfo = getZoneTypeInfo(type);
    return zoneInfo?['icon'] ?? Icons.location_on;
  }

  // Obtenir le label d'une zone par type
  static String getZoneLabel(String type) {
    final zoneInfo = getZoneTypeInfo(type);
    return zoneInfo?['label'] ?? 'Zone inconnue';
  }

  // Obtenir la description d'une zone par type
  static String getZoneDescription(String type) {
    final zoneInfo = getZoneTypeInfo(type);
    return zoneInfo?['description'] ?? 'Type de zone non spécifié';
  }

  // Vérifier si un type de zone est valide
  static bool isValidZoneType(String type) {
    return zoneColors.containsKey(type);
  }

  // Obtenir tous les types de zones valides
  static List<String> getValidZoneTypes() {
    return zoneColors.keys.toList();
  }

  // Obtenir la liste des types avec leurs informations complètes
  static List<Map<String, dynamic>> getAllZoneTypes() {
    return List.from(availableZoneTypes);
  }
}
