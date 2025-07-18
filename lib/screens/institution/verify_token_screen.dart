import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/otp_input.dart';
import '../dashboard/dashboard_screen.dart';
import 'congratulations_screen.dart';

class VerifyTokenScreen extends StatefulWidget {
  const VerifyTokenScreen({super.key});

  @override
  State<VerifyTokenScreen> createState() => _VerifyTokenScreenState();
}

class _VerifyTokenScreenState extends State<VerifyTokenScreen> {
  String code = '';
  bool loading = false;

  void _onCompleted(String value) {
    setState(() => code = value);
    if (value == '0000') {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CongratulationsScreen()),
        );
      });
    }
  }

  void _onVerify() {
    if (code == '0000') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CongratulationsScreen()),
      );
    }
    // Sinon, rien ne se passe
  }

  void _onPrevious() {
    Navigator.pop(context);
  }

  void _onRequestAgain() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouveau code envoyé (simulation)')),
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
              const SizedBox(height: 24),
              Text(
                'Entrer le code reçu',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifiez votre email et saisissez le code envoyé par l’institution.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              OtpInput(onCompleted: _onCompleted),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Code non reçu ?', style: GoogleFonts.poppins()),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _onRequestAgain,
                    child: Text(
                      'Renvoyer',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF179D5B),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
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
                      label: 'Vérifier',
                      loading: loading,
                      onPressed: loading ? null : _onVerify,
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
