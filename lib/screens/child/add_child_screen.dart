import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/custom_text_field.dart';
import '../address/add_address_screen.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  bool loading = false;
  // Simulé, pas de vraie image pour l'instant
  String? imagePath;

  void _onAdd() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Ajoutez les informations de votre enfant',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  'Le nom, l’âge et la photo de votre enfant nous aident à assurer sa sécurité.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CustomTextField(label: 'Nom de l’enfant'),
                const SizedBox(height: 20),
                const CustomTextField(
                  label: 'Âge',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () {}, // Simulation, pas d'upload réel
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EF),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: const Color(0xFF179D5B),
                          width: 2,
                        ),
                      ),
                      child:
                          imagePath == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey.shade600,
                              )
                              : null, // Affichage image simulé
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Ajouter une photo',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF179D5B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Ajouter',
                  loading: loading,
                  onPressed: loading ? null : _onAdd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
