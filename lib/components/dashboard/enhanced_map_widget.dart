import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_service.dart';
import '../../services/auth_service.dart';
import '../web_location_info.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class EnhancedMapWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showLegend;

  const EnhancedMapWidget({super.key, this.onTap, this.showLegend = true});

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(3.848033, 11.502075);
  LatLng? _currentPosition;
  String _address = 'Chargement de l\'adresse...';
  List<Map<String, dynamic>> _userAddresses = [];
  List<Map<String, dynamic>> _riskZones = [];
  List<Map<String, dynamic>> _childrenLocations = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMapData();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation();
      _loadMapData();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Utiliser le service de carte amélioré qui gère le web
      final pos = await _mapService.getCurrentUserPosition();

      if (pos != null && mounted) {
        setState(() {
          _currentPosition = pos;
          _mapCenter = pos;
        });
        _updateAddressFromCenter(pos);
      } else if (mounted) {
        // Fallback vers la position par défaut si la géolocalisation échoue
        setState(() {
          _currentPosition = _mapService.initialPosition;
          _mapCenter = _mapService.initialPosition;
        });
        _updateAddressFromCenter(_mapService.initialPosition);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      // En cas d'erreur, utiliser la position par défaut
      if (mounted) {
        setState(() {
          _currentPosition = _mapService.initialPosition;
          _mapCenter = _mapService.initialPosition;
        });
        _updateAddressFromCenter(_mapService.initialPosition);
      }
    }
  }

  Future<void> _loadMapData() async {
    try {
      final authService = AuthService();
      final addresses = await authService.getCurrentUserAddresses();
      final riskZones = await authService.getCurrentUserRiskZones();
      final childrenLocations =
          await authService.getCurrentUserChildrenLocations();

      if (mounted) {
        setState(() {
          _userAddresses = addresses;
          _riskZones = riskZones;
          _childrenLocations = childrenLocations;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _updateAddressFromCenter(LatLng center) async {
    try {
      final newAddress = await _mapService.getAddressFromLatLng(center);
      if (mounted) {
        setState(() => _address = newAddress);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'adresse: $e');
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // Marqueur de position actuelle de l'utilisateur
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: _buildUserMarker(),
        ),
      );
    }

    // Marqueurs des adresses de l'utilisateur
    for (final address in _userAddresses) {
      final type = address['type'] ?? 'unknown';
      markers.add(
        Marker(
          point: LatLng(address['latitude'], address['longitude']),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: _buildUserAddressMarker(type),
        ),
      );
    }

    // Marqueurs des zones de risque
    for (final zone in _riskZones) {
      markers.add(
        Marker(
          point: LatLng(zone['latitude'], zone['longitude']),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: _buildRiskZoneMarker(),
        ),
      );
    }

    // Marqueurs des enfants
    for (final child in _childrenLocations) {
      markers.add(
        Marker(
          point: LatLng(child['latitude'], child['longitude']),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: _buildChildMarker('Autre'),
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
            color: Colors.grey.withOpacity(0.25),
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
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAddressMarker(String type) {
    final Color color = _getColorForAddressType(type);
    final IconData icon = _getIconForAddressType(type);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
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
            border: Border.all(color: color, width: 2),
          ),
          child: Center(child: Icon(icon, size: 16, color: color)),
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

  Widget _buildChildMarker(String type) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.25),
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
            border: Border.all(color: Colors.purple, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.person, size: 16, color: Colors.purple),
          ),
        ),
      ],
    );
  }

  Color _getColorForAddressType(String type) {
    switch (type) {
      case 'Maison':
      case 'home':
        return const Color(0xFF2196F3); // Bleu
      case 'École':
      case 'school':
        return const Color(0xFF179D5B); // Vert (thème app)
      default:
        return const Color(0xFFFFC107); // Jaune/Amber
    }
  }

  IconData _getIconForAddressType(String type) {
    switch (type) {
      case 'Maison':
      case 'home':
        return Icons.home;
      case 'École':
      case 'school':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Information sur les restrictions web
        if (kIsWeb) const WebLocationInfo(),

        // Carte principale
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Carte principale
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 15,
                    minZoom: 10,
                    maxZoom: 18,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _updateAddressFromCenter(_mapCenter);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      subdomains: ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.safetytrack',
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // Overlay d'adresse
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFF179D5B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Indicateur web si nécessaire
                        if (kIsWeb && _address.contains('Position:'))
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Web',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Légende des marqueurs (si activée)
                if (widget.showLegend)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Légende',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                            const Color(0xFF179D5B),
                            'Vous',
                            Icons.my_location,
                          ),
                          _buildLegendItem(
                            Colors.purple,
                            'Enfants',
                            Icons.person,
                          ),
                          _buildLegendItem(
                            const Color(0xFFFF5722),
                            'Zones d\'alerte',
                            Icons.warning,
                          ),
                          _buildLegendItem(
                            Colors.blue,
                            'Adresses',
                            Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bouton de centrage
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: FloatingActionButton.small(
                    onPressed:
                        _currentPosition != null
                            ? () {
                              _mapController.move(_currentPosition!, 15);
                            }
                            : null,
                    backgroundColor: const Color(0xFF179D5B),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 10),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
