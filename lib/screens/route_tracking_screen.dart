import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:safetytrack/services/map_service.dart';

class RouteTrackingScreen extends StatefulWidget {
  const RouteTrackingScreen({super.key});

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final MapService _mapService = MapService();
  LatLng _mapCenter = LatLng(0, 0);
  LatLng? _currentPosition;
  String address = '3.730 Rue Ngoa Ekelle, Yaounde';
  bool _loadingLocation = true;

  Future<void> _updateAddressFromCenter(LatLng center) async {
    final newAddress = await _mapService.getAddressFromLatLng(center);
    setState(() {
      address = newAddress;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
      final newAddress = await _mapService.getAddressFromLatLng(_currentPosition!);
      setState(() {
        address = newAddress;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loadingLocation
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
                      onPositionChanged:
                          (MapCamera camera, bool hasGesture) {
                        if (hasGesture && camera.center != null) {
                          _mapCenter = camera.center!;
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
          Positioned(
            top: 120,
            left: 20,
            child: _floatingLabel('23°C 🌥️'),
          ),

          // Boutons à droite
          Positioned(
            bottom: 120,
            right: 20,
            child: _rightButtons(),
          ),

          // Draggable sheet
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _floatingIcon({required IconData icon, required VoidCallback onPressed}) {
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
            icon: const Icon(Icons.location_on_outlined, color: Color(0xFF179D5B)),
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
                            Text('Position Actuelle',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                )),
                            Text(address,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Color(0xFF7A7A7A),
                                )),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.battery_full,
                              color: Color(0xFF179D5B), size: 20),
                          const SizedBox(width: 4),
                          Text('72 %',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              )),
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
                      _placeButton(
                        icon: Icons.location_city,
                        label: 'École',
                      ),
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
                    endIndent: 18),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lieu',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Color(0xFFBDBDBD),
                          )),
                      const SizedBox(height: 2),
                      Text('Maison',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          )),
                      const SizedBox(height: 10),
                      Text('Adresse',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Color(0xFFBDBDBD),
                          )),
                      const SizedBox(height: 2),
                      Text(address,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          )),
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
          label: Text(label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
