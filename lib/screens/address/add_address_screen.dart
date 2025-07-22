import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/address/address_intro_screen.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/custom_search_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_service.dart';
import 'package:location/location.dart';
import 'package:flutter_map/src/map/camera/camera.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final MapService _mapService = MapService();
  LatLng? _currentPosition;
  bool _loadingLocation = true;
  bool loading = false;
  String selectedType = 'Maison';
  final List<String> types = ['Maison', 'École', 'Autre'];
  String address = '3.730 Rue Ngoa Ekelle, Yaounde';
  String name = 'Maison';
  LatLng _mapCenter = LatLng(0, 0);
  TextEditingController _searchController = TextEditingController();

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
      final newAddress = await _mapService.getAddressFromLatLng(
        _currentPosition!,
      );
      setState(() {
        address = newAddress;
      });
    }
  }

  Future<void> _updateAddressFromCenter(LatLng center) async {
    final newAddress = await _mapService.getAddressFromLatLng(center);
    setState(() {
      address = newAddress;
      _currentPosition = center;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Carte en arrière-plan
          Positioned.fill(
            child:
                _loadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            _currentPosition ?? _mapService.initialPosition,
                        initialZoom: 16,
                        onPositionChanged: (MapCamera camera, bool hasGesture) {
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
                      ],
                    ),
          ),
          // Marqueur visuel centré (au-dessus de la carte)
          if (!_loadingLocation)
            IgnorePointer(
              child: Center(
                child: Stack(
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
                ),
              ),
            ),
          // Barre de recherche personnalisée et bouton retour
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF179D5B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Rechercher',
                        onChanged: (value) {
                          // TODO: Ajouter la logique de recherche d'adresse si besoin
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 320,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enregistrer votre position exacte permet un suivi précis.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        types
                            .map(
                              (type) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: ChoiceChip(
                                  label: Row(
                                    children: [
                                      if (type == 'Maison')
                                        const Icon(
                                          Icons.home,
                                          size: 18,
                                          color: Color(0xFF179D5B),
                                        ),
                                      if (type == 'École')
                                        const Icon(
                                          Icons.school,
                                          size: 18,
                                          color: Color(0xFF179D5B),
                                        ),
                                      if (type == 'Autre')
                                        const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Color(0xFF179D5B),
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: selectedType == type,
                                  selectedColor: const Color(0xFF179D5B),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color:
                                        selectedType == type
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          selectedType == type
                                              ? const Color(0xFF179D5B)
                                              : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      selectedType = type;
                                      name = type;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nom",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  Text(name, style: GoogleFonts.poppins(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    "Adresse",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  Text(address, style: GoogleFonts.poppins(fontSize: 15)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF179D5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Action d'enregistrement
                      },
                      child: Text(
                        "Enregistrer l'adresse marquée",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
