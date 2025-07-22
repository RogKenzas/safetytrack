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
import '../../components/forms/custom_text_field.dart';

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

  void _showNameInputModal() {
    String lieu = '';
    final TextEditingController _lieuController = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nom du lieu",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Saisir le nom du lieu",
                controller: _lieuController,
                hintText: "Ex: Pharmacie, Bureau, etc.",
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: "Valider",
                onPressed: () {
                  if (_lieuController.text.trim().isNotEmpty) {
                    setState(() {
                      name = _lieuController.text.trim();
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
          // Marqueur visuel
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
                        onChanged: (value) {},
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
                                    if (type == 'Autre' && val) {
                                      setState(() {
                                        selectedType = type;
                                      });
                                      _showNameInputModal();
                                    } else if (val) {
                                      setState(() {
                                        selectedType = type;
                                        name = type;
                                      });
                                    }
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
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        try {
                          await _mapService.saveAddressForCurrentUser(
                            name: name,
                            address: address,
                            position:
                                _currentPosition ?? _mapService.initialPosition,
                            type: selectedType,
                          );
                          setState(() {
                            loading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Adresse enregistrée avec succès !',
                                ),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddressIntroScreen()),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            loading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de l\'enregistrement : $e',
                                ),
                              ),
                            );
                          }
                        }
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
