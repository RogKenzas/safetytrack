import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapService {
  // Position initiale de la carte (exemple : Paris)
  final LatLng initialPosition = LatLng(48.8588443, 2.2943506);

  // Liste des marqueurs (modifiable dynamiquement)
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
}
