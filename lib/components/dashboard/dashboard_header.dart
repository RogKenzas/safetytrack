import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../forms/custom_search_bar.dart';
import '../../services/auth_state_service.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateService>(
      builder: (context, authState, child) {
        final userName = authState.userData?['name'] as String?;
        final isLoading = authState.isLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 48,
                left: 24,
                right: 24,
                bottom: 14,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF179D5B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child:
                            isLoading
                                ? Text(
                                  'Chargement...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : Text(
                                  userName != null
                                      ? 'Bonjour, $userName !'
                                      : 'Bonjour !',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                      PopupMenuButton<String>(
                        icon: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF179D5B),
                            size: 22,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'profile') {
                            Navigator.pushNamed(context, '/profile');
                          } else if (value == 'logout') {
                            context.read<AuthStateService>().signOut();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color(0xFF179D5B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mon profil',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF179D5B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Color(0xFF179D5B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Se déconnecter',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF179D5B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomSearchBar(hintText: 'Rechercher...'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
