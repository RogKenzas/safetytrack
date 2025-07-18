import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/custom_text_field.dart';
import '../dashboard/dashboard_screen.dart';
import 'verify_token_screen.dart';

class AddInstitutionScreen extends StatefulWidget {
  const AddInstitutionScreen({super.key});

  @override
  State<AddInstitutionScreen> createState() => _AddInstitutionScreenState();
}

class _AddInstitutionScreenState extends State<AddInstitutionScreen> {
  bool loading = false;
  String? selectedGrade;
  final List<String> grades = [
    'CP',
    'CE1',
    'CE2',
    'CM1',
    'CM2',
    '6ème',
    '5ème',
    '4ème',
    '3ème',
    '2nde',
    '1ère',
    'Terminale',
  ];

  void _onSave() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    // Navigation vers la vérification du token après enregistrement
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VerifyTokenScreen()),
    );
  }

  void _onPrevious() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajouter les informations institutionnelles',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ces informations permettent d’adapter le planning et les événements de votre enfant.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nom de l’institution',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const CustomTextField(
                label: '',
                hintText: 'Entrez le nom de l’école ou collège',
              ),
              const SizedBox(height: 18),
              Text(
                'Email de l’institution',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const CustomTextField(
                label: '',
                hintText: 'Entrez l’email de l’école ou collège',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              Text(
                'Classe/Niveau',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: InputDecoration(
                  hintText: 'Sélectionnez la classe de votre enfant',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items:
                    grades
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g, style: GoogleFonts.poppins()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => selectedGrade = v),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : _onPrevious,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF179D5B)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Previous',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF179D5B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Submit',
                      loading: loading,
                      onPressed: loading ? null : _onSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
