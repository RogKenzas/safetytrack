import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/secondary_button.dart';
import '../../components/forms/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool loading = false;

  void _onRegister() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Compte créé (simulation)')));
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
                  'Créer un compte',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez remplir les informations pour créer un compte.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CustomTextField(label: 'Nom*'),
                const SizedBox(height: 20),
                const CustomTextField(label: 'Adresse e-mail*'),
                const SizedBox(height: 20),
                const CustomTextField(
                  label: 'Mot de passe*',
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
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Créer un compte',
                  loading: loading,
                  onPressed: loading ? null : _onRegister,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('ou', style: GoogleFonts.poppins()),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  label: 'Créer un compte avec Google',
                  icon: Icons.g_mobiledata,
                  imageAsset: 'assets/img/google.png',
                  onPressed: loading ? null : () {},
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Créer un compte avec Apple',
                  imageAsset: 'assets/img/apple.png',
                  icon: Icons.apple,
                  onPressed: loading ? null : () {},
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Déjà un compte ? ', style: GoogleFonts.poppins()),
                    GestureDetector(
                      onTap: loading ? null : _goToLogin,
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF179D5B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
