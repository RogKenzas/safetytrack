import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkAddressScreen extends StatefulWidget {
  const MarkAddressScreen({super.key});

  @override
  State<MarkAddressScreen> createState() => _MarkAddressScreenState();
}

class _MarkAddressScreenState extends State<MarkAddressScreen> {
  String selectedType = 'Maison';
  final List<String> types = ['Maison', 'École', 'Autre'];
  String address = '14 rue de Paris, Lyon';
  String name = 'Maison';
  bool loading = false;

  void _onSave() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse marquée enregistrée (simulation)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                user != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots()
                    : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Aucune adresse trouvée.'));
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List addresses = data['addresses'] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF179D5B),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
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
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rechercher une adresse',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child:
                        addresses.isEmpty
                            ? const Center(
                              child: Text('Aucune adresse enregistrée.'),
                            )
                            : ListView.separated(
                              itemCount: addresses.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 18),
                              itemBuilder: (context, i) {
                                final addr = addresses[i];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nom',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        addr['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Adresse',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        addr['address'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (addr['type'] != null)
                                        Row(
                                          children: [
                                            Icon(
                                              addr['type'] == 'Maison'
                                                  ? Icons.home
                                                  : addr['type'] == 'École'
                                                  ? Icons.school
                                                  : Icons.add,
                                              size: 18,
                                              color: Color(0xFF179D5B),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              addr['type'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
