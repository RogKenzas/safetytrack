import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/dashboard_screen.dart';
import '../../components/forms/primary_button.dart';

class CongratulationsScreen extends StatelessWidget {
  const CongratulationsScreen({super.key});

  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
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
              const SizedBox(height: 32),
              Text(
                'Félicitations !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF179D5B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tout est prêt pour assurer la sécurité et l’information de votre enfant.',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/img/congrats_family.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Démarrer',
                onPressed: () => _goToDashboard(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
