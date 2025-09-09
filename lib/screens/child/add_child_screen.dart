import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/components/forms/custom_text_field.dart';
import 'package:safetytrack/components/forms/primary_button.dart';
import 'package:safetytrack/screens/address/add_address_screen.dart';
import '../../services/auth_service.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  bool loading = false;
  final TextEditingController _emailController = TextEditingController();
  List<String> _suggestions = [];
  final AuthService _authService = AuthService();
  String? _selectedEmail;
  Future<void> _fetchSuggestions(String input) async {
    final suggestions = await _authService.suggestChildEmails(input);
    setState(() {
      _suggestions = suggestions;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onAdd() async {
    if (_selectedEmail == null) return;
    setState(() => loading = true);
    final childData = await _authService.getUserByEmail(_selectedEmail!);
    if (childData != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _authService.linkChildToParent(
          parentUid: user.uid,
          childUid: childData['uid'],
          childEmail: childData['email'],
          childName: childData['name'] ?? 'Enfant',
        );
      }
    }
    setState(() => loading = false);

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enfant ajouté avec succès !'),
        backgroundColor: Color(0xFF179D5B),
        duration: Duration(seconds: 2),
      ),
    );

    // Retourner à l'onboarding pour continuer le flux
    Navigator.pop(context);
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
                  'Ajoutez le compte enfant',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  'Saisissez l\'adresse email du compte enfant. Les suggestions s\'affichent automatiquement.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Email du compte enfant',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _selectedEmail = null;
                    _fetchSuggestions(value);
                  },
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final email = _suggestions[index];
                        return ListTile(
                          title: Text(
                            email,
                            style: GoogleFonts.poppins(fontSize: 15),
                          ),
                          onTap: () {
                            setState(() {
                              _emailController.text = email;
                              _selectedEmail = email;
                              _suggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Ajouter',
                  loading: loading,
                  onPressed: loading || _selectedEmail == null ? null : _onAdd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
