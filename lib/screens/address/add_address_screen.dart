import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/address/address_intro_screen.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/custom_search_bar.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  bool loading = false;
  String selectedType = 'Maison';
  final List<String> types = ['Maison', 'École', 'Autre'];
  String address = '3.730 Rue Ngoa Ekelle, Yaounde';
  String name = 'Maison';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Image de carte en fond (remplacer par ton asset)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/img/map_placeholder.png',
              fit: BoxFit.cover,
            ),
          ),
          // Bouton retour + barre de recherche
          Positioned(
            top: 38,
            left: 18,
            right: 18,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF179D5B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: CustomSearchBar()),
              ],
            ),
          ),
          // Modale fixe en bas
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Enregistrer votre position exacte permet un suivi précis.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nom',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: GoogleFonts.poppins(fontSize: 15)),
                        const SizedBox(height: 12),
                        Text(
                          'Adresse',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(address, style: GoogleFonts.poppins(fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Enregistrer l’adresse marquée',
                    loading: loading,
                    onPressed:
                        loading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddressIntroScreen(),
                                ),
                              );
                            },
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
