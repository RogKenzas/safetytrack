import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:safetytrack/services/map_service.dart';

class MapPlaceholder extends StatefulWidget {
  final VoidCallback? onTap;
  const MapPlaceholder({super.key, this.onTap});

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  final MapService _mapService = MapService();
  LatLng _mapCenter = LatLng(0, 0);
  LatLng? _currentPosition;
  String address = '3.730 Rue Ngoa Ekelle, Yaounde';
  bool _loadingLocation = true;

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

    final newAddress = await _mapService.getAddressFromLatLng(pos);
    setState(() {
      address = newAddress;
    });
  }

  Future<void> _updateAddressFromCenter(LatLng center) async {
    final newAddress = await _mapService.getAddressFromLatLng(center);
    setState(() {
      address = newAddress;
    });
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child:
                _loadingLocation
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF179D5B),
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              _currentPosition ?? _mapService.initialPosition,
                          initialZoom: 16,
                          onPositionChanged: (
                            MapCamera camera,
                            bool hasGesture,
                          ) {
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
          ),
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  '23°C 🌥️',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF179D5B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
