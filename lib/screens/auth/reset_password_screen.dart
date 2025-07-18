import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/custom_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool loading = false;

  void _onReset() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    // Navigation simulée (à remplacer par la vraie page d'accueil plus tard)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe réinitialisé (simulation)')),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                  'Nouveau mot de passe',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez saisir un nouveau mot de passe.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CustomTextField(
                  label: 'Mot de passe*',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                const CustomTextField(
                  label: 'Confirmer le mot de passe*',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF179D5B),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Au moins 8 caractères',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF179D5B),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Au moins un caractère spécial',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Réinitialiser le mot de passe',
                  loading: loading,
                  onPressed: loading ? null : _onReset,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: loading ? null : _goToLogin,
                  child: Text(
                    '← Retour à la connexion',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF179D5B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
