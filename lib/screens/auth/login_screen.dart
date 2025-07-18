import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/secondary_button.dart';
import '../../components/forms/custom_text_field.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import '../onboarding/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;

  void _onLogin() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    // Navigation vers l'onboarding après connexion
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
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
                  'Bienvenue',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez saisir vos identifiants pour vous connecter.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CustomTextField(label: 'Adresse e-mail'),
                const SizedBox(height: 20),
                const CustomTextField(label: 'Mot de passe', obscureText: true),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _goToResetPassword,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF179D5B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Se connecter',
                  loading: loading,
                  onPressed: loading ? null : _onLogin,
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
                  label: 'Se connecter avec Google',
                  icon: Icons.g_mobiledata,
                  imageAsset: 'assets/img/google.png',
                  onPressed: loading ? null : () {},
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Se connecter avec Apple',
                  icon: Icons.apple,
                  imageAsset: 'assets/img/apple.png',
                  onPressed: loading ? null : () {},
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pas encore de compte ? ",
                      style: GoogleFonts.poppins(),
                    ),
                    GestureDetector(
                      onTap: loading ? null : _goToRegister,
                      child: Text(
                        'Créer un compte',
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
