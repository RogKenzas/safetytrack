import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:safetytrack/services/auth_service.dart';
import 'package:safetytrack/services/map_service.dart';

class AddAlertZone extends StatefulWidget {
  const AddAlertZone({super.key});

  @override
  State<AddAlertZone> createState() => AddAlertZoneState();
}

class AddAlertZoneState extends State<AddAlertZone> {
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();
  LatLng _mapCenter = LatLng(0, 0);
  LatLng? _currentPosition;
  String address = '3.730 Rue Ngoa Ekelle, Yaounde';
  bool _loadingLocation = true;
  List<Map<String, dynamic>> _childrenAddresses = [];
  List<Map<String, dynamic>> _userAddresses = [];
  List<Map<String, dynamic>> _riskZones = []; // Zones de risque ajoutées

  Future<void> _loadChildrenAddresses() async {
    try {
      final addresses = await _authService.getCurrentUserChildrenAddresses();
      setState(() {
        _childrenAddresses = addresses;
      });
    } catch (e) {
      print('Erreur lors du chargement des adresses enfants: $e');
    }
  }

  Future<void> _loadUserAddresses() async {
    try {
      final addresses = await _authService.getCurrentUserAddresses();
      setState(() {
        _userAddresses = addresses;
      });
    } catch (e) {
      print('Erreur lors du chargement des adresses utilisateur: $e');
    }
  }

  Future<void> _loadRiskZones() async {
    try {
      final riskZones = await _authService.getCurrentUserRiskZones();
      setState(() {
        _riskZones = riskZones;
      });
    } catch (e) {
      print('Erreur lors du chargement des zones de risque: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadChildrenAddresses();
    _loadUserAddresses();
    _loadRiskZones();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _loadingLocation = false);
          return;
        }
      }
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _loadingLocation = false);
          return;
        }
      }
      final locData = await location.getLocation();
      final pos = LatLng(locData.latitude!, locData.longitude!);
      setState(() {
        _currentPosition = pos;
        _mapCenter = pos;
        _loadingLocation = false;
      });
      if (_currentPosition != null) {
        final newAddress = await _mapService.getAddressFromLatLng(
          _currentPosition!,
        );
        setState(() {
          address = newAddress;
        });
      }
    } catch (e) {
      print('Erreur de géolocalisation (probablement sur web): $e');
      // Position par défaut pour le web
      setState(() {
        _currentPosition = _mapService.initialPosition;
        _mapCenter = _mapService.initialPosition;
        _loadingLocation = false;
        address = 'Position par défaut';
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    _handleMapTap(position);
  }

  Future<void> _handleMapTap(LatLng position) async {
    try {
      final address = await _mapService.getAddressFromLatLng(position);

      final name = await _showRiskZoneDialog();
      if (name != null && name.isNotEmpty) {
        final riskZone = {
          'name': name,
          'address': address,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'type': 'Zone de risque',
          'createdAt': DateTime.now().toIso8601String(),
        };

        setState(() {
          _riskZones.add(riskZone);
        });

        try {
          await _mapService.saveRiskZone(
            name: name,
            address: address,
            position: position,
            type: 'Zone de risque',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Zone de risque "$name" ajoutée avec succès !'),
                backgroundColor: const Color(0xFF179D5B),
                duration: Duration(seconds: 2),
              ),
            );
            
            // Retourner à l'onboarding après un délai
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        } catch (firestoreError) {
          print(
            'Erreur Firestore (mais zone ajoutée localement): $firestoreError',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Zone "$name" ajoutée localement. Vérifiez les permissions Firestore.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la zone de risque: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la zone de risque: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRiskZoneDialog() async {
    final TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Nommer la zone de risque',
              style: GoogleFonts.poppins(),
            ),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la zone',
                hintText: 'Ex: Zone dangereuse, Rue sombre...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(nameController.text),
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildChildMarker(String type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child:
              (type == 'Maison')
                  ? const Center(
                    child: Icon(Icons.home, size: 16, color: Color(0xFF179D5B)),
                  )
                  : (type == 'École')
                  ? const Center(
                    child: Icon(
                      Icons.school,
                      size: 16,
                      color: Color(0xFF179D5B),
                    ),
                  )
                  : null,
        ),
      ],
    );
  }

  Widget _buildUserAddressMarker(String type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: _getIconForType(type),
        ),
      ],
    );
  }

  Widget _buildRiskZoneMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.warning, size: 16, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'Maison':
        return const Center(
          child: Icon(Icons.home, size: 16, color: Colors.amber),
        );
      case 'École':
        return const Center(
          child: Icon(Icons.school, size: 16, color: Colors.amber),
        );
      default:
        return const Center(
          child: Icon(Icons.location_on, size: 16, color: Colors.amber),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                _loadingLocation
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF179D5B),
                      ),
                    )
                    : FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            _currentPosition ?? _mapService.initialPosition,
                        initialZoom: 16,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                          subdomains: ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.safetytrack',
                          retinaMode: RetinaMode.isHighDensity(context),
                        ),
                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                child: _buildUserMarker(),
                              ),
                              ..._userAddresses
                                  .map((address) {
                                    final lat = address['latitude'] as double?;
                                    final lng = address['longitude'] as double?;
                                    final type =
                                        address['type'] as String? ?? 'Autre';

                                    if (lat != null && lng != null) {
                                      return Marker(
                                        point: LatLng(lat, lng),
                                        width: 60,
                                        height: 60,
                                        alignment: Alignment.center,
                                        child: _buildUserAddressMarker(type),
                                      );
                                    }
                                    return null;
                                  })
                                  .whereType<Marker>()
                                  .toList(),
                              ..._childrenAddresses
                                  .map((address) {
                                    final lat = address['latitude'] as double?;
                                    final lng = address['longitude'] as double?;
                                    final type =
                                        address['type'] as String? ?? 'Autre';

                                    if (lat != null && lng != null) {
                                      return Marker(
                                        point: LatLng(lat, lng),
                                        width: 60,
                                        height: 60,
                                        alignment: Alignment.center,
                                        child: _buildChildMarker(type),
                                      );
                                    }
                                    return null;
                                  })
                                  .whereType<Marker>()
                                  .toList(),
                              ..._riskZones
                                  .map((zone) {
                                    final lat = zone['latitude'] as double?;
                                    final lng = zone['longitude'] as double?;

                                    if (lat != null && lng != null) {
                                      return Marker(
                                        point: LatLng(lat, lng),
                                        width: 60,
                                        height: 60,
                                        alignment: Alignment.center,
                                        child: _buildRiskZoneMarker(),
                                      );
                                    }
                                    return null;
                                  })
                                  .whereType<Marker>()
                                  .toList(),
                            ],
                          ),
                      ],
                    ),
          ),

          // Bouton retour
          Positioned(
            top: 44,
            left: 16,
            child: _floatingIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Température
          Positioned(top: 120, left: 20, child: _floatingLabel('23°C 🌥️')),

          // Boutons à droite
          Positioned(bottom: 120, right: 20, child: _rightButtons()),

          // Draggable sheet
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _floatingIcon({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF179D5B), size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _floatingLabel(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF179D5B),
          ),
        ),
      ),
    );
  }

  Widget _rightButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.black),
              ),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.map, color: Color(0xFF179D5B)),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF179D5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.10,
      minChildSize: 0.10,
      maxChildSize: 0.35,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/img/google.png'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Position Actuelle',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              address,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.battery_full,
                            color: Color(0xFF179D5B),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '72 %',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18, left: 18, right: 18),
                  child: Row(
                    children: [
                      _placeButton(
                        icon: Icons.home,
                        label: 'Maison',
                        isFilled: true,
                      ),
                      const SizedBox(width: 8),
                      _placeButton(icon: Icons.location_city, label: 'École'),
                      const SizedBox(width: 8),
                      _placeButton(
                        icon: Icons.person_pin_circle,
                        label: 'Maison Ken..',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(
                  color: Color(0xFFE8E8E8),
                  thickness: 1,
                  indent: 18,
                  endIndent: 18,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lieu',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maison',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Adresse',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeButton({
    required IconData icon,
    required String label,
    bool isFilled = false,
  }) {
    if (isFilled) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(icon, color: const Color(0xFF179D5B)),
          label: Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8F5EF),
            foregroundColor: const Color(0xFF179D5B),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    } else {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(icon, color: const Color(0xFFBDBDBD)),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFBDBDBD),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE8E8E8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    }
  }
}
