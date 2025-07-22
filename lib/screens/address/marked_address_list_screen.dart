import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/institution/add_institution_screen.dart';
import 'package:safetytrack/services/auth_service.dart';
import '../../components/forms/primary_button.dart';

class MarkedAddressListScreen extends StatefulWidget {
  const MarkedAddressListScreen({super.key});

  @override
  State<MarkedAddressListScreen> createState() =>
      _MarkedAddressListScreenState();
}

class _MarkedAddressListScreenState extends State<MarkedAddressListScreen> {
  late Future<List<Map<String, dynamic>>> _addressFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _addressFuture = AuthService().getUserAddresses(uid);
    } else {
      _addressFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF179D5B),
        elevation: 0,
        title: Text(
          'Adresses marquées',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _addressFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }
              final addresses = snapshot.data ?? [];

              if (addresses.isEmpty) {
                return const Center(child: Text('Aucune adresse trouvée.'));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final addr = addresses[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      'assets/img/map_placeholder.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.08),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          addr['type'] == 'Maison'
                                              ? Icons.home
                                              : addr['type'] == 'École'
                                                  ? Icons.school
                                                  : Icons.place,
                                          color: const Color(0xFF179D5B),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      addr['type'] ?? 'Type inconnu',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: const Color(0xFF179D5B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addr['address'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Continuer',
                    loading: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddInstitutionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

