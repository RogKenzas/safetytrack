import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state_service.dart';
import '../../services/onboarding_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../child/child_dashboard_screen.dart';
import 'login_screen.dart';
import '../onboarding/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateService>(
      builder: (context, authState, child) {
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF179D5B),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF179D5B)),
                  ),
                ],
              ),
            ),
          );
        }

        if (authState.isAuthenticated) {
          // Utilisateur connecté
          final userData = authState.userData;
          if (userData != null) {
            final accountType = userData['accountType'] as String?;

            // Rediriger vers le dashboard approprié selon le type de compte
            if (accountType == 'parent') {
              // Utiliser le service d'onboarding pour vérifier l'état
              return FutureBuilder<bool>(
                future: OnboardingService().canAccessDashboard(
                  authState.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF179D5B),
                          ),
                        ),
                      ),
                    );
                  }

                  final canAccessDashboard = snapshot.data ?? false;
                  if (canAccessDashboard) {
                    return const DashboardScreen();
                  } else {
                    return const OnboardingScreen();
                  }
                },
              );
            } else if (accountType == 'child') {
              return const ChildDashboardScreen();
            }

            // Rediriger vers l'écran d'onboarding pour les autres types de comptes
            // ou si le type de compte n'est pas défini
            return const OnboardingScreen();
          }

          // Si pas de données utilisateur, rediriger vers l'onboarding
          return const OnboardingScreen();
        }

        // Utilisateur non connecté, afficher l'écran de connexion
        return const LoginScreen();
      },
    );
  }
}
