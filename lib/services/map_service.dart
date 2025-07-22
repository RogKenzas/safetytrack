import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> saveAddressForCurrentUser({
    required String name,
    required String address,
    required LatLng position,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    // Ajout dans un tableau d'adresses (array)
    await docRef.update({
      'addresses': FieldValue.arrayUnion([
        {
          'name': name,
          'address': address,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'type': type,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ]),
    });
  }

  
  
  // void _showAddressModal({Map<String, String>? initial, int? index}) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     isDismissible: true,
  //     enableDrag: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       String type = initial?['type'] ?? 'Maison';
  //       String nom = initial?['type'] ?? '';
  //       String adresse = initial?['address'] ?? '';
  //       final types = ['Maison', 'École', 'Autre'];
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return Padding(
  //             padding: EdgeInsets.only(
  //               bottom: MediaQuery.of(context).viewInsets.bottom,
  //             ),
  //             child: SingleChildScrollView(
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 20,
  //                   vertical: 24,
  //                 ),
  //                 decoration: const BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.only(
  //                     topLeft: Radius.circular(28),
  //                     topRight: Radius.circular(28),
  //                   ),
  //                 ),
  //                 child: SafeArea(
  //                   top: false,
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     crossAxisAlignment: CrossAxisAlignment.stretch,
  //                     children: [
  //                       Center(
  //                         child: Container(
  //                           width: 40,
  //                           height: 4,
  //                           margin: const EdgeInsets.only(bottom: 18),
  //                           decoration: BoxDecoration(
  //                             color: Colors.grey.shade300,
  //                             borderRadius: BorderRadius.circular(2),
  //                           ),
  //                         ),
  //                       ),
  //                       Text(
  //                         index == null
  //                             ? 'Ajouter une adresse'
  //                             : 'Modifier l’adresse',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                       const SizedBox(height: 18),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children:
  //                             types
  //                                 .map(
  //                                   (t) => Padding(
  //                                     padding: const EdgeInsets.symmetric(
  //                                       horizontal: 6,
  //                                     ),
  //                                     child: ChoiceChip(
  //                                       label: Row(
  //                                         children: [
  //                                           if (t == 'Maison')
  //                                             const Icon(
  //                                               Icons.home,
  //                                               size: 18,
  //                                               color: Color(0xFF179D5B),
  //                                             ),
  //                                           if (t == 'École')
  //                                             const Icon(
  //                                               Icons.school,
  //                                               size: 18,
  //                                               color: Color(0xFF179D5B),
  //                                             ),
  //                                           if (t == 'Autre')
  //                                             const Icon(
  //                                               Icons.add,
  //                                               size: 18,
  //                                               color: Color(0xFF179D5B),
  //                                             ),
  //                                           const SizedBox(width: 4),
  //                                           Text(
  //                                             t,
  //                                             style: GoogleFonts.poppins(
  //                                               fontWeight: FontWeight.w500,
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                       selected: type == t,
  //                                       selectedColor: const Color(0xFF179D5B),
  //                                       backgroundColor: Colors.white,
  //                                       labelStyle: TextStyle(
  //                                         color:
  //                                             type == t
  //                                                 ? Colors.white
  //                                                 : Colors.black87,
  //                                       ),
  //                                       shape: RoundedRectangleBorder(
  //                                         borderRadius: BorderRadius.circular(
  //                                           16,
  //                                         ),
  //                                         side: BorderSide(
  //                                           color:
  //                                               type == t
  //                                                   ? const Color(0xFF179D5B)
  //                                                   : Colors.grey.shade300,
  //                                         ),
  //                                       ),
  //                                       onSelected: (val) {
  //                                         setModalState(() => type = t);
  //                                       },
  //                                     ),
  //                                   ),
  //                                 )
  //                                 .toList(),
  //                       ),
  //                       const SizedBox(height: 18),
  //                       TextField(
  //                         decoration: InputDecoration(
  //                           labelText: 'Nom',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                         controller: TextEditingController(text: nom),
  //                         onChanged: (v) => nom = v,
  //                       ),
  //                       const SizedBox(height: 14),
  //                       TextField(
  //                         decoration: InputDecoration(
  //                           labelText: 'Adresse',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                         controller: TextEditingController(text: adresse),
  //                         onChanged: (v) => adresse = v,
  //                       ),
  //                       const SizedBox(height: 22),
  //                       Row(
  //                         children: [
  //                           Expanded(
  //                             child: OutlinedButton(
  //                               onPressed: () => Navigator.pop(context),
  //                               style: OutlinedButton.styleFrom(
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                                 side: const BorderSide(
  //                                   color: Color(0xFF179D5B),
  //                                 ),
  //                               ),
  //                               child: Text(
  //                                 'Annuler',
  //                                 style: GoogleFonts.poppins(
  //                                   color: const Color(0xFF179D5B),
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 16),
  //                           Expanded(
  //                             child: ElevatedButton(
  //                               onPressed: () {
  //                                 if (nom.isEmpty || adresse.isEmpty) return;
  //                                 setState(() {
  //                                   if (index == null) {
  //                                     addresses.add({
  //                                       'type': type,
  //                                       'address': adresse,
  //                                     });
  //                                   } else {
  //                                     addresses[index] = {
  //                                       'type': type,
  //                                       'address': adresse,
  //                                     };
  //                                   }
  //                                 });
  //                                 Navigator.pop(context);
  //                               },
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: const Color(0xFF179D5B),
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                               ),
  //                               child: Text(
  //                                 'Enregistrer',
  //                                 style: GoogleFonts.poppins(
  //                                   color: Colors.white,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

}
