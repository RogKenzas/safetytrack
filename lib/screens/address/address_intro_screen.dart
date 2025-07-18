import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/address/marked_address_list_screen.dart';
import '../../components/forms/primary_button.dart';

class AddressIntroScreen extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  const AddressIntroScreen({super.key, this.onNext, this.onPrevious});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/img/map_placeholder.png',
                fit: BoxFit.fitHeight,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Définir les adresses de la maison et de l’école',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              'Connaître les adresses de la maison et de l’école de votre enfant permet un suivi précis.',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Définir les adresses',
                    onPressed:
                        onNext ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MarkedAddressListScreen(),
                            ),
                          );
                        },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
