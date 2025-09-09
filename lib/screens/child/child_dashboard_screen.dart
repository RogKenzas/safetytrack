import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_state_service.dart';
import '../../services/map_service.dart';
// import '../../components/child/zone_info_card.dart';
// import '../../components/child/parent_location_card.dart';
import '../panic_alert_screen.dart';
import 'dart:async';

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _parentRiskZones = [];
  List<Map<String, dynamic>> _parentAddresses = [];
  Map<String, dynamic>? _parentLocation;
  Timer? _locationUpdateTimer;
  bool _isLoading = true;
  String _currentAddress = 'Chargement de l\'adresse...';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _panicVisible = false;
  String? _childName;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _getCurrentLocation();
      await _loadParentData();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await _mapService.getCurrentUserPosition();
    if (position != null) {
      setState(() => _currentPosition = position);
      // Mettre à jour l'adresse actuelle
      final address = await _mapService.getAddressFromLatLng(position);
      setState(() => _currentAddress = address);

      // Sauvegarder la position actuelle dans Firestore
      await _updateCurrentLocationInFirestore(position);

      // Vérifier la proximité aux zones de risque
      await _maybeShowPanic(position);
    }
  }

  Future<void> _updateCurrentLocationInFirestore(LatLng position) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'lastUpdate': DateTime.now().toIso8601String(),
          },
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la position: $e');
    }
  }

  Future<void> _loadParentData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final parentUid = userData?['parentUid'] as String?;
          final propagatedZones = List<Map<String, dynamic>>.from(
            userData?['parentRiskZones'] ?? [],
          );
          final propagatedAddresses = List<Map<String, dynamic>>.from(
            userData?['parentAddresses'] ?? [],
          );

          setState(() {
            _parentRiskZones = propagatedZones;
            _parentAddresses = propagatedAddresses;
            _childName = (userData?['name'] as String?) ?? 'Enfant';
          });

          if (parentUid != null) {
            // Charger les zones de risque du parent
            final parentDoc =
                await _firestore.collection('users').doc(parentUid).get();
            if (parentDoc.exists) {
              final parentData = parentDoc.data();

              // Récupérer la position actuelle du parent
              final currentLocation = parentData?['currentLocation'];

              setState(() {
                if (currentLocation != null) {
                  _parentLocation = {
                    'name': 'Position Parent',
                    'latitude': currentLocation['latitude'],
                    'longitude': currentLocation['longitude'],
                    'lastUpdate': DateTime.parse(currentLocation['lastUpdate']),
                  };
                }
              });
            }
          }

          // Si la position est déjà connue, re-vérifier la proximité après chargement des zones
          if (_currentPosition != null) {
            await _maybeShowPanic(_currentPosition!);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données parent: $e');
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation();
      _loadParentData(); // Mettre à jour les données du parent
    });
  }

  Future<void> _maybeShowPanic(LatLng position) async {
    if (_panicVisible) return;
    for (final zone in _parentRiskZones) {
      try {
        final double? lat = (zone['latitude'] as num?)?.toDouble();
        final double? lon = (zone['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        final zonePos = LatLng(lat, lon);
        final isNear = _mapService.isNearRiskZone(position, zonePos);
        if (isNear) {
          _panicVisible = true;
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => PanicAlertScreen(
                    childName: _childName ?? 'Enfant',
                    childLocation: position,
                  ),
            ),
          );
          _panicVisible = false;
          break;
        }
      } catch (_) {}
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // Marqueur de position actuelle de l'enfant
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 60,
          height: 60,
          child: _buildUserMarker(),
        ),
      );
    }

    // Marqueurs des zones de risque du parent
    for (final zone in _parentRiskZones) {
      markers.add(
        Marker(
          point: LatLng(zone['latitude'], zone['longitude']),
          width: 50,
          height: 50,
          child: _buildZoneMarker(zone),
        ),
      );
    }

    // Marqueurs des adresses du parent
    for (final address in _parentAddresses) {
      markers.add(
        Marker(
          point: LatLng(address['latitude'], address['longitude']),
          width: 50,
          height: 50,
          child: _buildAddressMarker(address),
        ),
      );
    }

    // Marqueur de la position du parent
    if (_parentLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            _parentLocation!['latitude'],
            _parentLocation!['longitude'],
          ),
          width: 60,
          height: 60,
          child: _buildParentMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF179D5B).withOpacity(0.25),
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
            border: Border.all(color: const Color(0xFF179D5B), width: 2),
          ),
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF179D5B),
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneMarker(Map<String, dynamic> zone) {
    final type = zone['type'] ?? 'unknown';
    final color = _getZoneColor(type);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(_getZoneIcon(type), color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildAddressMarker(Map<String, dynamic> address) {
    final type = address['type'] ?? 'unknown';
    final color = _getAddressColor(type);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(_getAddressIcon(type), color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildParentMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.25),
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
            border: Border.all(color: const Color(0xFF2196F3), width: 2),
          ),
          child: const Icon(
            Icons.family_restroom,
            color: Color(0xFF2196F3),
            size: 16,
          ),
        ),
      ],
    );
  }

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
        return Colors.red;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getAddressColor(String type) {
    switch (type) {
      case 'home':
        return const Color(0xFF2196F3); // Bleu (Maison)
      case 'school':
        return const Color(0xFF179D5B); // Vert (École)
      default:
        return const Color(0xFFFFC107); // Jaune (Autres)
    }
  }

  IconData _getZoneIcon(String type) {
    switch (type) {
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'park':
        return Icons.park;
      case 'hospital':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_cart;
      case 'risk':
        return Icons.warning;
      default:
        return Icons.warning;
    }
  }

  IconData _getAddressIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateService>(
      builder: (context, authState, child) {
        final userName = authState.userData?['name'] as String? ?? 'Enfant';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF179D5B),
                      ),
                    ),
                  )
                  : Stack(
                    children: [
                      // Carte principale
                      Positioned.fill(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _currentPosition ??
                                const LatLng(3.848033, 11.502075),
                            initialZoom: 15,
                            minZoom: 10,
                            maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                              subdomains: ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.example.safetytrack',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),
                      ),

                      // Header principal
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildHeader(context, userName),
                      ),

                      // Boutons à droite
                      Positioned(
                        bottom: 120,
                        right: 20,
                        child: _rightButtons(),
                      ),

                      _buildBottomSheet(),
                    ],
                  ),
        );
      },
    );
  }

  // _floatingIcon non utilisé

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF179D5B).withOpacity(0.95),
            const Color(0xFF179D5B).withOpacity(0.8),
            const Color(0xFF179D5B).withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        children: [
          // Barre supérieure avec bouton retour et actions
          Row(
            children: [
              // Bouton retour
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              const SizedBox(width: 16),

              // Titre principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $userName !',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Suivi en temps réel',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons d'action
              Row(
                children: [
                  // Bouton notifications
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.bell_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Menu utilisateur
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: Colors.white,
                        size: 22,
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          context.read<AuthStateService>().signOut();
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Color(0xFF179D5B)),
                                  SizedBox(width: 8),
                                  Text('Se déconnecter'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Indicateurs de statut
          Row(
            children: [
              // Statut en ligne
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En ligne',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Nombre de zones d'alerte
              if (_parentRiskZones.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_parentRiskZones.length} Alert(s)',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // _floatingLabel non utilisé

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
                bottom: BorderSide(
                  width: 1.0,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            child: IconButton(
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 15);
                }
              },
              icon: const Icon(Icons.my_location, color: Color(0xFF179D5B)),
            ),
          ),
          IconButton(
            onPressed: () {
              if (_parentLocation != null) {
                _mapController.move(
                  LatLng(
                    _parentLocation!['latitude'],
                    _parentLocation!['longitude'],
                  ),
                  15,
                );
              }
            },
            icon: const Icon(Icons.family_restroom, color: Color(0xFF179D5B)),
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
                              _currentAddress,
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
                            CupertinoIcons.battery_75_percent,
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
                        _currentAddress,
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
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFF179D5B);

    if (isFilled) {
      return ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: buttonColor),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor.withOpacity(0.1),
          foregroundColor: buttonColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: const Color(0xFFBDBDBD)),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
      );
    }
  }

  // _getZoneTypeLabel non utilisé
}
