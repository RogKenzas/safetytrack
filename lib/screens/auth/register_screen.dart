import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/auth/auth_wrapper.dart';
import '../../components/forms/primary_button.dart';
import '../../components/forms/secondary_button.dart';
import '../../components/forms/custom_text_field.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool loading = false;
  bool isParentAccount = true; // true = parent, false = enfant
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    setState(() {
      loading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        name: _nameController.text.trim(),
        accountType: isParentAccount ? 'parent' : 'child',
      );
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isParentAccount
                ? 'Compte parent créé avec succès !'
                : 'Compte enfant créé avec succès !',
          ),
        ),
      );
      // Laisser le flux continuer automatiquement via AuthWrapper
      if (mounted && user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
        _errorMessage = e.toString();
      });
    }
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

                // Toggle pour choisir le type de compte
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type de compte',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(() => isParentAccount = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isParentAccount
                                          ? const Color(0xFF179D5B)
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.family_restroom,
                                      color:
                                          isParentAccount
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Parent',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isParentAccount
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(() => isParentAccount = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      !isParentAccount
                                          ? const Color(0xFF179D5B)
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.child_care,
                                      color:
                                          !isParentAccount
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Enfant',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            !isParentAccount
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isParentAccount
                            ? 'Vous pourrez ajouter des comptes enfants et suivre leur localisation'
                            : 'Votre compte sera lié à un compte parent pour la surveillance',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                CustomTextField(label: 'Nom*', controller: _nameController),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Adresse e-mail*',
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mot de passe*',
                  obscureText: true,
                  controller: _passwordController,
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
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
